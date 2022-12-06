// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/api/backend/extension/contact.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/provider/gql/exceptions.dart'
    show
        GraphQlProviderExceptions,
        ResubscriptionRequiredException,
        StaleVersionException;
import '/provider/gql/graphql.dart';
import '/provider/hive/contact.dart';
import '/provider/hive/gallery_item.dart';
import '/provider/hive/session.dart';
import '/provider/hive/user.dart';
import '/store/contact_rx.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import 'event/contact.dart';
import 'model/contact.dart';
import 'user.dart';

// TODO: Implement [favorites] sorting.
/// Implementation of an [AbstractContactRepository].
class ContactRepository implements AbstractContactRepository {
  ContactRepository(
    this._graphQlProvider,
    this._contactLocal,
    this._userRepo,
    this._sessionLocal,
  );

  @override
  final RxBool isReady = RxBool(false);

  @override
  final RxObsMap<ChatContactId, HiveRxChatContact> contacts = RxObsMap();

  @override
  final RxMap<ChatContactId, HiveRxChatContact> favorites = RxMap();

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [ChatContact]s local [Hive] storage.
  final ContactHiveProvider _contactLocal;

  /// [User]s repository.
  final UserRepository _userRepo;

  /// [SessionDataHiveProvider] used to store [ChatContactsEventsCursor].
  final SessionDataHiveProvider _sessionLocal;

  /// Size of the [ChatContacts]s page.
  final int _pageSize = 120;

  /// Indicator whether the [contacts] has next page.
  bool _hasNextPage = true;

  /// [ContactHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  /// [_chatContactsRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamIterator? _remoteSubscription;

  @override
  Future<void> init() async {
    if (!_contactLocal.isEmpty) {
      for (HiveChatContact c in _contactLocal.contacts
          .sortedBy((a) => a.value.name.val)
          .take(_pageSize)) {
        HiveRxChatContact entry = HiveRxChatContact(_userRepo, c)..init();
        if (c.value.favoritePosition == null) {
          contacts[c.value.id] = entry;
        } else {
          favorites[c.value.id] = entry;
        }
      }

      isReady.value = true;
    }

    _initLocalSubscription();
    _initRemoteSubscription();

    HashMap<ChatContactId, HiveChatContact> fetched =
        await _chatContacts(first: _pageSize);

    for (ChatContactId id in contacts.keys) {
      if (!fetched.containsKey(id)) {
        _contactLocal.remove(id);
      }
    }

    for (HiveChatContact c in fetched.values) {
      _putChatContact(c);
    }

    isReady.value = true;
  }

  @override
  void dispose() {
    contacts.forEach((k, v) => v.dispose());
    favorites.forEach((k, v) => v.dispose());
    _localSubscription?.cancel();
    _remoteSubscription?.cancel();
  }

  @override
  Future<void> clearCache() => _contactLocal.clear();

  // TODO: Forbid creating multiple ChatContacts with the same User?
  @override
  Future<void> createChatContact(UserName name, UserId id) =>
      _graphQlProvider.createChatContact(
        name: name,
        records: [ChatContactRecord(userId: id)],
      );

  @override
  Future<void> deleteContact(ChatContactId id) async {
    final HiveRxChatContact? oldChatContact = contacts.remove(id);

    try {
      await _graphQlProvider.deleteChatContact(id);
    } catch (_) {
      contacts.addIf(oldChatContact != null, id, oldChatContact!);
      rethrow;
    }
  }

  @override
  Future<void> changeContactName(ChatContactId id, UserName name) async {
    final HiveRxChatContact? contact = contacts[id];
    final UserName? oldName = contact?.contact.value.name;

    contact?.contact.update((c) => c?.name = name);
    contacts.emit(
      MapChangeNotification.updated(contact?.id, contact?.id, contact),
    );

    try {
      await _graphQlProvider.changeContactName(id, name);
    } catch (_) {
      contact?.contact.update((c) => c?.name = oldName!);
      contacts.emit(
        MapChangeNotification.updated(contact?.id, contact?.id, contact),
      );
      rethrow;
    }
  }

