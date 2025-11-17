// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:convert';

import 'package:dio/dio.dart'
    as dio
    show MultipartFile, Options, FormData, DioException;
import 'package:graphql_flutter/graphql_flutter.dart';

import '../base.dart';
import '../exceptions.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/store/event/my_user.dart';
import '/store/model/blocklist.dart';
import '/store/model/my_user.dart';
import '/store/model/session.dart';
import '/store/model/user.dart';
import '/util/log.dart';

/// [MyUser] related functionality.
mixin UserGraphQlMixin {
  GraphQlClient get client;

  AccessTokenSecret? get token;

  /// Returns the current authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<GetMyUser$Query> getMyUser({bool raw = false}) async {
    Log.debug('getMyUser(raw: $raw)', '$runtimeType');

    QueryResult res = await client.query(
      QueryOptions(
        operationName: 'GetMyUser',
        document: GetMyUserQuery().document,
      ),
      raw: raw ? RawClientOptions(AccessTokenSecret('')) : null,
    );
    return GetMyUser$Query.fromJson(res.data!);
  }

  /// Returns an [User] by its [id].
  ///
  /// ### Authentication
  ///
  /// Optional.
  Future<GetUser$Query> getUser(UserId id) async {
    Log.debug('getUser($id)', '$runtimeType');

    final variables = GetUserArguments(id: id);
    QueryResult res = await client.query(
      QueryOptions(
        operationName: 'GetUser',
        document: GetUserQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return GetUser$Query.fromJson(res.data!);
  }

  /// Searches [User]s by the given criteria.
  ///
  /// Exactly one of [num]/[login]/[link]/[name] arguments must be specified
  /// (be non-`null`).
  ///
  /// Searching by [num]/[login]/[link] is exact.
  ///
  /// Searching by [name] is fuzzy.
  ///
  /// ### Authentication
  ///
  /// Optional.
  ///
  /// ### Sorting
  ///
  /// Returned [User]s are sorted depending on the provided arguments:
  ///
  /// - If one of the [num]/[login]/[link] arguments is specified, then an exact
  /// [User] is returned.
  ///
  /// - If the [name] argument is specified, then returned [User]s are sorted
  /// primarily by the `Levenshtein distance` of their [name]s, and secondary by
  /// their IDs (if the `Levenshtein distance` is the same), in descending
  /// order.
  ///
  /// ### Pagination
  ///
  /// It's allowed to specify both [first] and [last] counts at the same time,
  /// provided that [after] and [before] cursors are equal. In such case the
  /// returned page will include the [User] pointed by the cursor and the
  /// requested count of [User]s preceding and following it.
  ///
  /// If it's desired to receive the [User], pointed by the cursor, without
  /// querying in both directions, one can specify [first] or [last] count as 0.
  Future<SearchUsers$Query> searchUsers({
    UserNum? num,
    UserLogin? login,
    ChatDirectLinkSlug? link,
    UserName? name,
    int? first,
    UsersCursor? after,
    int? last,
    UsersCursor? before,
  }) async {
    Log.debug(
      'searchUsers($num, $login, $link, $name, $first, $after, $last, $before)',
      '$runtimeType',
    );

    final variables = SearchUsersArguments(
      num: num,
      login: login,
      directLink: link,
      name: name,
      first: first,
      after: after,
      last: last,
      before: before,
    );
    QueryResult res = await client.query(
      QueryOptions(
        operationName: 'SearchUsers',
        document: SearchUsersQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return SearchUsers$Query.fromJson(res.data!);
  }

  /// Updates [MyUser.name] field for the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [MyUserEvent]s may be produced on success:
  /// - [EventUserNameUpdated] (if [name] argument is specified);
  /// - [EventUserNameRemoved] (if [name] argument is absent or is `null`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] uses the provided [name] already.
  Future<MyUserEventsVersionedMixin?> updateUserName(UserName? name) async {
    Log.debug('updateUserName($name)', '$runtimeType');

    final variables = UpdateUserNameArguments(name: name);
    QueryResult res = await client.mutate(
      MutationOptions(
        operationName: 'UpdateUserName',
        document: UpdateUserNameMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return UpdateUserName$Mutation.fromJson(res.data!).updateUserName;
  }

  /// Updates or resets the [MyUser.bio] field of the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [MyUserEvent]s may be produced on success:
  /// - [EventUserBioUpdated] (if the [bio] argument is specified);
  /// - [EventUserBioRemoved] (if the [bio] argument is absent or is `null`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] uses the provided [bio] already.
  Future<MyUserEventsVersionedMixin?> updateUserBio(UserBio? bio) async {
    Log.debug('updateUserBio($bio)', '$runtimeType');

    final variables = UpdateUserBioArguments(bio: bio);
    QueryResult res = await client.mutate(
      MutationOptions(
        operationName: 'UpdateUserBio',
        document: UpdateUserBioMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return UpdateUserBio$Mutation.fromJson(res.data!).updateUserBio;
  }

  /// Updates or resets the [MyUser.status] field of the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [MyUserEvent]s may be produced on success:
  /// - [EventUserStatusUpdated] (if [text] argument is specified);
  /// - [EventUserStatusRemoved] (if [text] argument is absent or is `null`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] has the provided [text] as his `status` value already.
  Future<MyUserEventsVersionedMixin?> updateUserStatus(
    UserTextStatus? text,
  ) async {
    Log.debug('updateUserStatus($text)', '$runtimeType');

    final variables = UpdateUserStatusArguments(text: text);
    QueryResult res = await client.mutate(
      MutationOptions(
        operationName: 'UpdateUserStatus',
        document: UpdateUserStatusMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return UpdateUserStatus$Mutation.fromJson(res.data!).updateUserStatus;
  }

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [MyUserEvent]s may be produced on success:
  /// - [EventUserLoginUpdated] (if [login] argument is specified);
  /// - [EventUserLoginRemoved] (if [login] argument is absent or is `null`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] uses the provided [login] already.
  Future<MyUserEventsVersionedMixin?> updateUserLogin(UserLogin? login) async {
    Log.debug('updateUserLogin($login)', '$runtimeType');

    final variables = UpdateUserLoginArguments(login: login);
    QueryResult res = await client.mutate(
      MutationOptions(
        operationName: 'UpdateUserLogin',
        document: UpdateUserLoginMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UpdateUserLoginException(
        (UpdateUserLogin$Mutation.fromJson(data).updateUserLogin
                as UpdateUserLogin$Mutation$UpdateUserLogin$UpdateUserLoginError)
            .code,
      ),
    );
    return UpdateUserLogin$Mutation.fromJson(res.data!).updateUserLogin
        as MyUserEventsVersionedMixin?;
  }

  /// Updates [MyUser.presence] to the provided value.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] may be produced on success:
  /// - [EventUserPresenceUpdated].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] has the provided [presence] value already.
  Future<MyUserEventsVersionedMixin?> updateUserPresence(
    Presence presence,
  ) async {
    Log.debug('updateUserPresence($presence)', '$runtimeType');

    final variables = UpdateUserPresenceArguments(presence: presence);
    QueryResult res = await client.mutate(
      MutationOptions(
        operationName: 'UpdateUserPresence',
        document: UpdateUserPresenceMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return UpdateUserPresence$Mutation.fromJson(res.data!).updateUserPresence;
  }

  /// Updates or resets password of the authenticated [MyUser] or the one
  /// identified by the provided [MyUserIdentifier].
  ///
  /// If the [MyUser] has no password yet, then the [confirmation] argument is
  /// not required. Otherwise, it's mandatory to authenticate this operation
  /// additionally by providing the [confirmation] argument.
  ///
  /// This mutation can be used for both changing the [MyUser]'s password and
  /// recovering it. Use the `Mutation.createConfirmationCode` to create a new
  /// [ConfirmationCode] for authenticating the password recovery, and provide
  /// it as the confirmation argument along with the [identifier] argument to
  /// this mutation.
  ///
  /// If the concrete [MyUserIdentifier.email] address or
  /// [MyUserIdentifier.phone] number is provided, then the provided
  /// [ConfirmationCode] is validated against it exclusively, meaning that
  /// providing [ConfirmationCode]s sent to any other [MyUserEmails.confirmed]
  /// or [MyUserPhones.confirmed] is invalid. Otherwise, if a
  /// [MyUserIdentifier.num] or a [MyUserIdentifier.login] is provided, then a
  /// [ConfirmationCode] sent to any of [MyUserEmails.confirmed] or
  /// [MyUserPhones.confirmed] is suitable.
  ///
  /// `User-Agent` HTTP header must be specified for this mutation and meet the
  /// [UserAgent] scalar format.
  ///
  /// ### Authentication
  ///
  /// Mandatory if the [identifier] argument is absent or `null`.
  /// ### Result
  ///
  /// Only the following [MyUserEvent] is always produced on success:
  /// - [EventUserPasswordUpdated].
  ///
  /// ### Non-idempotent
  ///
  /// Each time renews the password (recalculates hash) even if it's the same one.
  ///
  /// Additionally, always uses the provided ConfirmationCode, disallowing to use it again.
  Future<MyUserEventsVersionedMixin?> updateUserPassword({
    MyUserIdentifier? identifier,
    UserPassword? newPassword,
    MyUserCredentials? confirmation,
  }) async {
    Log.debug('updateUserPassword(***, ***)', '$runtimeType');

    final variables = UpdateUserPasswordArguments(
      ident: identifier,
      password: newPassword,
      confirmation: confirmation,
    );
    QueryResult res = await client.mutate(
      MutationOptions(
        operationName: 'UpdateUserPassword',
        document: UpdateUserPasswordMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UpdateUserPasswordException(
        (UpdateUserPassword$Mutation.fromJson(data).updateUserPassword
                as UpdateUserPassword$Mutation$UpdateUserPassword$UpdateUserPasswordError)
            .code,
      ),
      raw: RawClientOptions(token),
    );
    return UpdateUserPassword$Mutation.fromJson(res.data!).updateUserPassword
        as MyUserEventsVersionedMixin?;
  }

  /// Deletes the authenticated [MyUser] completely.
  ///
  /// __This action cannot be reverted.__
  ///
  /// Also deletes all the [Session]s of the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] is always produced on success:
  /// - [EventUserDeleted].
  ///
  /// ### Non-idempotent
  ///
  /// Once deleted [MyUser] cannot be deleted again.
  Future<MyUserEventsVersionedMixin> deleteMyUser({
    MyUserCredentials? confirmation,
  }) async {
    Log.debug('deleteMyUser()', '$runtimeType');

    final variables = DeleteMyUserArguments(confirmation: confirmation);
    final QueryResult res = await client.mutate(
      MutationOptions(
        operationName: 'DeleteMyUser',
        document: DeleteMyUserMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => DeleteMyUserException(
        (DeleteMyUser$Mutation.fromJson(data).deleteMyUser
                as DeleteMyUser$Mutation$DeleteMyUser$DeleteMyUserError)
            .code,
      ),
    );
    return DeleteMyUser$Mutation.fromJson(res.data!).deleteMyUser
        as DeleteMyUser$Mutation$DeleteMyUser$MyUserEventsVersioned;
  }

  /// Subscribes to [MyUserEvent]s of the authenticated [MyUser].
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
  /// authenticated [MyUser] will be emitted after `SubscriptionInitialized` and
  /// before any other [MyUserEvent]s (and won't be emitted ever again until
  /// this subscription completes). This allows to skip calling [getMyUser]
  /// before establishing this subscription.
  ///
  /// If the specified [ver] is not fresh (was queried quite a time ago), it may
  /// become stale, so this subscription will return `STALE_VERSION` error on
  /// initialization. In such case:
  /// - either a fresh version should be obtained via [getMyUser];
  /// - or a re-subscription should be done without specifying a [ver] argument
  /// (so the fresh [ver] may be obtained in the emitted initial state of the
  /// [MyUser]).
  ///
  /// ### Completion
  ///
  /// Finite.
  ///
  /// Completes without re-subscription necessity when:
  /// - The authenticated [MyUser] is deleted (emits [EventUserDeleted] and
  /// completes).
  ///
  /// Completes requiring a re-subscription when:
  /// - Authenticated [Session] expires (`SESSION_EXPIRED` error is emitted).
  /// - An error occurs on the server (error is emitted).
  /// - The server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization).
  ///
  /// ### Idempotency
  ///
  /// This subscription could emit the same [EventUserDeleted] multiple times,
  /// so a client side is expected to handle it idempotently considering the
  /// `MyUser.ver`.
  Future<Stream<QueryResult>> myUserEvents(
    Future<MyUserVersion?> Function() ver,
  ) async {
    Log.debug('myUserEvents(ver)', '$runtimeType');

    final variables = MyUserEventsArguments(ver: await ver());
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'MyUserEvents',
        document: MyUserEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      ver: ver,
    );
  }

  /// Subscribes to [BlocklistEvent]s of the authenticated [MyUser].
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
  /// `Blocklist` will be emitted after `SubscriptionInitialized` and before any
  /// other [BlocklistEvent]s (and won't be emitted ever again until this
  /// subscription completes). This allows to skip calling `Query.blocklist`
  /// before establishing this subscription.
  ///
  /// If the specified [ver] is not fresh (was queried quite a time ago), it may
  /// become stale, so this subscription will return `STALE_VERSION` error on
  /// initialization. In such case:
  /// - either a fresh version should be obtained via `Query.blocklist`;
  /// - or a re-subscription should be done without specifying a [ver] argument
  /// (so the fresh ver may be obtained in the emitted initial state of the
  /// `Blocklist`).
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
  /// which have already been applied to the state of some [BlocklistRecord], so
  /// a client side is expected to handle all the events idempotently
  /// considering the [ver].
  Stream<QueryResult> blocklistEvents(BlocklistVersion? Function() ver) {
    Log.debug('blocklistEvents(ver)', '$runtimeType');

    final variables = BlocklistEventsArguments(ver: ver());
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'BlocklistEvents',
        document: BlocklistEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      ver: ver,
    );
  }

  /// Subscribes to [UserEvent]s of the specified [User].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Initialization
  ///
  /// Once this subscription is initialized completely, it immediately emits
  /// `SubscriptionInitialized`, or immediately completes (without emitting
  /// anything) if such [User] doesn't exist.
  ///
  /// If nothing has been emitted for a long period of time after establishing
  /// this subscription (while not being completed), it should be considered as
  /// an unexpected server error. This fact can be used on a client side to
  /// decide whether this subscription has been initialized successfully.
  ///
  /// ### Result
  ///
  /// If [ver] argument is not specified (or is `null`) an initial state of the
  /// [User] will be emitted after `SubscriptionInitialized` and before any
  /// other [UserEvent]s (and won't be emitted ever again until this
  /// subscription completes). This allows to skip doing [getUser] before
  /// establishing this subscription.
  ///
  /// If the specified [ver] is not fresh (was queried quite a time ago), it may
  /// become stale, so this subscription will return `STALE_VERSION` error on
  /// initialization. In such case:
  /// - either a fresh version should be obtained via [getUser];
  /// - or a re-subscription should be done without specifying a [ver] argument
  /// (so the fresh [ver] may be obtained in the emitted initial state of the
  /// [User]).
  ///
  /// ### Completion
  ///
  /// Finite.
  ///
  /// Completes without re-subscription necessity when:
  /// - The specified [User] is deleted (emits [EventUserDeleted] and
  /// completes).
  /// - The specified [User] doesn't exist (emits nothing, completes immediately
  /// after being established).
  ///
  /// Completes requiring a re-subscription when:
  /// - Authenticated [Session] expires (`SESSION_EXPIRED` error is emitted).
  /// - An error occurs on the server (error is emitted).
  /// - The server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization).
  ///
  /// ### Idempotency
  ///
  /// This subscription could emit the same [EventUserDeleted] multiple times,
  /// so a client side is expected to handle it idempotently considering the
  /// [UserVersion].
  Future<Stream<QueryResult>> userEvents(
    UserId id,
    Future<UserVersion?> Function() ver,
  ) async {
    Log.debug('userEvents($id, ver)', '$runtimeType');

    final variables = UserEventsArguments(id: id, ver: await ver());
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'UserEvents',
        document: UserEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      priority: -10,
      ver: ver,
    );
  }

  /// Deletes the given [email] from [MyUser.emails] of the authenticated
  /// [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] may be produced on success:
  /// - [EventUserEmailRemoved].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] doesn't have the provided [email] in his [MyUser.emails] already.
  Future<MyUserEventsVersionedMixin?> removeUserEmail(
    UserEmail email, {
    MyUserCredentials? confirmation,
  }) async {
    Log.debug(
      'removeUserEmail($email, confirmation: $confirmation)',
      '$runtimeType',
    );

    final variables = RemoveUserEmailArguments(
      email: email,
      confirmation: confirmation,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'RemoveUserEmail',
        document: RemoveUserEmailMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => RemoveUserEmailException(
        (RemoveUserEmail$Mutation.fromJson(data).removeUserEmail
                as RemoveUserEmail$Mutation$RemoveUserEmail$RemoveUserEmailError)
            .code,
      ),
    );
    return RemoveUserEmail$Mutation.fromJson(result.data!).removeUserEmail
        as RemoveUserEmail$Mutation$RemoveUserEmail$MyUserEventsVersioned;
  }

  /// Deletes the given [phone] from [MyUser.phones] for the authenticated
  /// [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] may be produced on success:
  /// - [EventUserPhoneRemoved].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] doesn't have the provided [phone] in his [MyUser.phones] already.
  Future<MyUserEventsVersionedMixin?> removeUserPhone(
    UserPhone phone, {
    MyUserCredentials? confirmation,
  }) async {
    Log.debug(
      'removeUserPhone($phone, confirmation: $confirmation)',
      '$runtimeType',
    );

    throw UnimplementedError();
    // final variables = RemoveUserPhoneArguments(phone: phone);
    // final QueryResult result = await client.mutate(MutationOptions(
    //   operationName: 'RemoveUserPhone',
    //   document: RemoveUserPhoneMutation(variables: variables).document,
    //   variables: variables.toJson(),
    // ));
    // return RemoveUserPhone$Mutation.fromJson(result.data!).removeUserPhone
    //     as RemoveUserPhone$Mutation$RemoveUserPhone$MyUserEventsVersioned;
  }

  /// Adds a new email address for the authenticated [MyUser].
  ///
  /// Sets the given [email] address as an [MyUserEmails.unconfirmed] of a
  /// [MyUser.emails] field and sends to this address an email message with a
  /// [ConfirmationCode].
  ///
  /// Once [User] successfully uses this [ConfirmationCode] in a
  /// `Mutation.confirmUserEmail`, the email address becomes a confirmed one and
  /// moves to [MyUserEmails.confirmed] sub-field unlocking the related
  /// capabilities.
  ///
  /// [MyUser] can have maximum one [MyUserEmails.unconfirmed] address at the
  /// same time.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] may be produced on success:
  /// - [EventUserEmailAdded].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the provided [email]
  /// is already present in a [MyUser.emails] field (either in confirmed or
  /// unconfirmed sub-field).
  Future<MyUserEventsVersionedMixin?> addUserEmail(
    UserEmail email, {
    ConfirmationCode? confirmation,
    RawClientOptions? raw,
    String? locale,
  }) async {
    Log.debug(
      'addUserEmail($email, confirmation: $confirmation, raw: $raw, locale: $locale)',
      '$runtimeType',
    );

    final variables = AddUserEmailArguments(
      email: email,
      confirmation: confirmation,
    );
    final query = MutationOptions(
      operationName: 'AddUserEmail',
      document: AddUserEmailMutation(variables: variables).document,
      variables: variables.toJson(),
    );

    if (confirmation != null) {
      final QueryResult result = await client.mutate(
        query,
        onException: (data) => AddUserEmailException(
          (AddUserEmail$Mutation.fromJson(data).addUserEmail
                  as AddUserEmail$Mutation$AddUserEmail$AddUserEmailError)
              .code,
        ),
      );

      return (AddUserEmail$Mutation.fromJson(result.data!).addUserEmail
          as MyUserEventsVersionedMixin?);
    }

    final request = query.asRequest;
    final body = const RequestSerializer().serializeRequest(request);
    final encodedBody = json.encode(body);

    final response = await client.post(
      dio.FormData.fromMap({
        'operations': encodedBody,
        'map': '{ "token": ["variables.token"] }',
        'token': raw?.token ?? token,
      }),
      options: dio.Options(
        headers: {if (locale != null) 'Accept-Language': locale},
      ),
      operationName: query.operationName,
      onException: (data) => AddUserEmailException(
        (AddUserEmail$Mutation.fromJson(data).addUserEmail
                as AddUserEmail$Mutation$AddUserEmail$AddUserEmailError)
            .code,
      ),
    );

    if (response.data['data'] == null) {
      throw GraphQlException([GraphQLError(message: response.data.toString())]);
    }

    return (AddUserEmail$Mutation.fromJson(response.data['data']).addUserEmail
        as MyUserEventsVersionedMixin?);
  }

  /// Adds a new phone number for the authenticated [MyUser].
  ///
  /// Sets the given [phone] number as an unconfirmed sub-field of a
  /// [MyUser.phones] field and sends to this number SMS with a
  /// [ConfirmationCode].
  ///
  /// Once [MyUser] successfully uses this [ConfirmationCode] in a
  /// `Mutation.confirmUserPhone`, the phone number becomes a confirmed one and
  /// moves to [MyUserPhones.confirmed] sub-field unlocking the related
  /// capabilities.
  ///
  /// [MyUser] can have maximum one [MyUserPhones.unconfirmed] number at the
  /// same time.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] may be produced on success:
  /// - [EventUserPhoneAdded].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the provided [phone]
  /// already is present in a [MyUser.phones] field (either in confirmed or
  /// unconfirmed sub-field).
  Future<MyUserEventsVersionedMixin?> addUserPhone(
    UserPhone phone, {
    ConfirmationCode? confirmation,
    String? locale,
  }) async {
    throw UnimplementedError();

    // Log.debug(
    //   'addUserPhone($phone, confirmation: $confirmation)',
    //   '$runtimeType',
    // );

    // final variables =
    //     AddUserPhoneArguments(phone: phone, confirmation: confirmation);
    // final QueryResult result = await client.mutate(
    //   MutationOptions(
    //     operationName: 'AddUserPhone',
    //     document: AddUserPhoneMutation(variables: variables).document,
    //     variables: variables.toJson(),
    //   ),
    //   onException: (data) => AddUserPhoneException(
    //       (AddUserPhone$Mutation.fromJson(data).addUserPhone
    //               as AddUserPhone$Mutation$AddUserPhone$AddUserPhoneError)
    //           .code),
    // );
    // return AddUserPhone$Mutation.fromJson(result.data!).addUserPhone
    //     as MyUserEventsVersionedMixin?;
  }

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the authenticated [MyUser]
  /// (if any).
  ///
  /// Deleted [ChatDirectLink]s can be re-created again by the original owner
  /// only ([MyUser]) and cannot leak to somebody else.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] may be produced on success:
  /// - [EventUserDirectLinkUpdated].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] has an active [ChatDirectLink] with such [ChatDirectLinkSlug]
  /// already.
  Future<MyUserEventsVersionedMixin?> createUserDirectLink(
    ChatDirectLinkSlug slug,
  ) async {
    Log.debug('createUserDirectLink($slug)', '$runtimeType');

    final variables = CreateUserDirectLinkArguments(slug: slug);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'CreateUserDirectLink',
        document: CreateUserDirectLinkMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => CreateChatDirectLinkException(
        (CreateUserDirectLink$Mutation.fromJson(data).createChatDirectLink
                as CreateUserDirectLink$Mutation$CreateChatDirectLink$CreateChatDirectLinkError)
            .code,
      ),
    );
    return CreateUserDirectLink$Mutation.fromJson(
          result.data!,
        ).createChatDirectLink
        as MyUserEventsVersionedMixin?;
  }

  /// Deletes the current [ChatDirectLink] of the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] may be produced on success:
  /// - [EventUserDirectLinkDeleted].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] has no active [ChatDirectLink]s already.
  Future<MyUserEventsVersionedMixin?> deleteUserDirectLink() async {
    Log.debug('deleteUserDirectLink()', '$runtimeType');

    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'DeleteUserDirectLink',
        document: DeleteUserDirectLinkMutation().document,
      ),
      onException: (data) => DeleteChatDirectLinkException(
        DeleteUserDirectLink$Mutation.fromJson(data).deleteChatDirectLink
            as DeleteChatDirectLinkErrorCode,
      ),
    );
    return DeleteUserDirectLink$Mutation.fromJson(
          result.data!,
        ).deleteChatDirectLink
        as MyUserEventsVersionedMixin?;
  }

  /// Updates or resets the [MyUser.avatar] field with the provided image
  /// [file].
  ///
  /// HTTP request for this mutation must be `Content-Type: multipart/form-data`
  /// containing the uploaded file and the file argument itself must be `null`,
  /// otherwise this mutation will fail.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [MyUserEvent]s may be produced on success:
  /// - [EventUserAvatarUpdated] (if image [file] is provided);
  /// - [EventUserAvatarRemoved] (if image [file] is not provided).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] uses the specified image [file] already as his avatar with the
  /// same crop area.
  Future<MyUserEventsVersionedMixin?> updateUserAvatar(
    dio.MultipartFile? file,
    CropAreaInput? crop, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug('updateUserAvatar($file, $crop, onSendProgress)', '$runtimeType');

    final variables = UpdateUserAvatarArguments(file: null, crop: crop);
    final query = MutationOptions(
      operationName: 'UpdateUserAvatar',
      document: UpdateUserAvatarMutation(variables: variables).document,
      variables: variables.toJson(),
    );

    final request = query.asRequest;
    final body = const RequestSerializer().serializeRequest(request);
    final encodedBody = json.encode(body);

    try {
      final response = await client.post(
        file == null
            ? encodedBody
            : dio.FormData.fromMap({
                'operations': encodedBody,
                'map': '{ "file": ["variables.upload"] }',
                'file': file,
              }),
        options: file == null
            ? null
            : dio.Options(contentType: 'multipart/form-data'),
        operationName: query.operationName,
        onSendProgress: onSendProgress,
        onException: (data) => UpdateUserAvatarException(
          (UpdateUserAvatar$Mutation.fromJson(data).updateUserAvatar
                  as UpdateUserAvatar$Mutation$UpdateUserAvatar$UpdateUserAvatarError)
              .code,
        ),
      );

      if (response.data['data'] == null) {
        throw GraphQlException([
          GraphQLError(message: response.data.toString()),
        ]);
      }

      return (UpdateUserAvatar$Mutation.fromJson(
            response.data['data'],
          ).updateUserAvatar
          as MyUserEventsVersionedMixin?);
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw const UpdateUserAvatarException(
          UpdateUserAvatarErrorCode.invalidSize,
        );
      }

      rethrow;
    }
  }

  /// Updates or resets the [MyUser.callCover] field with the provided image
  /// [file].
  ///
  /// HTTP request for this mutation must be `Content-Type: multipart/form-data`
  /// containing the uploaded file and the file argument itself must be `null`,
  /// otherwise this mutation will fail.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [MyUserEvent]s may be produced on success:
  /// - [EventUserCallCoverUpdated] (if image [file] is provided);
  /// - [EventUserCallCoverRemoved] (if image [file] is not provided).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] uses the specified image [file] already as his callCover with the
  /// same crop area.
  Future<MyUserEventsVersionedMixin?> updateUserCallCover(
    dio.MultipartFile? file,
    CropAreaInput? crop, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug(
      'updateUserCallCover($file, $crop, onSendProgress)',
      '$runtimeType',
    );

    final variables = UpdateUserCallCoverArguments(file: null, crop: crop);
    final query = MutationOptions(
      operationName: 'UpdateUserCallCover',
      document: UpdateUserCallCoverMutation(variables: variables).document,
      variables: variables.toJson(),
    );

    final request = query.asRequest;
    final body = const RequestSerializer().serializeRequest(request);
    final encodedBody = json.encode(body);

    try {
      var response = await client.post(
        file == null
            ? encodedBody
            : dio.FormData.fromMap({
                'operations': encodedBody,
                'map': '{ "file": ["variables.upload"] }',
                'file': file,
              }),
        options: file == null
            ? null
            : dio.Options(contentType: 'multipart/form-data'),
        operationName: query.operationName,
        onSendProgress: onSendProgress,
        onException: (data) => UpdateUserCallCoverException(
          (UpdateUserCallCover$Mutation.fromJson(data).updateUserCallCover
                  as UpdateUserCallCover$Mutation$UpdateUserCallCover$UpdateUserCallCoverError)
              .code,
        ),
      );

      if (response.data['data'] == null) {
        throw GraphQlException([
          GraphQLError(message: response.data.toString()),
        ]);
      }

      return (UpdateUserCallCover$Mutation.fromJson(
            response.data['data'],
          ).updateUserCallCover
          as MyUserEventsVersionedMixin?);
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw const UpdateUserCallCoverException(
          UpdateUserCallCoverErrorCode.invalidSize,
        );
      }

      rethrow;
    }
  }

  /// Mutes or unmutes all the [Chat]s of the authenticated [MyUser]. Overrides
  /// any already existing mute even if it's longer.
  ///
  /// Muted [MyUser] implies that all his [Chat]s events don't produce sounds
  /// and notifications on a client side. This, however, has nothing to do with
  /// a server and is the responsibility to be satisfied by a client side.
  ///
  /// Note, that `Mutation.toggleMyUserMute` doesn't correlate with
  /// `Mutation.toggleChatMute`. Unmuted [Chat] of muted [MyUser] should not
  /// produce any sounds, and so, muted [Chat] of unmuted [MyUser] should not
  /// produce any sounds too.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [MyUserEvent]s may be produced on success:
  /// - [EventUserMuted] (if [mute] argument is not `null`);
  /// - [EventUserUnmuted] (if [mute] argument is `null`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] is muted already `until` the specified [DateTime] (or unmuted).
  Future<MyUserEventsVersionedMixin?> toggleMyUserMute(Muting? mute) async {
    Log.debug('toggleMyUserMute($mute)', '$runtimeType');

    final variables = ToggleMyUserMuteArguments(mute: mute);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ToggleMyUserMute',
        document: ToggleMyUserMuteMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ToggleMyUserMuteException(
        ToggleMyUserMute$Mutation.fromJson(data).toggleMyUserMute
            as ToggleMyUserMuteErrorCode,
      ),
    );
    return (ToggleMyUserMute$Mutation.fromJson(result.data!).toggleMyUserMute
        as MyUserEventsVersionedMixin?);
  }

  /// Keeps the authenticated [MyUser] online while subscribed.
  ///
  /// Keep this subscription up while the authenticated [MyUser] should be
  /// considered as online. Once this subscription begins [User.online] of
  /// [MyUser] becomes `UserOnline`, and once ends sets it to `UserOffline`.
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
  /// ### Completion
  ///
  /// Infinite.
  ///
  /// Completes requiring a re-subscription when:
  /// - Authenticated [Session] expires (`SESSION_EXPIRED` error is emitted).
  /// - An error occurs on the server (error is emitted).
  /// - The server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization).
  Stream<QueryResult> keepOnline() {
    Log.debug('keepOnline()', '$runtimeType');

    return client.subscribe(
      SubscriptionOptions(
        operationName: 'KeepOnline',
        document: KeepOnlineSubscription().document,
      ),
    );
  }

  /// Blocks the specified [User] for the authenticated [MyUser].
  ///
  /// Blocked [User]s are not able to communicate with the authenticated
  /// [MyUser] directly (in [Chat]-dialogs) and add him to [Chat]-groups.
  ///
  /// [MyUser]'s blocklist can be obtained via [getBlocklist].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following BlocklistEvent may be produced on success:
  /// - [EventBlocklistRecordAdded].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [BlocklistEvent]) if the specified
  /// [User] is blocked by the authenticated [MyUser] already with the same
  /// [BlocklistReason].
  Future<BlocklistEventsVersionedMixin?> blockUser(
    UserId id,
    BlocklistReason? reason,
  ) async {
    Log.debug('blockUser($id, $reason)', '$runtimeType');

    final variables = BlockUserArguments(id: id, reason: reason);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'BlockUser',
        document: BlockUserMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => BlockUserException(
        BlockUser$Mutation.fromJson(data).blockUser as BlockUserErrorCode,
      ),
    );
    return BlockUser$Mutation.fromJson(result.data!).blockUser
        as BlocklistEventsVersionedMixin?;
  }

  /// Removes the specified [User] from the blocklist of the authenticated
  /// [MyUser].
  ///
  /// Reverses the action of [blockUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [BlocklistEvent] may be produced on success:
  /// - [EventBlocklistRecordRemoved].
  ///
  /// Idempotent
  ///
  /// Succeeds as no-op (and returns no [BlocklistEvent]) if the specified
  /// [User] is not blocked by the authenticated [MyUser] already.
  Future<BlocklistEventsVersionedMixin?> unblockUser(UserId id) async {
    Log.debug('unblockUser($id)', '$runtimeType');

    final variables = UnblockUserArguments(id: id);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'UnblockUser',
        document: UnblockUserMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UnblockUserException(
        UnblockUser$Mutation.fromJson(data).unblockUser as UnblockUserErrorCode,
      ),
    );
    return UnblockUser$Mutation.fromJson(result.data!).unblockUser
        as BlocklistEventsVersionedMixin?;
  }

  /// Returns [User]s blocked by this [MyUser] as [BlocklistRecord]s.
  ///
  /// ### Sorting
  ///
  /// Returned [User]s are sorted primarily by their blocking [DateTime], and
  /// secondary by their IDs (if the blocking [DateTime] is the same), in
  /// descending order.
  ///
  /// ### Pagination
  ///
  /// It's allowed to specify both [first] and [last] counts at the same time,
  /// provided that [after] and [before] cursors are equal. In such case the
  /// returned page will include the [BlocklistRecord] pointed by the cursor and
  /// the requested count of [BlocklistRecord]s preceding and following it.
  ///
  /// If it's desired to receive the [BlocklistRecord], pointed by the cursor,
  /// without querying in both directions, one can specify [first] or [last]
  /// count as 0.
  Future<GetBlocklist$Query$Blocklist> getBlocklist({
    int? first,
    BlocklistCursor? after,
    int? last,
    BlocklistCursor? before,
  }) async {
    Log.debug('getBlocklist($first, $after, $last, $before)', '$runtimeType');

    final variables = GetBlocklistArguments(
      first: first,
      after: after,
      last: last,
      before: before,
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'GetBlocklist',
        document: GetBlocklistQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return GetBlocklist$Query.fromJson(result.data!).blocklist;
  }

  /// Registers a device (Android, iOS, or Web) for receiving notifications via
  /// Firebase Cloud Messaging.
  ///
  /// ### Localization
  ///
  /// You may provide the device's preferred locale via the `Accept-Language`
  /// HTTP header, which will localize notifications to that device using the
  /// best match of the supported locales.
  ///
  /// In order to change the locale of the device, you should re-register it
  /// supplying the desired locale (use [unregisterPushDevice], and then
  /// [registerPushDevice] once again).
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Always returns `null` on success.
  ///
  /// ### Idempotent
  ///
  /// Succeeds if the specified [token] is registered already.
  Future<void> registerPushDevice(PushDeviceToken token, String? locale) async {
    Log.debug('registerPushDevice($token, $locale)', '$runtimeType');

    final variables = RegisterPushDeviceArguments(token: token);
    final query = MutationOptions(
      operationName: 'RegisterPushDevice',
      document: RegisterPushDeviceMutation(variables: variables).document,
      variables: variables.toJson(),
    );

    final request = query.asRequest;
    final body = const RequestSerializer().serializeRequest(request);
    final encodedBody = json.encode(body);

    await client.post(
      dio.FormData.fromMap({
        'operations': encodedBody,
        'map': '{ "token": ["variables.token"] }',
        'token': token,
      }),
      options: dio.Options(
        headers: {if (locale != null) 'Accept-Language': locale},
      ),
      operationName: query.operationName,
      onException: (data) => RegisterPushDeviceException(
        data['registerPushDevice'] == null
            ? null
            : RegisterPushDevice$Mutation.fromJson(data).registerPushDevice
                  as RegisterPushDeviceErrorCode,
      ),
    );
  }

  /// Unregisters a device (Android, iOS, or Web) from receiving notifications
  /// via Firebase Cloud Messaging.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Always returns `true` on success.
  ///
  /// ### Idempotent
  ///
  /// Succeeds if the specified [token] is not registered already.
  Future<void> unregisterPushDevice(PushDeviceToken token) async {
    Log.debug('unregisterPushDevice($token)', '$runtimeType');

    final variables = UnregisterPushDeviceArguments(token: token);
    await client.mutate(
      MutationOptions(
        operationName: 'UnregisterPushDevice',
        document: UnregisterPushDeviceMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
  }

  /// Returns all active [Session]s of the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Sorting
  ///
  /// Returned [Session]s are sorted primarily by their last activity
  /// [DateTime], and secondary by their IDs (if the last activity [DateTime] is
  /// the same), in descending order.
  Future<List<SessionMixin>> sessions() async {
    Log.debug('sessions()', '$runtimeType');

    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'Sessions',
        document: SessionsQuery().document,
      ),
    );
    return Sessions$Query.fromJson(result.data!).sessions.list;
  }

  /// Subscribes to [SessionEvent]s of all [Session]s of the authenticated
  /// [MyUser].
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
  /// [Session]s list will be emitted after `SubscriptionInitialized` and before
  /// any other [SessionEvent]s (and won't be emitted ever again until this
  /// subscription completes). This allows to skip doing [sessions] before
  /// establishing this subscription.
  ///
  /// If the specified ver is not fresh (was queried quite a time ago), it may
  /// become stale, so this subscription will return `STALE_VERSION` error on
  /// initialization. In such case:
  /// - either a fresh version should be obtained via [sessions];
  /// - or a re-subscription should be done without specifying a [ver] argument
  /// (so the fresh [ver] may be obtained in the emitted initial state of the
  /// [Session]s list).
  ///
  /// ### Completion
  ///
  /// Infinite.
  ///
  /// Completes requiring a re-subscription when:
  /// - authenticated [Session] expires (`SESSION_EXPIRED` error is emitted).
  /// - an error occurs on the server (error is emitted).
  /// - the server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization).
  ///
  /// ### Idempotency
  ///
  /// It's possible that in rare scenarios this subscription could emit an event
  /// which have already been applied to the state of some Session, so a client
  /// side is expected to handle all the events idempotently considering the
  /// [ver].
  Stream<QueryResult> sessionsEvents(SessionsListVersion? Function() ver) {
    Log.debug('sessionsEvents(ver)', '$runtimeType');

    final variables = SessionsEventsArguments(ver: ver());
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'SessionsEvents',
        document: SessionsEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      ver: ver,
    );
  }

  /// Updates the [WelcomeMessage] of the authenticated [MyUser].
  ///
  /// For the [WelcomeMessage] to be meaningful, at least one of the
  /// [WelcomeMessageInput.text] or [WelcomeMessageInput.attachments] arguments
  /// must be specified and non-empty.
  ///
  /// To attach some [Attachment]s to the [WelcomeMessage], first, they should
  /// be uploaded with `Mutation.uploadAttachment`, and only then, the returned
  /// [Attachment.id]s may be used as the [WelcomeMessageInput.attachments]
  /// argument of this mutation.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [MyUserEvent]s may be produced on success:
  /// - [EventUserWelcomeMessageUpdated] (if [content] argument is specified);
  /// - [EventUserWelcomeMessageDeleted] (if [content] argument is absent or
  /// `null`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser]'s [WelcomeMessage] already has the specified
  /// [WelcomeMessageInput.text] and [WelcomeMessageInput.attachments] in the
  /// same order.
  Future<MyUserEventsVersionedMixin?> updateWelcomeMessage(
    WelcomeMessageInput? content,
  ) async {
    Log.debug('updateWelcomeMessage($content)', '$runtimeType');

    final variables = UpdateWelcomeMessageArguments(content: content);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'UpdateWelcomeMessage',
        document: UpdateWelcomeMessageMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UpdateWelcomeMessageException(
        (UpdateWelcomeMessage$Mutation.fromJson(data).updateWelcomeMessage
                as UpdateWelcomeMessage$Mutation$UpdateWelcomeMessage$UpdateWelcomeMessageError)
            .code,
      ),
    );
    return DeleteUserDirectLink$Mutation.fromJson(
          result.data!,
        ).deleteChatDirectLink
        as MyUserEventsVersionedMixin?;
  }
}
