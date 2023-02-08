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

import 'package:graphql_flutter/graphql_flutter.dart';

import '../base.dart';
import '../exceptions.dart';
import '/api/backend/schema.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/store/model/contact.dart';

/// [ChatContact]s related functionality.
abstract class ContactGraphQlMixin {
  GraphQlClient get client;

  /// Returns address book of the authenticated [MyUser] ordered alphabetically
  /// by [ChatContact] names.
  ///
  /// Use the [noFavorite] argument to exclude favorite [ChatContact]s from the
  /// returned result.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Pagination
  ///
  /// It's allowed to specify both [first] and [last] at the same time, provided
  /// that [after] and [before] cursors are equal. In such case the returned
  /// page will include the [ChatContact] pointed by the cursor and the
  /// requested count of [ChatContact]s preceding and following it.
  ///
  /// If it's desired to receive the [ChatContact] pointed by the cursor without
  /// querying in both directions, one can specify [first] or [last] count as
  /// `0`.
  Future<Contacts$Query$ChatContacts> chatContacts({
    int? first,
    ChatContactsCursor? after,
    int? last,
    ChatContactsCursor? before,
    bool noFavorite = false,
  }) async {
    final variables = ContactsArguments(
      first: first,
      last: last,
      before: before,
      after: after,
      noFavorite: noFavorite,
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'Contacts',
        document: ContactsQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return Contacts$Query.fromJson(result.data!).chatContacts;
  }

  /// Creates a new [ChatContact] in the authenticated [MyUser]'s address book.
  ///
  /// Initially, a new [ChatContact] can be created with no more than 20
  /// `ChatContactRecord`s. Use `Mutation.createChatContactRecords` to add more,
  /// if you need so.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// The following [ChatContactEvent]s may be produced on success:
  /// - [EventChatContactCreated];
  /// - [EventChatContactEmailAdded];
  /// - [EventChatContactGroupAdded];
  /// - [EventChatContactPhoneAdded];
  /// - [EventChatContactUserAdded].
  ///
  /// ### Non-idempotent
  ///
  /// Each time creates a new unique [ChatContact].
  Future<ChatContactEventsVersionedMixin> createChatContact({
    required UserName name,
    List<ChatContactRecord>? records,
  }) async {
    final variables = CreateChatContactArguments(name: name, records: records);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'CreateChatContact',
        document: CreateChatContactMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => CreateChatContactException((CreateChatContact$Mutation
                      .fromJson(data)
                  .createChatContact
              as CreateChatContact$Mutation$CreateChatContact$CreateChatContactError)
          .code),
    );
    return CreateChatContact$Mutation.fromJson(result.data!).createChatContact
        as ChatContactEventsVersionedMixin;
  }

  /// Deletes the specified [ChatContact] from the authenticated [MyUser]'s
  /// address book.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatContactEvent] may be produced on success:
  /// - [EventChatContactDeleted].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatContactEvent]) if the specified
  /// [ChatContact] doesn't exist already.
  Future<DeleteChatContact$Mutation> deleteChatContact(ChatContactId id) async {
    final variables = DeleteChatContactArguments(id: id);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'DeleteChatContact',
        document: DeleteChatContactMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return DeleteChatContact$Mutation.fromJson(result.data!);
  }

