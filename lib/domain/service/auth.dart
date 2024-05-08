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
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show visibleForTesting;
import 'package:get/get.dart';

import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/fcm_registration_token.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/auth.dart';
import '/provider/gql/exceptions.dart';
import '/provider/hive/account.dart';
import '/provider/hive/credentials.dart';
import '/routes.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// Authentication service exposing [credentials] of the authenticated session.
///
/// It contains all the required methods to do the authentication process and
/// exposes [credentials] (a session and an user) of the authorized session.
class AuthService extends GetxService {
  AuthService(
    this._authRepository,
    this._credentialsProvider,
    this._accountProvider,
  );

  /// Currently authorized session's [Credentials].
  final Rx<Credentials?> credentials = Rx(null);

  /// Authorization status.
  ///
  /// Can be:
  /// - `status.isEmpty` meaning that `MyUser` is unauthorized;
  /// - `status.isLoading` meaning that authorization data is being fetched
  ///   from storage;
  /// - `status.isLoadingMore` meaning that `MyUser` is authorized according to
  ///   the storage, but network request to the server is still in-flight;
  /// - `status.isSuccess` meaning successful authorization.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.loading());

  /// [CredentialsHiveProvider] used to store user [Session].
  final CredentialsHiveProvider _credentialsProvider;

  /// [AccountHiveProvider] storing the current user's [UserId].
  final AccountHiveProvider _accountProvider;

  /// Authorization repository containing required authentication methods.
  final AbstractAuthRepository _authRepository;

  /// [Timer] used to periodically check the [Session.expireAt] and refresh it
  /// if necessary.
  Timer? _refreshTimer;

  /// [_refreshTimer] interval.
  final Duration _refreshTaskInterval = const Duration(seconds: 30);

  /// Minimal allowed [credentials] TTL.
  final Duration _accessTokenMinTtl = const Duration(minutes: 2);

  /// [StreamSubscription] to [CredentialsHiveProvider.boxEvents] saving new
  /// [Credentials] to the browser's storage.
  StreamSubscription? _credentialsSubscription;

  /// [StreamSubscription] to [AccountHiveProvider.boxEvents] saving new
  /// [Credentials] to the browser's storage.
  StreamSubscription? _accountSubscription;

  /// [StreamSubscription] to [WebUtils.onStorageChange] fetching new
  /// [Credentials].
  StreamSubscription? _storageSubscription;

  /// Returns the currently authorized [Credentials.userId].
  UserId? get userId => credentials.value?.userId;

  /// Indicates whether the [credentials] require a refresh.
  bool get _shouldRefresh =>
      credentials.value?.access.expireAt
          .subtract(_accessTokenMinTtl)
          .isBefore(PreciseDateTime.now().toUtc()) ==
      true;

