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

import 'dart:convert';

import 'package:dio/dio.dart' as dio
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
import '/store/model/my_user.dart';
import '/store/model/user.dart';

/// [MyUser] related functionality.
mixin UserGraphQlMixin {
  GraphQlClient get client;

  /// Returns the current authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<GetMyUser$Query> getMyUser() async {
    QueryResult res =
        await client.query(QueryOptions(document: GetMyUserQuery().document));
    return GetMyUser$Query.fromJson(res.data!);
  }

  /// Returns an [User] by its [id].
  ///
  /// ### Authentication
  ///
  /// Optional.
  Future<GetUser$Query> getUser(UserId id) async {
    final variables = GetUserArguments(id: id);
    QueryResult res = await client.query(QueryOptions(
      document: GetUserQuery(variables: variables).document,
      variables: variables.toJson(),
    ));
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
    QueryResult res = await client.query(QueryOptions(
      document: SearchUsersQuery(variables: variables).document,
      variables: variables.toJson(),
    ));
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
  /// - [EventUserNameDeleted] (if [name] argument is absent or is `null`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] uses the provided [name] already.
  Future<MyUserEventsVersionedMixin?> updateUserName(UserName? name) async {
    final variables = UpdateUserNameArguments(name: name);
    QueryResult res = await client.mutate(
      MutationOptions(
        document: UpdateUserNameMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return UpdateUserName$Mutation.fromJson(res.data!).updateUserName;
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
  /// - [EventUserStatusDeleted] (if [text] argument is absent or is `null`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] has the provided [text] as his `status` value already.
  Future<MyUserEventsVersionedMixin?> updateUserStatus(
    UserTextStatus? text,
  ) async {
    final variables = UpdateUserStatusArguments(text: text);
    QueryResult res = await client.mutate(
      MutationOptions(
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
  /// Only the following [MyUserEvent] may be produced on success:
  /// - [EventUserLoginUpdated].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] uses the provided [login] already.
  Future<MyUserEventsVersionedMixin?> updateUserLogin(UserLogin login) async {
    final variables = UpdateUserLoginArguments(login: login);
    QueryResult res = await client.mutate(
      MutationOptions(
        document: UpdateUserLoginMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UpdateUserLoginException((UpdateUserLogin$Mutation
                      .fromJson(data)
                  .updateUserLogin
              as UpdateUserLogin$Mutation$UpdateUserLogin$UpdateUserLoginError)
          .code),
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
      Presence presence) async {
    final variables = UpdateUserPresenceArguments(presence: presence);
    QueryResult res = await client.mutate(
      MutationOptions(
        document: UpdateUserPresenceMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return UpdateUserPresence$Mutation.fromJson(res.data!).updateUserPresence;
  }

  /// Updates password for the authenticated [MyUser].
  ///
  /// If [MyUser] has no password yet (when sets his password), then `old`
  /// password is not required. Otherwise (when changes his password), it's
  /// mandatory to specify the `old` one.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] is always produced on success:
  /// - [EventUserPasswordUpdated].
  ///
  /// ### Non-idempotent
  ///
  /// Each time renews the password (recalculates hash) even if it's the same
  /// one.
  Future<MyUserEventsVersionedMixin?> updateUserPassword(
      UserPassword? oldPassword, UserPassword newPassword) async {
    final variables = UpdateUserPasswordArguments(
      old: oldPassword,
      kw$new: newPassword,
    );
    QueryResult res = await client.mutate(
      MutationOptions(
        document: UpdateUserPasswordMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UpdateUserPasswordException(
          (UpdateUserPassword$Mutation.fromJson(data).updateUserPassword
                  as UpdateUserPassword$Mutation$UpdateUserPassword$UpdateUserPasswordError)
              .code),
    );
    return UpdateUserPassword$Mutation.fromJson(res.data!).updateUserPassword
        as MyUserEventsVersionedMixin?;
  }

  /// Deletes the authenticated [MyUser] completely.
  ///
  /// __This action cannot be reverted.__
  ///
  /// Also deletes all the [Session]s and [RememberedSession]s of the
  /// authenticated [MyUser].
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
  Future<MyUserEventsVersionedMixin> deleteMyUser() async {
    QueryResult res = await client
        .mutate(MutationOptions(document: DeleteMyUserMutation().document));
    return DeleteMyUser$Mutation.fromJson(res.data!).deleteMyUser;
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
  Stream<QueryResult> myUserEvents(MyUserVersion? Function() ver) {
    final variables = MyUserEventsArguments(ver: ver());
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'MyUserEvents',
        document: MyUserEventsSubscription(variables: variables).document,
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
  Stream<QueryResult> userEvents(UserId id, UserVersion? Function() ver) {
    final variables = UserEventsArguments(id: id, ver: ver());
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'UserEvents',
        document: UserEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
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
  /// - [EventUserEmailDeleted].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] doesn't have the provided [email] in his [MyUser.emails] already.
  Future<MyUserEventsVersionedMixin?> deleteUserEmail(UserEmail email) async {
    final variables = DeleteUserEmailArguments(email: email);
    final QueryResult result = await client.mutate(MutationOptions(
      operationName: 'DeleteUserEmail',
      document: DeleteUserEmailMutation(variables: variables).document,
      variables: variables.toJson(),
    ));
    return DeleteUserEmail$Mutation.fromJson(result.data!).deleteUserEmail;
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
  /// - [EventUserPhoneDeleted].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [MyUserEvent]) if the authenticated
  /// [MyUser] doesn't have the provided [phone] in his [MyUser.phones] already.
  Future<MyUserEventsVersionedMixin?> deleteUserPhone(UserPhone phone) async {
    final variables = DeleteUserPhoneArguments(phone: phone);
    final QueryResult result = await client.mutate(MutationOptions(
      operationName: 'DeleteUserPhone',
      document: DeleteUserPhoneMutation(variables: variables).document,
      variables: variables.toJson(),
    ));
    return DeleteUserPhone$Mutation.fromJson(result.data!).deleteUserPhone;
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
    RawClientOptions? raw,
  }) async {
    final variables = AddUserEmailArguments(email: email);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'AddUserEmail',
        document: AddUserEmailMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      raw: raw,
      onException: (data) => AddUserEmailException(
          (AddUserEmail$Mutation.fromJson(data).addUserEmail
                  as AddUserEmail$Mutation$AddUserEmail$AddUserEmailError)
              .code),
    );
    return AddUserEmail$Mutation.fromJson(result.data!).addUserEmail
        as MyUserEventsVersionedMixin?;
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
  Future<MyUserEventsVersionedMixin?> addUserPhone(UserPhone phone) async {
    final variables = AddUserPhoneArguments(phone: phone);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'AddUserPhone',
        document: AddUserPhoneMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => AddUserPhoneException(
          (AddUserPhone$Mutation.fromJson(data).addUserPhone
                  as AddUserPhone$Mutation$AddUserPhone$AddUserPhoneError)
              .code),
    );
    return AddUserPhone$Mutation.fromJson(result.data!).addUserPhone
        as MyUserEventsVersionedMixin?;
  }

  /// Confirms the given unconfirmed email address with the provided
  /// [ConfirmationCode] for the authenticated [MyUser], and moves it to a
  /// [MyUserEmails.confirmed] sub-field unlocking the related capabilities.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] is always produced on success:
  /// - [EventUserEmailConfirmed].
  ///
  /// ### Non-idempotent
  ///
  /// Errors with `WRONG_CODE` if the provided [ConfirmationCode] has been used
  /// already.
  Future<MyUserEventsVersionedMixin?> confirmEmailCode(
    ConfirmationCode code, {
    RawClientOptions? raw,
  }) async {
    final variables = ConfirmUserEmailArguments(code: code);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ConfirmUserEmail',
        document: ConfirmUserEmailMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      raw: raw,
      onException: (data) => ConfirmUserEmailException((ConfirmUserEmail$Mutation
                      .fromJson(data)
                  .confirmUserEmail
              as ConfirmUserEmail$Mutation$ConfirmUserEmail$ConfirmUserEmailError)
          .code),
    );
    return ConfirmUserEmail$Mutation.fromJson(result.data!).confirmUserEmail
        as MyUserEventsVersionedMixin?;
  }

  /// Confirms the given unconfirmed phone number with the provided
  /// [ConfirmationCode] for the authenticated [MyUser], and moves it to a
  /// [MyUserPhones.confirmed] sub-field unlocking the related capabilities.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [MyUserEvent] is always produced on success:
  /// - [EventUserPhoneConfirmed].
  ///
  /// ### Non-idempotent
  ///
  /// Errors with `WRONG_CODE` if the provided [ConfirmationCode] has been used
  /// already.
  Future<MyUserEventsVersionedMixin?> confirmPhoneCode(
      ConfirmationCode code) async {
    final variables = ConfirmUserPhoneArguments(code: code);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ConfirmUserPhone',
        document: ConfirmUserPhoneMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ConfirmUserPhoneException((ConfirmUserPhone$Mutation
                      .fromJson(data)
                  .confirmUserPhone
              as ConfirmUserPhone$Mutation$ConfirmUserPhone$ConfirmUserPhoneError)
          .code),
    );
    return ConfirmUserPhone$Mutation.fromJson(result.data!).confirmUserPhone
        as MyUserEventsVersionedMixin?;
  }

  /// Resends a new [ConfirmationCode] to [MyUserEmails.unconfirmed] address
  /// for the authenticated [MyUser].
  ///
  /// Once [User] successfully uses this [ConfirmationCode] in a
  /// [confirmEmailCode], the given email address moves to a
  /// [MyUserEmails.confirmed] sub-field unlocking the related capabilities.
  ///
  /// The number of generated [ConfirmationCode]s is limited up to 10 per 1
  /// hour.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Always returns `null` on success.
  ///
  /// ### Non-idempotent
  ///
  /// Each time generates a new [ConfirmationCode].
  Future<void> resendEmail({RawClientOptions? raw}) async {
    await client.mutate(
      MutationOptions(
        operationName: 'ResendUserEmailConfirmation',
        document: ResendUserEmailConfirmationMutation().document,
      ),
      raw: raw,
      onException: (data) => ResendUserEmailConfirmationException(
          ResendUserEmailConfirmation$Mutation.fromJson(data)
                  .resendUserEmailConfirmation
              as ResendUserEmailConfirmationErrorCode),
    );
  }

  /// Resends a new [ConfirmationCode] to [MyUserPhones.unconfirmed] number for
  /// the authenticated [MyUser].
  ///
  /// Once [User] successfully uses this [ConfirmationCode] in a
  /// [confirmPhoneCode], the given phone number moves to a
  /// [MyUserPhones.confirmed] sub-field unlocking the related capabilities.
  ///
  /// The number of generated [ConfirmationCode]s is limited up to 10 per 1
  /// hour.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Always returns `null` on success.
  ///
  /// ### Non-idempotent
  ///
  /// Each time generates a new [ConfirmationCode].
  Future<void> resendPhone() async {
    await client.mutate(
      MutationOptions(
        operationName: 'ResendUserPhoneConfirmation',
        document: ResendUserPhoneConfirmationMutation().document,
      ),
      onException: (data) => ResendUserPhoneConfirmationException(
          ResendUserPhoneConfirmation$Mutation.fromJson(data)
                  .resendUserPhoneConfirmation
              as ResendUserPhoneConfirmationErrorCode),
    );
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
      ChatDirectLinkSlug slug) async {
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
              .code),
    );
    return CreateUserDirectLink$Mutation.fromJson(result.data!)
        .createChatDirectLink as MyUserEventsVersionedMixin?;
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
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'DeleteUserDirectLink',
        document: DeleteUserDirectLinkMutation().document,
      ),
      onException: (data) => DeleteChatDirectLinkException(
          DeleteUserDirectLink$Mutation.fromJson(data).deleteChatDirectLink
              as DeleteChatDirectLinkErrorCode),
    );
    return DeleteUserDirectLink$Mutation.fromJson(result.data!)
        .deleteChatDirectLink as MyUserEventsVersionedMixin?;
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
  /// - [EventUserAvatarDeleted] (if image [file] is not provided).
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
        onSendProgress: onSendProgress,
        onException: (data) => UpdateUserAvatarException(
          (UpdateUserAvatar$Mutation.fromJson(data).updateUserAvatar
                  as UpdateUserAvatar$Mutation$UpdateUserAvatar$UpdateUserAvatarError)
              .code,
        ),
      );

      if (response.data['data'] == null) {
        throw GraphQlException(
          [GraphQLError(message: response.data.toString())],
        );
      }

      return (UpdateUserAvatar$Mutation.fromJson(response.data['data'])
          .updateUserAvatar as MyUserEventsVersionedMixin?);
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw const UpdateUserAvatarException(
          UpdateUserAvatarErrorCode.tooBigSize,
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
  /// - [EventUserCallCoverDeleted] (if image [file] is not provided).
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
        onSendProgress: onSendProgress,
        onException: (data) => UpdateUserCallCoverException(
          (UpdateUserCallCover$Mutation.fromJson(data).updateUserCallCover
                  as UpdateUserCallCover$Mutation$UpdateUserCallCover$UpdateUserCallCoverError)
              .code,
        ),
      );

      if (response.data['data'] == null) {
        throw GraphQlException(
          [GraphQLError(message: response.data.toString())],
        );
      }

      return (UpdateUserCallCover$Mutation.fromJson(response.data['data'])
          .updateUserCallCover as MyUserEventsVersionedMixin?);
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw const UpdateUserCallCoverException(
          UpdateUserCallCoverErrorCode.tooBigSize,
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
    final variables = ToggleMyUserMuteArguments(mute: mute);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ToggleMyUserMute',
        document: ToggleMyUserMuteMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ToggleMyUserMuteException(
          ToggleMyUserMute$Mutation.fromJson(data).toggleMyUserMute
              as ToggleMyUserMuteErrorCode),
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
}
