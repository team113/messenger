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
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/api/backend/extension/contact.dart';
import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/search.dart';
import '/provider/gql/exceptions.dart' show StaleVersionException;
import '/provider/gql/graphql.dart';
import '/provider/hive/contact.dart';
import '/provider/hive/session.dart';
import '/provider/hive/user.dart';
import '/store/contact_rx.dart';
import '/store/pagination.dart';
import '/store/pagination/graphql.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/stream_utils.dart';
import '/util/web/web_utils.dart';
import 'event/contact.dart';
import 'model/contact.dart';
import 'pagination/combined_pagination.dart';
import 'search.dart';
import 'user.dart';

/// Implementation of an [AbstractContactRepository].
class ContactRepository extends DisposableInterface
    implements AbstractContactRepository {
  ContactRepository(
    this._graphQlProvider,
    this._contactLocal,
    this._userRepo,
    this._sessionLocal,
  );

  @override
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  @override
  final RxObsMap<ChatContactId, HiveRxChatContact> contacts = RxObsMap();

  @override
  final RxObsMap<ChatContactId, HiveRxChatContact> favorites = RxObsMap();

  // TODO: Unite [contacts] and [favorites] into single [paginated] list.
  @override
  final RxObsMap<ChatContactId, HiveRxChatContact> allContacts = RxObsMap();

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [ChatContact]s local [Hive] storage.
  final ContactHiveProvider _contactLocal;

  /// [User]s repository.
  final UserRepository _userRepo;

  /// [SessionDataHiveProvider] used to store [ChatContactsEventsCursor].
  final SessionDataHiveProvider _sessionLocal;

  /// [ContactHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  /// [CombinedPagination] loading [contacts] and [favorites] with pagination.
  late final CombinedPagination<HiveChatContact, ChatContactId> _pagination;

  /// [Pagination] loading [favorites] contacts with pagination.
  late Pagination<HiveChatContact, FavoriteChatContactsCursor, ChatContactId>
      _favoriteContactsPagination;

  /// [Pagination] loading [contacts] with pagination.
  late Pagination<HiveChatContact, ChatContactsCursor, ChatContactId>
      _contactsPagination;

  /// Subscription to the [_pagination] changes.
  StreamSubscription? _paginationSubscription;

  /// [_chatContactsRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<ChatContactsEvents>? _remoteSubscription;

  @override
  RxBool get hasNext => _pagination.hasNext;

  @override
  RxBool get nextLoading => _pagination.nextLoading;

  @override
  Future<void> onInit() async {
    status.value = RxStatus.loading();

    _initPagination();
    _initLocalSubscription();
    _initRemoteSubscription();

    super.onInit();
  }

  @override
  void onClose() {
    allContacts.forEach((_, v) => v.dispose());
    _localSubscription?.cancel();
    _paginationSubscription?.cancel();
    _remoteSubscription?.close(immediate: true);

    super.onClose();
  }

  @override
  Future<void> next() => _pagination.next();

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
    final bool isFavorite = favorites.containsKey(id);

    final HiveRxChatContact? oldChatContact =
        (isFavorite ? favorites : contacts).remove(id);

    try {
      await _graphQlProvider.deleteChatContact(id);
    } catch (_) {
      (isFavorite ? favorites : contacts)
          .addIf(oldChatContact != null, id, oldChatContact!);
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
          (a, b) => b.contact.value.favoritePosition!
              .compareTo(a.contact.value.favoritePosition!),
        );

      final double? highestFavorite = sorted.isEmpty
          ? null
          : sorted.first.contact.value.favoritePosition!.val;

      newPosition = ChatContactFavoritePosition(
        highestFavorite == null ? 1 : highestFavorite * 2,
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

  @override
  SearchResult<ChatContactId, RxChatContact> search({
    UserName? name,
    UserEmail? email,
    UserPhone? phone,
  }) {
    if (name == null && email == null && phone == null) {
      return SearchResultImpl();
    }

    Pagination<RxChatContact, ChatContactsCursor, ChatContactId>? pagination;
    if (name != null) {
      pagination = Pagination(
        perPage: 30,
        provider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) {
            return searchByName(
              name,
              after: after,
              first: first,
            );
          },
        ),
        onKey: (RxChatContact u) => u.id,
      );
    }

    final List<RxChatContact> contacts = [
      ...this.contacts.values,
      ...favorites.values
    ]
        .where((u) =>
            (phone != null && u.contact.value.phones.contains(phone)) ||
            (email != null && u.contact.value.emails.contains(email)) ||
            (name != null &&
                u.contact.value.name.val
                        .toLowerCase()
                        .contains(name.val.toLowerCase()) ==
                    true))
        .toList();

    Map<ChatContactId, RxChatContact> toMap(RxChatContact? c) {
      if (c != null) {
        return {c.id: c};
      }

      return {};
    }

    final SearchResultImpl<ChatContactId, RxChatContact> searchResult =
        SearchResultImpl(
      pagination: pagination,
      initial: [
        {for (var u in contacts) u.id: u},
        if (email != null) searchByEmail(email).then(toMap),
        if (phone != null) searchByPhone(phone).then(toMap),
      ],
    );

    return searchResult;
  }

  @override
  RxChatContact? get(ChatContactId id) {
    // TODO: Get [ChatContact] from remote if it's not stored locally.
    return contacts[id] ?? favorites[id];
  }

  /// Removes a [ChatContact] identified by the provided [id].
  Future<void> remove(ChatContactId id) => _contactLocal.remove(id);

  /// Searches [ChatContact]s by the provided [UserName].
  ///
  /// This is a fuzzy search.
  Future<Page<RxChatContact, ChatContactsCursor>> searchByName(
    UserName name, {
    ChatContactsCursor? after,
    int? first,
  }) =>
      _search(name: name, after: after, first: first);

  /// Searches [ChatContact]s by the provided [UserEmail].
  ///
  /// This is an exact match search.
  Future<RxChatContact?> searchByEmail(UserEmail email) async =>
      (await _search(email: email)).edges.firstOrNull;

  /// Searches [ChatContact]s by the provided [UserPhone].
  ///
  /// This is an exact match search.
  Future<RxChatContact?> searchByPhone(UserPhone phone) async =>
      (await _search(phone: phone)).edges.firstOrNull;

  /// Initializes the [_pagination].
  Future<void> _initPagination() async {
    _favoriteContactsPagination = Pagination(
      onKey: (e) => e.value.id,
      perPage: 15,
      provider: GraphQlPageProvider(
        fetch: ({after, before, first, last}) => _favoriteContacts(
          after: after,
          first: first,
          before: before,
          last: last,
        ),
      ),
      compare: (a, b) =>
          b.value.favoritePosition!.compareTo(a.value.favoritePosition!),
    );

    _contactsPagination = Pagination(
      onKey: (e) => e.value.id,
      perPage: 15,
      provider: GraphQlPageProvider(
        fetch: ({after, before, first, last}) => _chatContacts(
          after: after,
          first: first,
          before: before,
          last: last,
        ),
      ),
      compare: (a, b) => a.value.name.val.compareTo(b.value.name.val),
    );

    _pagination = CombinedPagination([
      CombinedPaginationEntry(
        _favoriteContactsPagination,
        addIf: (e) => e.value.favoritePosition != null,
      ),
      CombinedPaginationEntry(
        _contactsPagination,
        addIf: (e) => e.value.favoritePosition == null,
      ),
    ]);

    _paginationSubscription = _pagination.changes.listen((event) async {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          _putChatContact(event.value!, pagination: true, ignoreVersion: true);
          break;

        case OperationKind.removed:
          remove(event.value!.value.id);
          break;
      }
    });

    await _pagination.around();

    status.value = RxStatus.success();
  }

  /// Searches [ChatContact]s by the given criteria.
  ///
  /// Exactly one of [email]/[phone]/[name] arguments must be specified (be
  /// non-`null`).
  Future<Page<RxChatContact, ChatContactsCursor>> _search({
    UserName? name,
    UserEmail? email,
    UserPhone? phone,
    ChatContactsCursor? after,
    int? first,
  }) async {
    const maxInt = 120;
    var query = await _graphQlProvider.searchChatContacts(
      name: name,
      email: email,
      phone: phone,
      after: after,
      first: first ?? maxInt,
    );

    final List<HiveChatContact> result =
        query.searchChatContacts.edges.map((c) => c.node.toHive()).toList();

    for (HiveChatContact user in result) {
      _putChatContact(user);
    }

    // Wait for [Hive] to populate the added [HiveChatContact] from
    // [_putChatContact] invoked earlier.
    await Future.delayed(Duration.zero);

    List<RxChatContact> contacts =
        result.map((e) => get(e.value.id)).whereNotNull().toList();

    return Page(
      RxList(contacts),
      query.searchChatContacts.pageInfo.toModel((c) => ChatContactsCursor(c)),
    );
  }

  /// Puts the provided [contact] to [Pagination] and [Hive].
  Future<void> _putChatContact(
    HiveChatContact contact, {
    bool pagination = false,
    bool ignoreVersion = false,
  }) async {
    final ChatContactId contactId = contact.value.id;
    final HiveRxChatContact? saved = allContacts[contactId];

    // Check the versions first, if [ignoreVersion] is `false`.
    if (saved != null && !ignoreVersion) {
      if (saved.ver >= contact.ver) {
        if (pagination) {
          if (contact.value.favoritePosition != null) {
            favorites[contactId] ??= saved;
          } else {
            contacts[contactId] ??= saved;
          }
        } else {
          await _pagination.put(contact);
        }

        return;
      }
    }

    // [pagination] is `true`, if the [contact] is received from [Pagination],
    // thus otherwise we should try putting it to it.
    if (!pagination) {
      await _pagination.put(contact);
    }

    _add(contact, pagination: pagination);

    // TODO: https://github.com/team113/messenger/issues/27
    // Don't write to [Hive] from popup, as [Hive] doesn't support isolate
    // synchronization, thus writes from multiple applications may lead to
    // missing events.
    if (!WebUtils.isPopup) {
      HiveChatContact? saved;

      // If version is ignored, there's no need to retrieve the stored chat.
      if (!ignoreVersion) {
        saved = await _contactLocal.get(contactId);
      }

      // TODO: Version should not be zero at all.
      if (saved == null ||
          saved.ver < contact.ver ||
          contact.ver.internal == BigInt.zero) {
        await _contactLocal.put(contact);
      }
    }
  }

  /// Adds the provided [HiveChatContact] to the [allContacts] and optionally to
  /// the [contacts] or [favorites].
  void _add(HiveChatContact contact, {bool pagination = false}) {
    final ChatContactId contactId = contact.value.id;

    HiveRxChatContact? entry = allContacts[contactId];

    if (entry == null) {
      entry = HiveRxChatContact(_userRepo, contact)..init();
      allContacts[contactId] = entry;
    } else {
      entry.contact.value = contact.value;
    }

    if (pagination) {
      if (contact.value.favoritePosition == null) {
        favorites.remove(contactId);

        contacts[contactId] ??= entry;
        contacts.emit(
          MapChangeNotification.updated(entry.id, entry.id, entry),
        );
      } else {
        contacts.remove(contactId);

        favorites[contactId] ??= entry;
        favorites.emit(
          MapChangeNotification.updated(entry.id, entry.id, entry),
        );
      }
    }
  }

  /// Initializes [ContactHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    _localSubscription = StreamIterator(_contactLocal.boxEvents);
    while (await _localSubscription!.moveNext()) {
      final BoxEvent event = _localSubscription!.current;
      final ChatContactId contactId = ChatContactId(event.key);

      if (event.deleted) {
        allContacts.remove(contactId)?.dispose();
        favorites.remove(contactId);
        contacts.remove(contactId);
        _pagination.remove(contactId);
      } else {
        final HiveRxChatContact? contact = allContacts[contactId];
        if (contact == null || contact.ver <= event.value.ver) {
          _add(event.value);
        }
      }
    }
  }

  /// Initializes [_chatContactsRemoteEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    _remoteSubscription?.close(immediate: true);
    _remoteSubscription = StreamQueue(
      _chatContactsRemoteEvents(_sessionLocal.getChatContactsListVersion),
    );
    await _remoteSubscription!.execute(
      _contactRemoteEvent,
      onError: (e) async {
        if (e is StaleVersionException) {
          allContacts.clear();
          contacts.clear();
          favorites.clear();

          await _contactLocal.clear();
          await _pagination.clear();
          await _pagination.around();
        }
      },
    );
  }

  /// Handles [ChatContactEvent] from the [_chatContactsRemoteEvents]
  /// subscription.
  Future<void> _contactRemoteEvent(ChatContactsEvents event) async {
    switch (event.kind) {
      case ChatContactsEventsKind.initialized:
        break;

      case ChatContactsEventsKind.chatContactsList:
        // No-op, as contacts are loaded through [_pagination].
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
                  null,
                ),
              );

              continue;
            } else if (node.kind == ChatContactEventKind.deleted) {
              remove(node.contactId);
              continue;
            }

            HiveChatContact? contactEntity =
                await _contactLocal.get(node.contactId) ??
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

            _putChatContact(contactEntity);
          }
        }
    }
  }

  // TODO: This currently fetches all the contacts. Should be reimplemented when
  //       backend will allow to fetch single ChatContact by its ID.
  /// Fetches and persists a [HiveChatContact] by the provided [id].
  Future<HiveChatContact?> _fetchById(ChatContactId id) async {
    var contact =
        (await _chatContacts()).edges.firstWhereOrNull((e) => e.value.id == id);
    if (contact != null) {
      _putChatContact(contact);
    }
    return contact;
  }

  /// Fetches [HiveChatContact]s ordered by their [ChatContact.name] with
  /// pagination.
  Future<Page<HiveChatContact, ChatContactsCursor>> _chatContacts({
    int? first,
    ChatContactsCursor? after,
    int? last,
    ChatContactsCursor? before,
    bool noFavorite = true,
  }) async {
    Contacts$Query$ChatContacts query = (await _graphQlProvider.chatContacts(
      first: first,
      after: after,
      last: last,
      before: before,
      noFavorite: noFavorite,
    ))
        .chatContacts;
    _sessionLocal.setChatContactsListVersion(query.ver);

    for (var c in query.edges) {
      final List<HiveUser> users = c.node.getHiveUsers();
      for (var user in users) {
        _userRepo.put(user);
      }
    }

    return Page(
      RxList(
        query.edges.map((e) => e.node.toHive(cursor: e.cursor)).toList(),
      ),
      query.pageInfo.toModel((c) => ChatContactsCursor(c)),
    );
  }

  /// Fetches favorite [HiveChatContact]s ordered by their
  /// [ChatContact.favoritePosition] with pagination.
  Future<Page<HiveChatContact, FavoriteChatContactsCursor>> _favoriteContacts({
    int? first,
    FavoriteChatContactsCursor? after,
    int? last,
    FavoriteChatContactsCursor? before,
  }) async {
    FavoriteContacts$Query$FavoriteChatContacts query =
        (await _graphQlProvider.favoriteChatContacts(
      first: first,
      after: after,
      last: last,
      before: before,
    ))
            .favoriteChatContacts;
    _sessionLocal.setChatContactsListVersion(query.ver);

    for (var c in query.edges) {
      final List<HiveUser> users = c.node.getHiveUsers();
      for (var user in users) {
        _userRepo.put(user);
      }
    }

    return Page(
      RxList(
        query.edges
            .map((e) => e.node.toHive(favoriteCursor: e.cursor))
            .toList(),
      ),
      query.pageInfo.toModel((c) => FavoriteChatContactsCursor(c)),
    );
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
          // No-op, as contacts are loaded through [_pagination].
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