  /// Subscribes to [ChatContactEvent]s of all [ChatContact]s of the
  /// authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Initialization
  ///
  /// Once this subscription is initialized completely, it immediately emits
  /// `SubscriptionInitialized`.
  ///
  /// If nothing has been emitted for a long period of time after establishing
  /// this subscription (while not being completed), it should be considered as
  /// an unexpected server error. This fact can be used on a client side to
  /// decide whether this subscription has been initialized successfully.
  ///
  /// ### Result
  ///
  /// If [ver] argument is not specified (or is `null`) an initial state of the
  /// [ChatContact]s list will be emitted after `SubscriptionInitialized` and
  /// before any other [ChatContactEvent]s (and won't be emitted ever again
  /// until this subscription completes). This allows to skip doing
  /// [chatContacts] (or `Query.favoriteChatContacts`) before establishing this
  /// subscription.
  ///
  /// If the specified [ver] is not fresh (was queried quite a time ago), it may
  /// become stale, so this subscription will return `STALE_VERSION` error on
  /// initialization. In such case:
  /// - either a fresh version should be obtained via [chatContacts] (or
  /// `Query.favoriteChatContacts`);
  /// - or a re-subscription should be done without specifying a [ver] argument
  /// (so the fresh [ver] may be obtained in the emitted initial state of the
  /// [ChatContact]s list).
  ///
  /// ### Completion
  ///
  /// Infinite.
  ///
  /// Completes requiring a re-subscription when:
  /// - Authenticated [Session] expires (`SESSION_EXPIRED` error is emitted).
  /// - An error occurs on the server (error is emitted).
  /// - The server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization).
  ///
  /// ### Idempotency
  ///
  /// It's possible that in rare scenarios this subscription could emit an event
  /// which have already been applied to the state of some [ChatContact], so a
  /// client side is expected to handle all the events idempotently considering
  /// the `ChatContact.ver`.
  Stream<QueryResult> contactsEvents(ChatContactsListVersion? Function() ver) {
    final variables = ContactsEventsArguments(ver: ver());
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'ContactsEvents',
        document: ContactsEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      ver: ver,
    );
  }

  /// Updates the `name` of the specified [ChatContact] in the authenticated
  /// [MyUser]'s address book.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatContactEvent] may be produced on success:
  /// - [EventChatContactNameUpdated].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatContactEvent]) if the specified
  /// [ChatContact] has such name already.
  Future<ChatContactEventsVersionedMixin> changeContactName(
      ChatContactId id, UserName name) async {
    final variables = UpdateChatContactNameArguments(id: id, name: name);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'UpdateChatContactName',
        document: UpdateChatContactNameMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UpdateChatContactNameException(
          (UpdateChatContactName$Mutation.fromJson(data).updateChatContactName
                  as UpdateChatContactName$Mutation$UpdateChatContactName$UpdateChatContactNameError)
              .code),
    );
    return UpdateChatContactName$Mutation.fromJson(result.data!)
        .updateChatContactName as ChatContactEventsVersionedMixin;
  }

  /// Marks the specified [ChatContact] as favorited for the authenticated
  /// [MyUser] and sets its position in the favorites list.
  ///
  /// To move the [ChatContact] to a concrete position in a favorites list,
  /// provide the average value of two other [ChatContact]s positions
  /// surrounding it.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatContactEvent] may be produced on success:
  /// - [EventChatContactFavorited].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatContactEvent]) if the specified
  /// [ChatContact] is already favorited at the same position.
  Future<ChatContactEventsVersionedMixin?> favoriteChatContact(
    ChatContactId id,
    ChatContactPosition position,
  ) async {
    final variables = FavoriteChatContactArguments(id: id, pos: position);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'FavoriteChatContact',
        document: FavoriteChatContactMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => FavoriteChatContactException(
          (FavoriteChatContact$Mutation.fromJson(data).favoriteChatContact
                  as FavoriteChatContact$Mutation$FavoriteChatContact$FavoriteChatContactError)
              .code),
    );
    return FavoriteChatContact$Mutation.fromJson(result.data!)
        .favoriteChatContact as ChatContactEventsVersionedMixin?;
  }

  /// Removes the specified [ChatContact] from the favorites list of the
  /// authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatContactEvent] may be produced on success:
  /// - [EventChatContactUnfavorited].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatContactEvent]) if the specified
  /// [ChatContact] is not in the favorites list already.
  Future<ChatContactEventsVersionedMixin?> unfavoriteChatContact(
    ChatContactId id,
  ) async {
    final variables = UnfavoriteChatContactArguments(id: id);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'UnfavoriteChatContact',
        document: UnfavoriteChatContactMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UnfavoriteChatContactException(
          (UnfavoriteChatContact$Mutation.fromJson(data).unfavoriteChatContact
                  as UnfavoriteChatContact$Mutation$UnfavoriteChatContact$UnfavoriteChatContactError)
              .code),
    );
    return UnfavoriteChatContact$Mutation.fromJson(result.data!)
        .unfavoriteChatContact as ChatContactEventsVersionedMixin?;
  }
}