  @override
  Future<void> fetchNextPage() async {
    if (this.contacts.isEmpty || !_hasNextPage) {
      return;
    }

    List<HiveChatContact>? localContacts;
    if (!_contactLocal.isEmpty &&
        _contactLocal.contacts.length > this.contacts.length) {
      localContacts = _contactLocal.contacts
          .sortedBy((a) => a.value.name.val)
          .skip(this.contacts.length)
          .take(_pageSize)
          .toList();
      for (HiveChatContact c in localContacts) {
        final HiveRxChatContact entry = HiveRxChatContact(_userRepo, c);
        this.contacts[c.value.id] = entry;
        entry.init();
      }
    }

    ChatContactsCursor? cursor = this
        .contacts
        .values
        .sortedBy((a) => a.contact.value.name.val)
        .lastWhereOrNull((e) => e.cursor != null)
        ?.cursor;

    HashMap<ChatContactId, HiveChatContact> contacts =
        await _chatContacts(first: _pageSize, after: cursor);

    if (contacts.length < _pageSize) {
      _hasNextPage = false;
    }

    if (localContacts != null) {
      for (HiveChatContact c in localContacts) {
        if (!contacts.containsKey(c.value.id)) {
          _contactLocal.remove(c.value.id);
        }
      }
    }

    for (HiveChatContact c in contacts.values) {
      _putChatContact(c);
    }
  }

  /// Puts the provided [contact] to [Hive].
  Future<void> _putChatContact(HiveChatContact contact) async {
    var saved = _contactLocal.get(contact.value.id);
    // TODO: Version should not be zero at all.
    if (saved == null ||
        saved.ver <= contact.ver ||
        contact.ver.internal == BigInt.zero) {
      if (saved != null && contact.cursor == null) {
        contact.cursor = saved.cursor;
      }
      await _contactLocal.put(contact);
    }
  }

