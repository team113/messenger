// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/api/backend/extension/contact.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/contact.dart';
import '/provider/hive/gallery_item.dart';
import '/provider/hive/session.dart';
import '/provider/hive/user.dart';
import '/store/contact_rx.dart';
import '/store/pagination.dart';
import '/util/backoff.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/stream_utils.dart';
import 'event/contact.dart';
import 'model/contact.dart';
import 'user.dart';

/// Implementation of an [AbstractContactRepository].
class ContactRepository implements AbstractContactRepository {
  ContactRepository(
    this._graphQlProvider,
    this._contactLocal,
    this._userRepo,
    this._sessionLocal,
  );

  @override
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  @override
  final RxObsMap<ChatContactId, HiveRxChatContact> contacts = RxObsMap();

  @override
  final RxObsMap<ChatContactId, HiveRxChatContact> favorites = RxObsMap();

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [ChatContact]s local [Hive] storage.
  final ContactHiveProvider _contactLocal;

  /// [User]s repository.
  final UserRepository _userRepo;

  /// [SessionDataHiveProvider] used to store [ChatContactsEventsCursor].
  final SessionDataHiveProvider _sessionLocal;

  /// [PaginatedFragment] loading [contacts] with pagination.
  late final PaginatedFragment<HiveChatContact> _fragment;

  /// [CancelToken] cancelling the [PaginatedFragment.loadInitialPage].
  final CancelToken _cancelToken = CancelToken();

  /// [ContactHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  /// Subscription to the [PaginatedFragment.elements] changes.
  StreamSubscription? _fragmentSubscription;

  /// [_chatContactsRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<ChatContactsEvents>? _remoteSubscription;

  @override
  RxBool get hasNext => _fragment.hasNextPage;

