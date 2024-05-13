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

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/extension/contact.dart';
import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/paginated.dart';
import '/provider/gql/exceptions.dart' show StaleVersionException;
import '/provider/gql/graphql.dart';
import '/provider/hive/contact.dart';
import '/provider/hive/contact_sorting.dart';
import '/provider/hive/favorite_contact.dart';
import '/provider/hive/session_data.dart';
import '/provider/hive/user.dart';
import '/store/contact_rx.dart';
import '/store/pagination.dart';
import '/store/pagination/graphql.dart';
import '/util/event_pool.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/stream_utils.dart';
import 'event/contact.dart';
import 'model/contact.dart';
import 'paginated.dart';
import 'pagination/combined_pagination.dart';
import 'pagination/hive.dart';
import 'pagination/hive_graphql.dart';
import 'user.dart';

/// Implementation of an [AbstractContactRepository].
class ContactRepository extends DisposableInterface
    implements AbstractContactRepository {
  ContactRepository(
    this._graphQlProvider,
    this._contactLocal,
    this._favoriteLocal,
    this._contactSortingLocal,
    this._userRepo,
    this._sessionLocal,
  );

  @override
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  @override
  final RxObsMap<ChatContactId, HiveRxChatContact> paginated = RxObsMap();

  @override
  final RxObsMap<ChatContactId, HiveRxChatContact> contacts = RxObsMap();

  /// [EventPool]s debouncing [ContactField] related [ChatContactsEvents]
  /// handling.
  final Map<ChatContactId, EventPool<ContactField>> _pools = {};

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [ChatContact]s local [Hive] storage.
  final ContactHiveProvider _contactLocal;

  /// [ChatContactId]s sorted by [UserName] representing [ChatContact]s [Hive]
  /// storage.
  final ContactSortingHiveProvider _contactSortingLocal;

  /// [ChatContactId]s sorted by [ChatContactFavoritePosition] representing
  /// favorite [ChatContact]s [Hive] storage.
  final FavoriteContactHiveProvider _favoriteLocal;

  /// [User]s repository.
  final UserRepository _userRepo;

  /// [SessionDataHiveProvider] for storing and accessing
  /// [SessionData.favoriteContactsSynchronized].
  final SessionDataHiveProvider _sessionLocal;

  /// [ContactHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  /// [CombinedPagination] loading [paginated] with pagination.
  late final CombinedPagination<HiveChatContact, ChatContactId> _pagination;

  /// Subscription to the [_pagination] changes.
  StreamSubscription? _paginationSubscription;

  /// [_chatContactsRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<ChatContactsEvents>? _remoteSubscription;

  /// [Mutex]es guarding access to the [get] method.
  final Map<ChatContactId, Mutex> _getGuards = {};

  @override
  RxBool get hasNext => _pagination.hasNext;

  @override
  RxBool get nextLoading => _pagination.nextLoading;

  @override
  Future<void> onInit() async {
    Log.debug('onInit()', '$runtimeType');

    status.value = RxStatus.loading();

    _initPagination();
    _initLocalSubscription();
    _initRemoteSubscription();

    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    contacts.forEach((_, v) => v.dispose());
    _localSubscription?.cancel();
    _paginationSubscription?.cancel();
    _remoteSubscription?.close(immediate: true);
    _pagination.dispose();

    super.onClose();
  }

  @override
  Future<void> next() {
    Log.debug('next()', '$runtimeType');
    return _pagination.next();
  }

  @override
  Future<void> clearCache() {
    Log.debug('clearCache()', '$runtimeType');
    return _contactLocal.clear();
  }

  // TODO: Forbid creating multiple ChatContacts with the same User?
  @override
  Future<void> createChatContact(UserName name, UserId id) async {
    Log.debug('createChatContact($name, $id)', '$runtimeType');

    final response = await _graphQlProvider.createChatContact(
      name: name,
      records: [ChatContactRecord(userId: id)],
    );

    final events = ChatContactsEventsEvent(
      ChatContactEventsVersioned(
        response.events.map((e) => _contactEvent(e)).toList(),
        response.ver,
        response.listVer,
      ),
    );

    await _contactRemoteEvent(events, updateVersion: false);
  }

  @override
  Future<void> deleteContact(ChatContactId id) async {
    Log.debug('deleteContact($id)', '$runtimeType');

    final HiveRxChatContact? oldChatContact = paginated.remove(id);

    try {
      await _graphQlProvider.deleteChatContact(id);
    } catch (_) {
      paginated.addIf(oldChatContact != null, id, oldChatContact!);
      rethrow;
    }
  }

  @override
  Future<void> changeContactName(ChatContactId id, UserName name) async {
    Log.debug('changeContactName($id, $name)', '$runtimeType');

    final HiveRxChatContact? contact = paginated[id];
    final UserName? oldName = contact?.contact.value.name;

    contact?.contact.update((c) => c?.name = name);
    _emit(MapChangeNotification.updated(contact?.id, contact?.id, contact));

    try {
      await _graphQlProvider.changeContactName(id, name);
    } catch (_) {
      contact?.contact.update((c) => c?.name = oldName!);
      _emit(MapChangeNotification.updated(contact?.id, contact?.id, contact));
      rethrow;
    }
  }

  @override
  Future<void> favoriteChatContact(
    ChatContactId id,
    ChatContactFavoritePosition? position,
  ) async {
    Log.debug('favoriteChatContact($id, $position)', '$runtimeType');

    final HiveRxChatContact? contact = contacts[id];

    final ChatContactFavoritePosition newPosition;

    if (position == null) {
      final List<HiveRxChatContact> favorites = contacts.values
          .where((e) => e.contact.value.favoritePosition != null)
          .toList();

      final List<HiveRxChatContact> sorted = favorites..sort();

      final double? highestFavorite = sorted.isEmpty
          ? null
          : sorted.first.contact.value.favoritePosition!.val;

      newPosition = ChatContactFavoritePosition(
        highestFavorite == null ? 1 : highestFavorite * 2,
      );
    } else {
      newPosition = position;
    }

    await _debounce(
      field: ContactField.favoritePosition,
      current: () => contact?.contact.value.favoritePosition,
      saved: () async => (await _contactLocal.get(id))?.value.favoritePosition,
      contactId: id,
      value: newPosition,
      update: (pos) {
        contact?.contact.update((c) => c?.favoritePosition = pos);
        paginated.emit(
          MapChangeNotification.updated(contact?.id, contact?.id, contact),
        );
      },
      mutation: (pos) async {
        if (pos != null) {
          return await _graphQlProvider.favoriteChatContact(id, pos);
        } else {
          return await _graphQlProvider.unfavoriteChatContact(id);
        }
      },
    );
  }

  @override
  Future<void> unfavoriteChatContact(ChatContactId id) async {
    Log.debug('unfavoriteChatContact($id)', '$runtimeType');

    final HiveRxChatContact? contact = paginated[id];

    await _debounce(
      field: ContactField.favoritePosition,
      current: () => contact?.contact.value.favoritePosition,
      saved: () async => (await _contactLocal.get(id))?.value.favoritePosition,
      contactId: id,
      value: null,
      update: (pos) {
        contact?.contact.update((c) => c?.favoritePosition = pos);
        paginated.emit(
          MapChangeNotification.updated(contact?.id, contact?.id, contact),
        );
      },
      mutation: (pos) async {
        if (pos != null) {
          return await _graphQlProvider.favoriteChatContact(id, pos);
        } else {
          return await _graphQlProvider.unfavoriteChatContact(id);
        }
      },
    );
  }

  @override
  Paginated<ChatContactId, RxChatContact> search({
    UserName? name,
    UserEmail? email,
    UserPhone? phone,
  }) {
    Log.debug('search($name, $email, $phone)', '$runtimeType');

    if (name == null && email == null && phone == null) {
      return PaginatedImpl();
    }

    Pagination<RxChatContact, ChatContactsCursor, ChatContactId>? pagination;
    if (name != null) {
      pagination = Pagination(
        perPage: 30,
        provider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) {
            return searchByName(name, after: after, first: first);
          },
        ),
        onKey: (RxChatContact u) => u.id,
      );
    }

    final List<RxChatContact> contacts = this
        .contacts
        .values
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

    return PaginatedImpl(
      pagination: pagination,
      initial: [
        {for (var u in contacts) u.id: u},
        if (email != null) searchByEmail(email).then(toMap),
        if (phone != null) searchByPhone(phone).then(toMap),
      ],
    );
  }

  @override
  FutureOr<RxChatContact?> get(ChatContactId id) async {
    Log.debug('get($id)', '$runtimeType');

    HiveRxChatContact? contact = contacts[id];
    if (contact != null) {
      return contact;
    }

    // If [contact] doesn't exists, we should lock the [mutex] to avoid remote
    // double invoking.
    Mutex? mutex = _getGuards[id];
    if (mutex == null) {
      mutex = Mutex();
      _getGuards[id] = mutex;
    }

    return mutex.protect(() async {
      contact = contacts[id];
      if (contact == null) {
        final HiveChatContact? hiveContact = await _contactLocal.get(id);

        // [ChatContact] may be added to the [contacts] list during async
        // operation above.
        if (contacts[id] != null) {
          return contacts[id];
        }

        if (hiveContact != null) {
          contact = await _putChatContact(hiveContact);
        }

        if (contact == null) {
          final query = (await _graphQlProvider.chatContact(id)).chatContact;

          // [ChatContact] may be added to the [contacts] list during async
          // operation above.
          if (contacts[id] != null) {
            return contacts[id];
          }

          if (query != null) {
            contact = await _putChatContact(query.toHive());
          }
        }
      }

      return contact;
    });
  }

  /// Removes a [ChatContact] identified by the provided [id].
  Future<void> remove(ChatContactId id) async {
    Log.debug('remove($id)', '$runtimeType');

    final ChatContact? contact =
        contacts[id]?.contact.value ?? (await _contactLocal.get(id))?.value;

    if (contact != null) {
      for (User user in contact.users) {
        await _userRepo.removeContact(contact.id, user.id);
      }
    }

    await _contactLocal.remove(id);
  }

  /// Searches [ChatContact]s by the provided [UserName].
  ///
  /// This is a fuzzy search.
  Future<Page<RxChatContact, ChatContactsCursor>> searchByName(
    UserName name, {
    ChatContactsCursor? after,
    int? first,
  }) async {
    Log.debug('searchByName($name, $after, $first)', '$runtimeType');
    return await _search(name: name, after: after, first: first);
  }

  /// Searches [ChatContact]s by the provided [UserEmail].
  ///
  /// This is an exact match search.
  Future<RxChatContact?> searchByEmail(UserEmail email) async {
    Log.debug('searchByEmail($email)', '$runtimeType');
    return (await _search(email: email)).edges.firstOrNull;
  }

  /// Searches [ChatContact]s by the provided [UserPhone].
  ///
  /// This is an exact match search.
  Future<RxChatContact?> searchByPhone(UserPhone phone) async {
    Log.debug('searchByPhone($phone)', '$runtimeType');
    return (await _search(phone: phone)).edges.firstOrNull;
  }

  /// Emits the provided [event] in the [contacts] and [paginated].
  void _emit(MapChangeNotification<ChatContactId, HiveRxChatContact> event) {
    contacts.emit(event);
    paginated.emit(event);
  }

  /// Initializes the [_pagination].
  Future<void> _initPagination() async {
    Log.debug('_initPagination()', '$runtimeType');

    final Pagination<HiveChatContact, FavoriteChatContactsCursor, ChatContactId>
        favoriteContactsPagination = Pagination(
      onKey: (e) => e.value.id,
      perPage: 15,
      provider: HiveGraphQlPageProvider(
        hiveProvider: HivePageProvider(
          _contactLocal,
          getCursor: (e) => e?.favoriteCursor,
          getKey: (e) => e.value.id,
          orderBy: (_) => _favoriteLocal.values,
          isFirst: (_) =>
              _sessionLocal.getFavoriteContactsSynchronized() == true,
          isLast: (_) =>
              _sessionLocal.getFavoriteContactsSynchronized() == true,
          strategy: PaginationStrategy.fromEnd,
          reversed: true,
        ),
        graphQlProvider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) async {
            final Page<HiveChatContact, FavoriteChatContactsCursor> page =
                await _favoriteContacts(
              after: after,
              first: first,
              before: before,
              last: last,
            );

            if (page.info.hasNext == false) {
              _sessionLocal.setFavoriteContactsSynchronized(true);
            }

            return page;
          },
        ),
      ),
      compare: (a, b) => a.value.compareTo(b.value),
    );

    final Pagination<HiveChatContact, ChatContactsCursor, ChatContactId>
        contactsPagination = Pagination(
      onKey: (e) => e.value.id,
      perPage: 15,
      provider: HiveGraphQlPageProvider(
        hiveProvider: HivePageProvider(
          _contactLocal,
          getCursor: (e) => e?.cursor,
          getKey: (e) => e.value.id,
          orderBy: (_) => _contactSortingLocal.values,
          isFirst: (_) => _sessionLocal.getContactsSynchronized() == true,
          isLast: (_) => _sessionLocal.getContactsSynchronized() == true,
        ),
        graphQlProvider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) async {
            final Page<HiveChatContact, ChatContactsCursor> page =
                await _chatContacts(
              after: after,
              first: first,
              before: before,
              last: last,
            );

            if (page.info.hasNext == false) {
              _sessionLocal.setContactsSynchronized(true);
            }

            return page;
          },
        ),
      ),
      compare: (a, b) => a.value.compareTo(b.value),
    );

    _pagination = CombinedPagination([
      CombinedPaginationEntry(
        favoriteContactsPagination,
        addIf: (e) => e.value.favoritePosition != null,
      ),
      CombinedPaginationEntry(
        contactsPagination,
        addIf: (e) => e.value.favoritePosition == null,
      ),
    ]);

    _paginationSubscription = _pagination.changes.listen((event) async {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          _putChatContact(event.value!, pagination: true);
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
    Log.debug('_search($name, $email, $phone, $after, $first)', '$runtimeType');

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

    final List<RxChatContact> contacts =
        (await Future.wait(result.map((e) async => await get(e.value.id))))
            .whereNotNull()
            .toList();

    return Page(
      RxList(contacts),
      query.searchChatContacts.pageInfo.toModel((c) => ChatContactsCursor(c)),
    );
  }

  /// Puts the provided [contact] to [Pagination] and [Hive].
  Future<HiveRxChatContact> _putChatContact(
    HiveChatContact contact, {
    bool pagination = false,
  }) async {
    Log.debug('_putChatContact($contact, $pagination)', '$runtimeType');

    final ChatContactId contactId = contact.value.id;
    final HiveRxChatContact? saved = contacts[contactId];

    if (saved != null) {
      if (saved.ver > contact.ver) {
        if (pagination) {
          paginated[contactId] ??= saved;
        } else {
          await _pagination.put(contact);
        }

        return saved;
      }
    }

    final HiveRxChatContact entry = _add(contact, pagination: pagination);

    // [pagination] is `true`, if the [contact] is received from [Pagination],
    // thus otherwise we should try putting it to it.
    if (!pagination) {
      await _pagination.put(contact);
    }

    return entry;
  }

  /// Adds the provided [HiveChatContact] to the [contacts] and optionally to
  /// the [paginated].
  HiveRxChatContact _add(HiveChatContact contact, {bool pagination = false}) {
    Log.debug('_add($contact, $pagination)', '$runtimeType');

    final ChatContactId contactId = contact.value.id;

    HiveRxChatContact? entry = contacts[contactId];

    bool emitUpdate = false;

    if (entry == null) {
      entry = HiveRxChatContact(_userRepo, contact)..init();
      contacts[contactId] = entry;
    } else {
      if (entry.contact.value.favoritePosition !=
              contact.value.favoritePosition ||
          entry.contact.value.users.length != contact.value.users.length) {
        emitUpdate = true;
      }

      entry.contact.value = contact.value;
    }

    if (pagination) {
      paginated[contactId] ??= entry;
    }

    if (emitUpdate) {
      _emit(MapChangeNotification.updated(entry.id, entry.id, entry));
    }

    return entry;
  }

  /// Initializes [ContactHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    Log.debug('_initLocalSubscription()', '$runtimeType');

    _localSubscription = StreamIterator(_contactLocal.boxEvents);
    while (await _localSubscription!.moveNext()) {
      final BoxEvent event = _localSubscription!.current;
      final ChatContactId contactId = ChatContactId(event.key);

      if (event.deleted) {
        contacts.remove(contactId)?.dispose();
        paginated.remove(contactId);
        _pagination.remove(contactId);

        _favoriteLocal.remove(contactId);
        _contactSortingLocal.remove(contactId);
      } else {
        final HiveChatContact value = event.value;

        final HiveRxChatContact? existing = contacts[value.value.id];
        final EventPool<ContactField> pool = _getPool(value.value.id);

        if (existing != null) {
          if (pool.lockedWith(
            ContactField.favoritePosition,
            value.value.favoritePosition,
          )) {
            value.value.favoritePosition =
                existing.contact.value.favoritePosition;
          }
        }

        if (existing == null) {
          _putChatContact(value);
        } else if (existing.ver <= value.ver) {
          _add(value);
        }

        if (value.value.favoritePosition != null) {
          _favoriteLocal.put(value.value.favoritePosition!, contactId);
          _contactSortingLocal.remove(contactId);
        } else {
          _contactSortingLocal.put(value.value.name, contactId);
          _favoriteLocal.remove(contactId);
        }
      }
    }
  }

  /// Initializes [_chatContactsRemoteEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    if (isClosed) {
      return;
    }

    Log.debug('_initRemoteSubscription()', '$runtimeType');

    _remoteSubscription?.close(immediate: true);
    _remoteSubscription = StreamQueue(
      _chatContactsRemoteEvents(_sessionLocal.getChatContactsListVersion),
    );
    await _remoteSubscription!.execute(
      _contactRemoteEvent,
      onError: (e) async {
        if (e is StaleVersionException) {
          contacts.clear();
          paginated.clear();

          await _contactLocal.clear();
          await _pagination.clear();
          await _sessionLocal.setFavoriteContactsSynchronized(false);
          await _sessionLocal.setContactsSynchronized(false);

          await _pagination.around();
        }
      },
    );
  }

  /// Handles [ChatContactEvent] from the [_chatContactsRemoteEvents]
  /// subscription.
  Future<void> _contactRemoteEvent(
    ChatContactsEvents event, {
    bool updateVersion = true,
  }) async {
    switch (event.kind) {
      case ChatContactsEventsKind.initialized:
        Log.debug('_contactRemoteEvent(${event.kind})', '$runtimeType');
        break;

      case ChatContactsEventsKind.chatContactsList:
        // No-op, as contacts are loaded through [_pagination].
        break;

      case ChatContactsEventsKind.event:
        final versioned = (event as ChatContactsEventsEvent).event;
        if (versioned.listVer < _sessionLocal.getChatContactsListVersion()) {
          Log.debug(
            '_contactRemoteEvent(${event.kind}): ignored ${versioned.events.map((e) => e.kind)}',
            '$runtimeType',
          );
        } else {
          // If [updateVersion] is `true`, then those events are processed and
          // should be removed from the [EventPool], or added to it otherwise
          // to prevent events overwriting each other's actions.
          if (updateVersion) {
            _sessionLocal.setChatContactsListVersion(versioned.listVer);

            versioned.events
                .removeWhere((e) => _getPool(e.contactId).processed(e));
          } else {
            for (var e in versioned.events) {
              _getPool(e.contactId).add(e);
            }
          }

          Log.debug(
            '_contactRemoteEvent(${event.kind}): ${versioned.events.map((e) => e.kind)}',
            '$runtimeType',
          );

          final Map<ChatContactId, HiveChatContact> entities = {};

          for (var node in versioned.events) {
            if (node.kind == ChatContactEventKind.created) {
              node as EventChatContactCreated;
              entities[node.contactId] =
                      HiveChatContact(
                        ChatContact(
                          node.contactId,
                          name: node.name,
                        ),
                        versioned.ver,
                        null,
                        null,
                      );

              continue;
            } else if (node.kind == ChatContactEventKind.deleted) {
              entities.remove(node.contactId);
              remove(node.contactId);
              continue;
            }

            HiveChatContact? entity = entities[node.contactId];
            if (entity == null) {
              entity = await _contactLocal.get(node.contactId) ??
                  await _fetchById(node.contactId);

              if (entity != null) {
                entities[node.contactId] = entity;
              }
            }

            if (updateVersion) {
              entity?.ver = versioned.ver;
            }

            if (entity == null) {
              // Failed to find `ChatContact` in the local database or fetch it
              // from the remote, so assume that it doesn't exist anymore and
              // the current events can be ignored.
              return;
            }

            switch (node.kind) {
              case ChatContactEventKind.emailAdded:
                node as EventChatContactEmailAdded;
                entity.value.emails.add(node.email);
                break;

              case ChatContactEventKind.emailRemoved:
                node as EventChatContactEmailRemoved;
                entity.value.emails.remove(node.email);
                break;

              case ChatContactEventKind.favorited:
                node as EventChatContactFavorited;
                entity.value.favoritePosition = node.position;
                break;

              case ChatContactEventKind.groupAdded:
                node as EventChatContactGroupAdded;
                entity.value.groups.add(node.group);
                break;

              case ChatContactEventKind.groupRemoved:
                node as EventChatContactGroupRemoved;
                entity.value.groups.removeWhere((e) => e.id == node.groupId);
                break;

              case ChatContactEventKind.nameUpdated:
                node as EventChatContactNameUpdated;
                entity.value.name = node.name;

                // Add the [entity.value] to the [node.user], as [User] has no
                // events about its [User.contacts] list changes.
                for (var e in entity.value.users) {
                  _userRepo.addContact(entity.value, e.id);
                }
                break;

              case ChatContactEventKind.phoneAdded:
                node as EventChatContactPhoneAdded;
                entity.value.phones.add(node.phone);
                break;

              case ChatContactEventKind.phoneRemoved:
                node as EventChatContactPhoneRemoved;
                entity.value.phones.remove(node.phone);
                break;

              case ChatContactEventKind.unfavorited:
                entity.value.favoritePosition = null;
                break;

              case ChatContactEventKind.userAdded:
                node as EventChatContactUserAdded;
                entity.value.users.add(node.user);

                // Add the [entity.value] to the [node.user], as [User] has no
                // events about its [User.contacts] list changes.
                _userRepo.addContact(entity.value, node.user.id);
                break;

              case ChatContactEventKind.userRemoved:
                node as EventChatContactUserRemoved;
                entity.value.users.removeWhere((e) => e.id == node.userId);

                // Remove the [node.contactId] from the [node.userId], as [User]
                // has no events about its [User.contacts] list changes.
                _userRepo.removeContact(node.contactId, node.userId);
                break;

              case ChatContactEventKind.created:
              case ChatContactEventKind.deleted:
                // No-op as these events are handled elsewhere.
                break;
            }
          }

          for (var e in entities.values) {
            await _contactLocal.put(e);
          }
        }
    }
  }

  /// Fetches and persists a [HiveChatContact] by the provided [id].
  Future<HiveChatContact?> _fetchById(ChatContactId id) async {
    Log.debug('_fetchById($id)', '$runtimeType');

    Mutex? mutex = _getGuards[id];
    if (mutex == null) {
      mutex = Mutex();
      _getGuards[id] = mutex;
    }

    return mutex.protect(() async {
      final HiveChatContact? contact =
          (await _graphQlProvider.chatContact(id)).chatContact?.toHive();
      if (contact != null) {
        _putChatContact(contact);
      }

      return contact;
    });
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
    Log.debug(
      '_chatContacts($first, $after, $last, $before, $noFavorite)',
      '$runtimeType',
    );

    Contacts$Query$ChatContacts query = (await _graphQlProvider.chatContacts(
      first: first,
      after: after,
      last: last,
      before: before,
      noFavorite: noFavorite,
    ));
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
    Log.debug(
      '_favoriteContacts($first, $after, $last, $before)',
      '$runtimeType',
    );

    FavoriteContacts$Query$FavoriteChatContacts query =
        (await _graphQlProvider.favoriteChatContacts(
      first: first,
      after: after,
      last: last,
      before: before,
    ));
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
  ) {
    Log.debug('_chatContactsRemoteEvents(ver)', '$runtimeType');

    return _graphQlProvider.contactsEvents(ver).asyncExpand((event) async* {
      Log.trace(
        '_chatContactsRemoteEvents(ver): ${event.data}',
        '$runtimeType',
      );

      var events =
          ContactsEvents$Subscription.fromJson(event.data!).chatContactsEvents;

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
  }

  /// Constructs a [ChatContactEvent] from the
  /// [ChatContactEventsVersionedMixin$Events].
  ChatContactEvent _contactEvent(ChatContactEventsVersionedMixin$Events e) {
    Log.trace('_contactEvent($e)', '$runtimeType');

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
        node.contactId,
        node.at,
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatContactUserRemoved') {
      var node = e
          as ChatContactEventsVersionedMixin$Events$EventChatContactUserRemoved;

      return EventChatContactUserRemoved(node.contactId, node.at, node.userId);
    } else {
      throw UnimplementedError('Unknown ContactEvent: ${e.$$typename}');
    }
  }

  /// Debounces the [mutation] execution, synchronizing the results with
  /// [EventPool] for the provided [field].
  Future<void> _debounce<T>({
    required ContactField field,
    required T? Function() current,
    required Future<T?> Function() saved,
    required ChatContactId contactId,
    T? value,
    required void Function(T? value) update,
    required Future<ChatContactEventsVersionedMixin?> Function(T? value)
        mutation,
  }) async {
    Log.debug(
      '_debounce($field, current, saved, $contactId, $value, update, mutation)',
      '$runtimeType',
    );

    final EventPool<ContactField> pool = _getPool(contactId);

    update(value);

    await pool.protect(
      field,
      () async {
        try {
          // Lock the [field] before each mutation as [current] and [saved]
          // values may changed.
          pool.lock(field, [current(), await saved()]);

          final ChatContactEventsVersionedMixin? response =
              await mutation(value);

          if (response != null) {
            final event = ChatContactsEventsEvent(
              ChatContactEventsVersioned(
                response.events.map((e) => _contactEvent(e)).toList(),
                response.ver,
                response.listVer,
              ),
            );

            await _contactRemoteEvent(event, updateVersion: false);
          }
        } catch (_) {
          update(await saved());
          rethrow;
        }
      },
      repeat: () async {
        if (current() != await saved()) {
          value = current();
          return true;
        }

        return false;
      },
    );
  }

  /// Returns the [EventPool] for the [ChatContact] with the provided [id].
  EventPool<ContactField> _getPool(ChatContactId id) {
    EventPool<ContactField>? pool = _pools[id];
    if (pool == null) {
      pool = EventPool();
      _pools[id] = pool;
    }

    return pool;
  }
}

/// [ChatContact] fields being updated via [ChatContactsEvents].
///
/// Used to update [ChatContact] according to the [EventPool].
enum ContactField { favoritePosition }
