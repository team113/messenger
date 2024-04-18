// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'dart:async';

import 'package:device_region/device_region.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/settings.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/permission.dart';
import '/util/platform_utils.dart';
import 'disposable_service.dart';

/// Service responsible for [ChatContact]s related functionality.
class ContactService extends DisposableService {
  ContactService(this._contactRepository, this._settingsRepository);

  /// Repository to fetch [ChatContact]s from.
  final AbstractContactRepository _contactRepository;

  /// Settings repository updating the [ApplicationSettings.contactsImported].
  final AbstractSettingsRepository _settingsRepository;

  /// Returns the [RxStatus] of the [paginated] initialization.
  Rx<RxStatus> get status => _contactRepository.status;

  /// Indicates whether the [paginated] have next page.
  RxBool get hasNext => _contactRepository.hasNext;

  /// Indicates whether a next page of the [paginated] is loading.
  RxBool get nextLoading => _contactRepository.nextLoading;

  /// Returns the reactive map of the currently paginated [RxChatContact]s.
  RxObsMap<ChatContactId, RxChatContact> get paginated =>
      _contactRepository.paginated;

  /// Returns the current reactive map of all [RxChatContact]s available.
  RxObsMap<ChatContactId, RxChatContact> get contacts =>
      _contactRepository.contacts;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    if (PlatformUtils.isMobile &&
        !PlatformUtils.isWeb &&
        _settingsRepository.applicationSettings.value?.contactsImported !=
            true) {
      _importContacts();
    }

    super.onInit();
  }

  /// Fetches the next [paginated] page.
  FutureOr<void> next() {
    Log.debug('next()', '$runtimeType');
    return _contactRepository.next();
  }

  /// Adds the specified [user] to the current [MyUser]'s address book.
  Future<void> createChatContact(User user) {
    Log.debug('createChatContact($user)', '$runtimeType');

    return _contactRepository.createChatContact(
      user.name ?? UserName(user.num.toString()),
      userId: user.id,
    );
  }

  /// Deletes the specified [ChatContact] from the authenticated [MyUser]'s
  /// address book.
  Future<void> deleteContact(ChatContactId id) async {
    Log.debug('deleteContact($id)', '$runtimeType');
    await _contactRepository.deleteContact(id);
  }

  /// Updates `name` of the specified [ChatContact] in the authenticated
  /// [MyUser]'s address book.
  Future<void> changeContactName(ChatContactId id, UserName name) async {
    Log.debug('changeContactName($id, $name)', '$runtimeType');
    await _contactRepository.changeContactName(id, name);
  }

  /// Marks the specified [ChatContact] as favorited for the authenticated
  /// [MyUser] and sets its position in the favorites list.
  Future<void> favoriteChatContact(
    ChatContactId id, [
    ChatContactFavoritePosition? position,
  ]) async {
    Log.debug('favoriteChatContact($id, $position)', '$runtimeType');
    await _contactRepository.favoriteChatContact(id, position);
  }

  /// Removes the specified [ChatContact] from the favorites list of the
  /// authenticated [MyUser].
  Future<void> unfavoriteChatContact(ChatContactId id) async {
    Log.debug('unfavoriteChatContact($id)', '$runtimeType');
    await _contactRepository.unfavoriteChatContact(id);
  }

  /// Searches [ChatContact]s by the given criteria.
  Paginated<ChatContactId, RxChatContact> search({
    UserName? name,
    UserEmail? email,
    UserPhone? phone,
  }) {
    Log.debug('search($name, $email, $phone)', '$runtimeType');

    return _contactRepository.search(
      name: name,
      email: email,
      phone: phone,
    );
  }

  /// Imports contacts from the device's contact list.
  Future<void> _importContacts() async {
    Log.debug('_importContacts()', '$runtimeType');

    PermissionStatus status = await Permission.contacts.status;

    if (status.isPermanentlyDenied || status.isRestricted) {
      return;
    }

    if (!status.isGranted) {
      status = await PermissionUtils.contacts();

      if (!status.isGranted) {
        return;
      }
    }

    final List<Future> futures = [];
    final List<Contact> contacts = await FastContacts.getAllContacts();

    IsoCode? isoCode;
    final String? countryCode = await DeviceRegion.getSIMCountryCode();
    if (countryCode != null) {
      isoCode = IsoCode.fromJson(countryCode.toUpperCase());
    }

    for (final Contact contact in contacts) {
      final List<UserPhone> phones = [];
      final List<UserEmail> emails = [];

      for (var e in contact.phones) {
        try {
          final PhoneNumber phone =
              PhoneNumber.parse(e.number, callerCountry: isoCode);

          if (!phone.isValid(type: PhoneNumberType.mobile)) {
            throw const FormatException('Not valid');
          }

          phones.add(UserPhone('+${phone.countryCode}${phone.nsn}'));
        } catch (ex) {
          Log.warning(
            'Failed to parse ${e.number} into UserPhone with $ex',
            '$runtimeType',
          );
        }
      }

      for (var e in contact.emails) {
        try {
          emails.add(UserEmail(e.address));
        } catch (ex) {
          Log.warning(
            'Failed to parse ${e.address} into UserEmail with $ex',
            '$runtimeType',
          );
        }
      }

      futures.add(
        Future(() async {
          try {
            if (phones.isNotEmpty || emails.isNotEmpty) {
              await _contactRepository.createChatContact(
                UserName(contact.displayName.padRight(2, '_')),
                phones: phones,
                emails: emails,
              );
            }
          } catch (_) {
            // No-op.
          }
        }),
      );
    }

    await Future.wait(futures);
    await _settingsRepository.setContactsImported(true);
  }
}