  @override
  Future<void> init() async {
    status.value = RxStatus.loading();
    _initLocalSubscription();

    _fragment = PaginatedFragment<HiveChatContact>(
      cacheProvider: _contactLocal,
      compare: (a, b) {
        int result = a.value.name.val.compareTo(b.value.name.val);
        if (result == 0) {
          result = a.value.id.val.compareTo(b.value.id.val);
        }

        return result;
      },
      equal: (a, b) => a.value.id == b.value.id,
      onDelete: (e) => _contactLocal.remove(e.value.id),
      remoteProvider: RemotePageProvider(
        ({after, before, first, last}) async {
          ChatContactsCursor? afterCursor;
          if (after != null) {
            afterCursor = ChatContactsCursor(after);
          }

          ChatContactsCursor? beforeCursor;
          if (before != null) {
            beforeCursor = ChatContactsCursor(before);
          }

          ItemsPage<HiveChatContact> query = await _fetchContacts(
            after: afterCursor,
            first: first,
            before: beforeCursor,
            last: last,
          );

          return query;
        },
      ),
    );

    _fragmentSubscription = _fragment.elements.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          add(event.element);
          _putEntry(event.element);
          break;

        case OperationKind.removed:
          contacts.remove(event.element.value.id)?.dispose();
          break;

        case OperationKind.updated:
          add(event.element);
          _putEntry(event.element);
          break;
      }
    });

    _fragment.init();

    if (!_contactLocal.isEmpty) {
      status.value = RxStatus.loadingMore();
    }

    await Backoff.run(_fragment.fetchInitialPage, _cancelToken);

    _initRemoteSubscription();

    status.value = RxStatus.success();
  }

  @override
  void dispose() {
    contacts.forEach((k, v) => v.dispose());
    favorites.forEach((k, v) => v.dispose());
    _localSubscription?.cancel();
    _remoteSubscription?.close(immediate: true);
    _fragmentSubscription?.cancel();
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
  Future<void> fetchNext() => _fragment.fetchNextPage();

  @override
  Future<void> favoriteChatContact(
    ChatContactId id,
    ChatContactFavoritePosition? position,
  ) async {
    final bool fromContacts = contacts[id] != null;
    final HiveRxChatContact? contact =
        fromContacts ? contacts[id] : favorites[id];

    final ChatContactFavoritePosition? oldPosition =
        contact?.contact.value.favoritePosition;
    final ChatContactFavoritePosition newPosition;

    if (position == null) {
      final List<HiveRxChatContact> sorted = favorites.values.toList()
        ..sort(
          (a, b) => a.contact.value.favoritePosition!
              .compareTo(b.contact.value.favoritePosition!),
        );

      final double? lowestFavorite = sorted.isEmpty
          ? null
          : sorted.first.contact.value.favoritePosition!.val;

      newPosition = ChatContactFavoritePosition(
        lowestFavorite == null ? 9007199254740991 : lowestFavorite / 2,
      );
    } else {
      newPosition = position;
    }

    contact?.contact.update((c) => c?.favoritePosition = newPosition);
    if (fromContacts) {
      contacts.remove(id);
      favorites.addIf(contact != null, id, contact!);
    } else {
      favorites.emit(
        MapChangeNotification.updated(contact?.id, contact?.id, contact),
      );
    }

    try {
      await _graphQlProvider.favoriteChatContact(id, newPosition);
    } catch (e) {
      contact?.contact.update((c) => c?.favoritePosition = oldPosition);
      if (fromContacts) {
        favorites.remove(id);
        contacts.addIf(contact != null, id, contact!);
      } else {
        favorites.emit(
          MapChangeNotification.updated(contact?.id, contact?.id, contact),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> unfavoriteChatContact(ChatContactId id) async {
    final HiveRxChatContact? contact = favorites[id];
    final ChatContactFavoritePosition? oldPosition =
        contact?.contact.value.favoritePosition;

    contact?.contact.update((c) => c?.favoritePosition = null);
    favorites.remove(id);
    contacts.addIf(contact != null, id, contact!);

    try {
      await _graphQlProvider.unfavoriteChatContact(id);
    } catch (e) {
      contact.contact.update((c) => c?.favoritePosition = oldPosition);
      contacts.remove(id);
      favorites[id] = contact;
      rethrow;
    }
  }

  /// Puts the provided [contact] to [Hive].
  Future<void> _putEntry(
    HiveChatContact contact, {
    bool add = false,
  }) async {
    var saved = _contactLocal.get(contact.value.id);
    // TODO: Version should not be zero at all.
    if (saved == null ||
        saved.ver <= contact.ver ||
        contact.ver.internal == BigInt.zero) {
      if (saved != null && contact.cursor == null) {
        contact.cursor = saved.cursor;
      }
      if (add) {
        await _contactLocal.add(contact);
      } else {
        await _contactLocal.put(contact);
      }
    }
  }

  /// Adds the provided [HiveChatContact] to the [contacts] or [favorites] list.
  add(HiveChatContact contact) {
    if (contact.value.favoritePosition == null) {
      favorites.remove(contact.value.id);
      HiveRxChatContact? rxContact = contacts[contact.value.id];
      if (rxContact == null) {
        contacts[contact.value.id] = HiveRxChatContact(_userRepo, contact)
          ..init();
      } else {
        rxContact.contact.value = contact.value;
      }
    } else {
      contacts.remove(contact.value.id);
      HiveRxChatContact? rxContact = favorites[contact.value.id];
      if (rxContact == null) {
        favorites[contact.value.id] = HiveRxChatContact(_userRepo, contact)
          ..init();
      } else {
        rxContact.contact.value = contact.value;
        rxContact.contact.refresh();
        favorites.emit(
          MapChangeNotification.updated(rxContact.id, rxContact.id, rxContact),
        );
      }
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
      }
    }
  }

  /// Initializes [_chatContactsRemoteEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    _remoteSubscription?.close(immediate: true);
    _remoteSubscription = StreamQueue(
      _chatContactsRemoteEvents(_sessionLocal.getChatContactsListVersion),
    );
    await _remoteSubscription!.execute(_contactRemoteEvent,
        onStaleVersion: () async {
      await _contactLocal.clear();
      _contactLocal;
      _fragment.clear();
      _fragment.fetchInitialPage();
    });
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
          _putEntry(c, add: true);
          _fragment.add(c);
        }
        break;

      case ChatContactsEventsKind.event:
        var versioned = (event as ChatContactsEventsEvent).event;
        if (versioned.listVer > _sessionLocal.getChatContactsListVersion()) {
          _sessionLocal.setChatContactsListVersion(versioned.listVer);

          for (var node in versioned.events) {
            if (node.kind == ChatContactEventKind.created) {
              node as EventChatContactCreated;
              final HiveChatContact contact = HiveChatContact(
                ChatContact(
                  node.contactId,
                  name: node.name,
                ),
                versioned.ver,
                null,
              );
              _putEntry(contact, add: true);
              _fragment.add(contact);

              continue;
            } else if (node.kind == ChatContactEventKind.deleted) {
              _contactLocal.remove(node.contactId);
              continue;
            }

            HiveChatContact? contactEntity = _contactLocal.get(node.contactId);
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
          }
        }
    }
  }

  /// Fetches [HiveChatContact]s from the remote with pagination.
  ///
  /// Saves all [ChatContact.users] to the [UserHiveProvider] and whole
  /// [User.gallery] to the [GalleryItemHiveProvider].
  Future<ItemsPage<HiveChatContact>> _fetchContacts({
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
      before: before,
    );

    _sessionLocal.setChatContactsListVersion(query.ver);

    final List<HiveChatContact> contacts = [];
    for (var c in query.edges) {
      final List<HiveUser> users = c.node.getHiveUsers();
      for (var user in users) {
        _userRepo.put(user);
      }

      contacts.add(c.node.toHive(cursor: c.cursor));
    }

    return ItemsPage<HiveChatContact>(contacts, query.pageInfo);
  }

  /// Notifies about updates in all [ChatContact]s of the authenticated
  /// [MyUser].
  ///
  /// It's possible that in rare scenarios this subscription could emit an event
  /// which have already been applied to the state of some [ChatContact], so a
  /// client side is expected to handle all the events idempotently considering
  /// the [ChatContactVersion].
  Stream<ChatContactsEvents> _chatContactsRemoteEvents(
    ChatContactsListVersion? Function() ver,
  ) =>
      _graphQlProvider.contactsEvents(ver).asyncExpand((event) async* {
        var events = ContactsEvents$Subscription.fromJson(event.data!)
            .chatContactsEvents;

        if (events.$$typename == 'SubscriptionInitialized') {
          events
              as ContactsEvents$Subscription$ChatContactsEvents$SubscriptionInitialized;
          yield const ChatContactsEventsInitialized();
        } else if (events.$$typename == 'ChatContactsList') {
          var list = events
              as ContactsEvents$Subscription$ChatContactsEvents$ChatContactsList;
          for (var u in list.chatContacts.edges
              .map((e) => e.node.getHiveUsers())
              .expand((e) => e)) {
            _userRepo.put(u);
          }
          for (var u in list.favoriteChatContacts.nodes
              .map((e) => e.getHiveUsers())
              .expand((e) => e)) {
            _userRepo.put(u);
          }
          yield ChatContactsEventsChatContactsList(
            list.chatContacts.edges
                .map((e) => e.node.toHive(cursor: e.cursor))
                .toList(),
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