  /// Indicates whether this [AuthService] is considered authorized.
  bool get _hasAuthorization => credentials.value != null;

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _storageSubscription?.cancel();
    _credentialsSubscription?.cancel();
    _accountSubscription?.cancel();
    _refreshTimer?.cancel();
  }

  /// Initializes this service.
  ///
  /// Tries to load user data from the storage and navigates to the
  /// [Routes.auth] page if this operation fails. Otherwise, fetches user data
  /// from the server to be up-to-date with it.
  String? init() {
    Log.debug('init()', '$runtimeType');

    // Try to refresh session, otherwise just force logout.
    _authRepository.authExceptionHandler = (e) async {
      if (credentials.value?.refresh.expireAt
              .isAfter(PreciseDateTime.now().toUtc()) ==
          true) {
        await refreshSession();
      } else {
        _unauthorized();
        router.auth();
        throw e;
      }
    };

    final UserId? userId = _accountProvider.userId;
    Credentials? creds =
        userId != null ? _credentialsProvider.get(userId) : null;
    AccessToken? access = creds?.access;
    RefreshToken? refresh = creds?.refresh;

    // Listen to the [Credentials] changes.
    _storageSubscription = WebUtils.onStorageChange.listen((e) {
      Log.debug(
        '_storageSubscription(${e.key}): received new credentials',
        '$runtimeType',
      );

      if (e.key == 'credentials') {
        if (e.newValue != null) {
          final Credentials creds =
              Credentials.fromJson(json.decode(e.newValue!));
          final bool authorized = _hasAuthorization;

          if (creds.access.secret != credentials.value?.access.secret &&
              (creds.userId == credentials.value?.userId || !authorized)) {
            _authRepository.token = creds.access.secret;
            _authRepository.applyToken();
            credentials.value = creds;
            status.value = RxStatus.success();

            if (!authorized) {
              router.home();
            }
          }
        } else {
          if (!WebUtils.isPopup) {
            router.go(_unauthorized());
          }
        }
      }
    });

    WebUtils.credentials = creds;
    _credentialsSubscription = _credentialsProvider.boxEvents.listen((e) {
      if (e.deleted) {
        // No-op, handled in [_accountSubscription].
        return;
      }

      // Check [_accountProvider] to determine whether these [Credentials] are
      // of the active account.
      final UserId? current =
          WebUtils.credentials?.userId ?? _accountProvider.userId;

      if (e.key == current?.val) {
        WebUtils.credentials = e.value;
      }
    });

    _accountSubscription = _accountProvider.boxEvents.listen((e) {
      if (e.deleted) {
        WebUtils.credentials = null;
      } else {
        final UserId id = e.value;
        final Credentials? creds = _credentialsProvider.get(id);

        // [creds] may still be `null` here if [Credentials] haven't been put to
        // [Hive] yet. Still update [WebUtils.credentials] so that this case
        // can be handled by the [_credentialsSubscription]'s event handler.
        WebUtils.credentials = creds;
      }
    });

    if (access == null) {
      return _unauthorized();
    } else {
      if (refresh == null) {
        if (access.expireAt.isAfter(PreciseDateTime.now().toUtc())) {
          _authorized(creds!);
          status.value = RxStatus.success();
          return null;
        }
      } else if (refresh.expireAt.isAfter(PreciseDateTime.now().toUtc())) {
        _authorized(creds!);
        if (access.expireAt
            .subtract(_accessTokenMinTtl)
            .isBefore(PreciseDateTime.now().toUtc())) {
          refreshSession();
        }
        status.value = RxStatus.success();
        return null;
      }

      return _unauthorized();
    }
  }

  /// Initiates password recovery for a [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of fourth should be specified).
  ///
  /// Sends a recovery [ConfirmationCode] to [MyUser]'s [email] and [phone].
  ///
  /// If [MyUser] has no password yet, then this method still may be used for
  /// recovering his sign-in capability.
  ///
  /// The number of generated [ConfirmationCode]s is limited up to 10 per 1
  /// hour.
  Future<void> recoverUserPassword({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) async {
    Log.debug(
      'recoverUserPassword(login: $login, num: $num, email: ***, phone: ***)',
      '$runtimeType',
    );

    await _authRepository.recoverUserPassword(
      login: login,
      num: num,
      email: email,
      phone: phone,
    );
  }

  /// Validates the provided password recovery [ConfirmationCode] for a [MyUser]
  /// identified by the provided [num]/[login]/[email]/[phone] (exactly one of
  /// fourth should be specified).
  Future<void> validateUserPasswordRecoveryCode({
    required ConfirmationCode code,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) async {
    Log.debug(
      'validateUserPasswordRecoveryCode(code: $code, login: $login, num: $num, email: ***, phone: ***)',
      '$runtimeType',
    );

    await _authRepository.validateUserPasswordRecoveryCode(
      login: login,
      num: num,
      email: email,
      phone: phone,
      code: code,
    );
  }

  /// Resets password for a [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of fourth should be specified)
  /// and recovery [ConfirmationCode].
  ///
  /// If [MyUser] has no password yet, then [newPassword] will be his first
  /// password unlocking the sign-in capability.
  Future<void> resetUserPassword({
    required ConfirmationCode code,
    required UserPassword newPassword,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) async {
    Log.debug(
      'resetUserPassword(code: $code, newPassword: ***, login: $login, num: $num, email: ***, phone: ***)',
      '$runtimeType',
    );

    await _authRepository.resetUserPassword(
      login: login,
      num: num,
      email: email,
      phone: phone,
      code: code,
      newPassword: newPassword,
    );
  }

  /// Creates a new [MyUser] having only [UserId] and [UserNum] fields, and
  /// creates a new [Session] for this [MyUser] (valid for 24 hours).
  ///
  /// Once the created [Session] expires, the created [MyUser] looses access, if
  /// he doesn't re-sign in within that period of time.
  ///
  /// If [status] is already authorized, then this method does nothing.
  Future<void> register() async {
    Log.debug('register()', '$runtimeType');

    status.value = RxStatus.loading();

    await WebUtils.protect(() async {
      // If service is already authorized, then no-op, as this operation is
      // meant to be invoked only during unauthorized phase, or otherwise the
      // dependencies will be broken as of now.
      if (_hasAuthorization) {
        return;
      }

      try {
        final Credentials data = await _authRepository.signUp();
        _authorized(data);
        status.value = RxStatus.success();
      } catch (e) {
        _unauthorized();
        rethrow;
      }
    });
  }

  /// Sends a [ConfirmationCode] to the provided [email] for signing up with it.
  ///
  /// [ConfirmationCode] is sent to the [email], which should be confirmed with
  /// [confirmSignUpEmail] in order to successfully sign up.
  ///
  /// [ConfirmationCode] sent can be resent with [resendSignUpEmail].
  Future<void> signUpWithEmail(UserEmail email) async {
    Log.debug('signUpWithEmail(***)', '$runtimeType');
    await _authRepository.signUpWithEmail(email);
  }

  /// Confirms the [signUpWithEmail] with the provided [ConfirmationCode].
  ///
  /// If [status] is already authorized, then this method does nothing.
  Future<void> confirmSignUpEmail(ConfirmationCode code) async {
    Log.debug('confirmSignUpEmail($code)', '$runtimeType');

    status.value = RxStatus.loading();

    await WebUtils.protect(() async {
      // If service is already authorized, then no-op, as this operation is
      // meant to be invoked only during unauthorized phase, or otherwise the
      // dependencies will be broken as of now.
      if (_hasAuthorization) {
        return;
      }

      try {
        final Credentials data = await _authRepository.confirmSignUpEmail(code);
        _authorized(data);
        status.value = RxStatus.success();
      } catch (e) {
        _unauthorized();
        rethrow;
      }
    });
  }

  /// Resends a new [ConfirmationCode] to the [UserEmail] specified in
  /// [signUpWithEmail].
  Future<void> resendSignUpEmail() async {
    Log.debug('resendSignUpEmail()', '$runtimeType');
    await _authRepository.resendSignUpEmail();
  }

  /// Creates a new [Session] for the [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of four should be specified).
  ///
  /// The created [Session] expires in 1 day after creation.
  ///
  /// Throws [CreateSessionException].
  ///
  /// If [status] is already authorized, then this method does nothing, however
  /// this logic can be ignored by specifying [force] as `true`, but be careful,
  /// as this also ignores possible [WebUtils.protect] races - you may want to
  /// lock it before invoking this method to be async-safe.
  Future<void> signIn(
    UserPassword password, {
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    bool force = false,
  }) async {
    Log.debug(
      'signIn(***, login: $login, num: $num, email: ***, phone: ***, force: $force)',
      '$runtimeType',
    );

    // If [force] is `true`, then [WebUtils.protect] is ignored.
    final Function protect = force ? (fn) => fn() : WebUtils.protect;

    status.value =
        credentials.value == null ? RxStatus.loading() : RxStatus.loadingMore();
    await protect(() async {
      // If service is already authorized, then no-op, as this operation is
      // meant to be invoked only during unauthorized phase, or otherwise the
      // dependencies will be broken as of now.
      if (!force && _hasAuthorization) {
        return;
      }

      try {
        final Credentials creds = await _authRepository.signIn(
          password,
          login: login,
          num: num,
          email: email,
          phone: phone,
        );
        _authorized(creds);
        status.value = RxStatus.success();
      } catch (e) {
        _unauthorized();
        rethrow;
      }
    });
  }

  /// Authorizes the current [Session] from the provided [credentials].
  @visibleForTesting
  Future<void> signInWith(Credentials credentials) async {
    Log.debug('signInWith(credentials)', '$runtimeType');

    // Check if the [credentials] are valid.
    credentials =
        await _authRepository.refreshSession(credentials.refresh.secret);

    status.value = RxStatus.loadingMore();
    await WebUtils.protect(() async {
      _authorized(credentials);
      status.value = RxStatus.success();
    });
  }

  /// Deletes [Session] of the active [MyUser].
  ///
  /// Returns the path of the authentication page.
  ///
  /// If [force] is `true`, then the current [Credentials] will be revoked
  /// unilaterally and immediately.
  Future<String> deleteSession({bool force = false}) async {
    Log.debug('deleteSession(force: $force)', '$runtimeType');

    status.value = RxStatus.empty();

    if (force) {
      if (userId != null) {
        _authRepository.removeAccount(userId!);
      }

      return _unauthorized();
    }

    return await WebUtils.protect(() async {
      try {
        FcmRegistrationToken? fcmToken;

        if (PlatformUtils.pushNotifications) {
          final NotificationSettings settings =
              await FirebaseMessaging.instance.getNotificationSettings();

          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            final String? token = await FirebaseMessaging.instance.getToken(
              vapidKey: Config.vapidKey,
            );

            if (token != null) {
              fcmToken = FcmRegistrationToken(token);
            }
          }
        }

        await _authRepository.deleteSession(fcmToken);
      } catch (e) {
        printError(info: e.toString());
      }

      return _unauthorized();
    });
  }

  /// Deletes [Session] of the active [MyUser] and removes it from the list of
  /// available accounts.
  ///
  /// Returns the path of the authentication page.
  Future<String> logout() async {
    Log.debug('logout()', '$runtimeType');

    if (userId != null) {
      _authRepository.removeAccount(userId!);
    }

    return await deleteSession();
  }

  /// Validates the current [AccessToken].
  Future<bool> validateToken() async {
    Log.debug('validateToken()', '$runtimeType');

    return await WebUtils.protect(() async {
      try {
        await _authRepository.validateToken();
        return true;
      } on AuthorizationException {
        return false;
      }
    });
  }

  /// Refreshes the current [credentials].
  Future<void> refreshSession() async {
    final FutureOr<bool> futureOrBool = WebUtils.isLocked;
    final bool isLocked =
        futureOrBool is bool ? futureOrBool : await futureOrBool;

    Log.debug('refreshSession() with `isLocked`: $isLocked', '$runtimeType');

    try {
      // Do not perform renew since some other task has already renewed it. But
      // still wait for the lock to be sure that session was renewed when
      // current `refreshSession()` call resolves.
      await WebUtils.protect(() async {
        if (isLocked) {
          Log.debug(
            'refreshSession(): acquired the lock, while it was locked, thus should proceed: $_shouldRefresh',
            '$runtimeType',
          );

          if (!_shouldRefresh) {
            // [Credentials] are successfully updated.
            return;
          }
        } else {
          Log.debug(
            'refreshSession(): acquired the lock, while it was unlocked',
            '$runtimeType',
          );
        }

        // Fetch the fresh [WebUtils.credentials], if there are any.
        if (WebUtils.credentials != null &&
            WebUtils.credentials?.access.secret !=
                credentials.value?.access.secret) {
          _authorized(WebUtils.credentials!);
          status.value = RxStatus.success();
          return;
        }

        if (credentials.value == null) {
          router.go(_unauthorized());
        } else {
          try {
            final Credentials data = await _authRepository
                .refreshSession(credentials.value!.refresh.secret);
            _authorized(data);
            status.value = RxStatus.success();
          } on RefreshSessionException catch (_) {
            router.go(_unauthorized());
            rethrow;
          }
        }
      });
    } on RefreshSessionException catch (_) {
      // No-op, already handled in the [WebUtils.protect].
    } catch (e) {
      Log.debug('refreshSession(): Exception occurred: $e', '$runtimeType');

      // If any unexpected exception happens, just retry the mutation.
      await Future.delayed(const Duration(seconds: 2));
      await refreshSession();
    }
  }

  /// Uses the specified [ChatDirectLink] by the authenticated [MyUser] creating
  /// a new [Chat]-dialog or joining an existing [Chat]-group.
  Future<ChatId> useChatDirectLink(ChatDirectLinkSlug slug) async {
    Log.debug('useChatDirectLink($slug)', '$runtimeType');
    return await _authRepository.useChatDirectLink(slug);
  }



  /// Sets authorized [status] to `isLoadingMore` (aka "partly authorized").
  void _authorized(Credentials creds) {
    Log.debug('_authorized($creds)', '$runtimeType');

    _credentialsProvider.put(creds);
    _accountProvider.set(creds.userId);

    _authRepository.token = creds.access.secret;
    credentials.value = creds;
    _refreshTimer?.cancel();

    // TODO: Offload refresh task to the background process?
    _refreshTimer = Timer.periodic(_refreshTaskInterval, (timer) {
      if (credentials.value?.refresh != null && _shouldRefresh) {
        refreshSession();
      }
    });

    status.value = RxStatus.loadingMore();
  }

  /// Sets authorized [status] to `isEmpty` (aka "unauthorized").
  String _unauthorized() {
    Log.debug('_unauthorized()', '$runtimeType');

    final UserId? id = _accountProvider.userId;
    if (id != null) {
      _credentialsProvider.remove(id);
    }

    _accountProvider.clear();
    _authRepository.token = null;
    credentials.value = null;
    status.value = RxStatus.empty();
    _refreshTimer?.cancel();

    return Routes.auth;
  }
}