  /// Initializes [ContactHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    _localSubscription = StreamIterator(_contactLocal.boxEvents);
    while (await _localSubscription!.moveNext()) {
      BoxEvent event = _localSubscription!.current;
      if (event.deleted) {
        favorites.remove(ChatContactId(event.key));
        contacts.remove(ChatContactId(event.key));
      } else {
        if (event.value?.value.favoritePosition == null) {
          favorites.remove(ChatContactId(event.key));
          HiveRxChatContact? contact = contacts[ChatContactId(event.key)];
          if (contact == null) {
            contacts[ChatContactId(event.key)] =
                HiveRxChatContact(_userRepo, event.value)..init();
          } else {
            contact.contact.value = event.value.value;
          }
        } else {
          contacts.remove(ChatContactId(event.key));
          HiveRxChatContact? contact = favorites[ChatContactId(event.key)];
          if (contact == null) {
            favorites[ChatContactId(event.key)] =
                HiveRxChatContact(_userRepo, event.value)..init();
          } else {
            contact.contact.value = event.value.value;
            contact.contact.refresh();
          }
        }
      }
    }
  }

  /// Initializes [_chatContactsRemoteEvents] subscription.
  Future<void> _initRemoteSubscription({bool noVersion = false}) async {
    var ver = noVersion ? null : _sessionLocal.getChatContactsListVersion();
    _remoteSubscription?.cancel();
    _remoteSubscription = StreamIterator(await _chatContactsRemoteEvents(ver));

    while (await _remoteSubscription!
        .moveNext()
        .onError<ResubscriptionRequiredException>((_, __) {
      _initRemoteSubscription();
      return false;
    }).onError<StaleVersionException>((_, __) {
      _initRemoteSubscription(noVersion: true);
      return false;
    })) {
      await _contactRemoteEvent(_remoteSubscription!.current);
    }
  }

  /// Handles [ChatContactEvent] from the [_chatContactsRemoteEvents]
  /// subscription.
  Future<void> _contactRemoteEvent(ChatContactsEvents event) async {
    switch (event.kind) {
      case ChatContactsEventsKind.initialized:
        // No-op.
        break;

      case ChatContactsEventsKind.chatContactsList:
        var node = event as ChatContactsEventsChatContactsList;
        var chatContacts = [...node.chatContacts, ...node.favoriteChatContacts];
        _sessionLocal.setChatContactsListVersion(node.ver);

        for (HiveChatContact c in _contactLocal.contacts) {
          if (!chatContacts.any((m) => m.value.id == c.value.id)) {
            _contactLocal.remove(c.value.id);
          }
        }

        for (HiveChatContact c in chatContacts) {
          _putChatContact(c);
        }

        isReady.value = true;
        break;

      case ChatContactsEventsKind.event:
        var versioned = (event as ChatContactsEventsEvent).event;
        if (versioned.listVer > _sessionLocal.getChatContactsListVersion()) {
          _sessionLocal.setChatContactsListVersion(versioned.listVer);

          for (var node in versioned.events) {
            if (node.kind == ChatContactEventKind.created) {
              node as EventChatContactCreated;
              _putChatContact(
                HiveChatContact(
                  ChatContact(
                    node.contactId,
                    name: node.name,
                  ),
                  versioned.ver,
                  null,
                ),
              );

              continue;
            } else if (node.kind == ChatContactEventKind.deleted) {
              _contactLocal.remove(node.contactId);
              continue;
            }

            HiveChatContact? contactEntity =
                _contactLocal.get(node.contactId) ??
                    await _fetchById(node.contactId);
            contactEntity?.ver = versioned.ver;

            if (contactEntity == null) {
              // Failed to find `ChatContact` in the local database or fetch it
              // from the remote, so assume that it doesn't exist anymore and
              // the current events can be ignored.
              return;
            }

            switch (node.kind) {
              case ChatContactEventKind.emailAdded:
                node as EventChatContactEmailAdded;
                contactEntity.value.emails.add(node.email);
                break;

              case ChatContactEventKind.emailRemoved:
                node as EventChatContactEmailRemoved;
                contactEntity.value.emails.remove(node.email);
                break;

              case ChatContactEventKind.favorited:
                node as EventChatContactFavorited;
                contactEntity.value.favoritePosition = node.position;
                break;

              case ChatContactEventKind.groupAdded:
                node as EventChatContactGroupAdded;
                contactEntity.value.groups.add(node.group);
                break;

              case ChatContactEventKind.groupRemoved:
                node as EventChatContactGroupRemoved;
                contactEntity.value.groups
                    .removeWhere((e) => e.id == node.groupId);
                break;

              case ChatContactEventKind.nameUpdated:
                node as EventChatContactNameUpdated;
                contactEntity.value.name = node.name;
                break;

              case ChatContactEventKind.phoneAdded:
                node as EventChatContactPhoneAdded;
                contactEntity.value.phones.add(node.phone);
                break;

              case ChatContactEventKind.phoneRemoved:
                node as EventChatContactPhoneRemoved;
                contactEntity.value.phones.remove(node.phone);
                break;

              case ChatContactEventKind.unfavorited:
                contactEntity.value.favoritePosition = null;
                break;

              case ChatContactEventKind.userAdded:
                node as EventChatContactUserAdded;
                contactEntity.value.users.add(node.user);
                break;

              case ChatContactEventKind.userRemoved:
                node as EventChatContactUserRemoved;
                contactEntity.value.users
                    .removeWhere((e) => e.id == node.userId);
                break;

              case ChatContactEventKind.created:
              case ChatContactEventKind.deleted:
                // These events are handled elsewhere.
                throw StateError('Unreachable');
            }

            contactEntity.save();
            break;
          }
        }
    }
  }

  // TODO: This currently fetches all the contacts. Should be reimplemented when
  //       backend will allow to fetch single ChatContact by its ID.
  /// Fetches and persists a [HiveChatContact] by the provided [id].
  Future<HiveChatContact?> _fetchById(ChatContactId id) async {
    var contact = (await _chatContacts(first: 120))[id];
    if (contact != null) {
      _putChatContact(contact);
    }
    return contact;
  }

  /// Fetches [HiveChatContact]s from the remote with pagination.
  ///
  /// Saves all [ChatContact.users] to the [UserHiveProvider] and whole
  /// [User.gallery] to the [GalleryItemHiveProvider].
  Future<HashMap<ChatContactId, HiveChatContact>> _chatContacts({
    int? first,
    ChatContactsCursor? after,
    int? last,
    ChatContactsCursor? before,
  }) async {
    Contacts$Query$ChatContacts query = await _graphQlProvider.chatContacts(
        noFavorite: false,
        first: first,
        after: after,
        last: last,
        before: before);
    _sessionLocal.setChatContactsListVersion(query.ver);

    HashMap<ChatContactId, HiveChatContact> contacts = HashMap();
    for (var c in query.edges) {
      List<HiveUser> users = c.node.getHiveUsers();
      for (var user in users) {
        _userRepo.put(user);
      }

      HiveChatContact contact = c.node.toHive(cursor: c.cursor);
      contacts[contact.value.id] = contact;
    }

    return contacts;
  }

  /// Notifies about updates in all [ChatContact]s of the authenticated
  /// [MyUser].
  ///
  /// It's possible that in rare scenarios this subscription could emit an event
  /// which have already been applied to the state of some [ChatContact], so a
  /// client side is expected to handle all the events idempotently considering
  /// the [ChatContactVersion].
  Future<Stream<ChatContactsEvents>> _chatContactsRemoteEvents(
          ChatContactsListVersion? ver) async =>
      (await _graphQlProvider.contactsEvents(ver)).asyncExpand((event) async* {
        GraphQlProviderExceptions.fire(event);
        var events = ContactsEvents$Subscription.fromJson(event.data!)
            .chatContactsEvents;

        if (events.$$typename == 'SubscriptionInitialized') {
          events
              as ContactsEvents$Subscription$ChatContactsEvents$SubscriptionInitialized;
          yield const ChatContactsEventsInitialized();
        } else if (events.$$typename == 'ChatContactsList') {
          var list = events
              as ContactsEvents$Subscription$ChatContactsEvents$ChatContactsList;
          for (var u in list.chatContacts.nodes
              .map((e) => e.getHiveUsers())
              .expand((e) => e)) {
            _userRepo.put(u);
          }
          yield ChatContactsEventsChatContactsList(
            list.chatContacts.nodes.map((e) => e.toHive()).toList(),
            list.favoriteChatContacts.nodes.map((e) => e.toHive()).toList(),
            list.chatContacts.ver,
          );
        } else if (events.$$typename == 'ChatContactEventsVersioned') {
          var mixin = events
              as ContactsEvents$Subscription$ChatContactsEvents$ChatContactEventsVersioned;
          yield ChatContactsEventsEvent(
            ChatContactEventsVersioned(
              mixin.events.map((e) => _contactEvent(e)).toList(),
              mixin.ver,
              mixin.listVer,
            ),
          );
        }
      });

  /// Constructs a [ChatContactEvent] from the
  /// [ChatContactEventsVersionedMixin$Event].
  ChatContactEvent _contactEvent(ChatContactEventsVersionedMixin$Events e) {
    if (e.$$typename == 'EventChatContactCreated') {
      var node =
          e as ChatContactEventsVersionedMixin$Events$EventChatContactCreated;
      return EventChatContactCreated(node.contactId, node.at, node.name);
    } else if (e.$$typename == 'EventChatContactDeleted') {
      return EventChatContactDeleted(e.contactId, e.at);
    } else if (e.$$typename == 'EventChatContactEmailAdded') {
      var node = e
          as ChatContactEventsVersionedMixin$Events$EventChatContactEmailAdded;
      return EventChatContactEmailAdded(
          node.contactId, node.at, node.email.email);
    } else if (e.$$typename == 'EventChatContactEmailRemoved') {
      var node = e
          as ChatContactEventsVersionedMixin$Events$EventChatContactEmailRemoved;
      return EventChatContactEmailRemoved(
          node.contactId, node.at, node.email.email);
    } else if (e.$$typename == 'EventChatContactFavorited') {
      var node =
          e as ChatContactEventsVersionedMixin$Events$EventChatContactFavorited;
      return EventChatContactFavorited(node.contactId, node.at, node.position);
    } else if (e.$$typename == 'EventChatContactGroupAdded') {
      var node = e
          as ChatContactEventsVersionedMixin$Events$EventChatContactGroupAdded;
      return EventChatContactGroupAdded(
          node.contactId, node.at, Chat(node.group.id));
    } else if (e.$$typename == 'EventChatContactGroupRemoved') {
      var node = e
          as ChatContactEventsVersionedMixin$Events$EventChatContactGroupRemoved;
      return EventChatContactGroupRemoved(
          node.contactId, node.at, node.groupId);
    } else if (e.$$typename == 'EventChatContactNameUpdated') {
      var node = e
          as ChatContactEventsVersionedMixin$Events$EventChatContactNameUpdated;
      return EventChatContactNameUpdated(node.contactId, node.at, node.name);
    } else if (e.$$typename == 'EventChatContactPhoneAdded') {
      var node = e
          as ChatContactEventsVersionedMixin$Events$EventChatContactPhoneAdded;
      return EventChatContactPhoneAdded(
          node.contactId, node.at, node.phone.phone);
    } else if (e.$$typename == 'EventChatContactPhoneRemoved') {
      var node = e
          as ChatContactEventsVersionedMixin$Events$EventChatContactPhoneRemoved;
      return EventChatContactPhoneRemoved(
          node.contactId, node.at, node.phone.phone);
    } else if (e.$$typename == 'EventChatContactUnfavorited') {
      return EventChatContactUnfavorited(e.contactId, e.at);
    } else if (e.$$typename == 'EventChatContactUserAdded') {
      var node =
          e as ChatContactEventsVersionedMixin$Events$EventChatContactUserAdded;
      _userRepo.put(e.user.toHive());
      return EventChatContactUserAdded(
          node.contactId, node.at, node.user.toModel());
    } else if (e.$$typename == 'EventChatContactUserRemoved') {
      var node = e
          as ChatContactEventsVersionedMixin$Events$EventChatContactUserRemoved;
      return EventChatContactUserRemoved(
        node.contactId,
        node.at,
        node.userId,
      );
    } else {
      throw UnimplementedError('Unknown ContactEvent: ${e.$$typename}');
    }
  }
}
