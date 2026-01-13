// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart'
    show AppLifecycleState, visibleForTesting;
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';

import '/domain/model/chat.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/auth.dart';
import '/provider/drift/account.dart';
import '/provider/drift/credentials.dart';
import '/provider/drift/locks.dart';
import '/provider/drift/secret.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'disposable_service.dart';

/// Authentication service exposing [credentials] of the authenticated session.
///
/// It contains all the required methods to do the authentication process and
/// exposes [credentials] (a session and an user) of the authorized session.
class AuthService extends Dependency {
  AuthService(
    this._authRepository,
    this._credentialsProvider,
    this._accountProvider,
    this._lockProvider,
    this._secretProvider,
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

  /// [Credentials] of the available accounts.
  ///
  /// If there're no [Credentials] for the given [UserId], then their
  /// [Credentials] should be considered as stale.
  final RxMap<UserId, Rx<Credentials>> accounts = RxMap();

  /// [Function] to be invoked before [logout].
  Future<void> Function({bool keepData})? onLogout;

  /// Callback, called to indicate whether application has any [OngoingCall]s.
  bool Function()? hasCalls;

  /// [CredentialsDriftProvider] used to store user's [Session].
  final CredentialsDriftProvider _credentialsProvider;

  /// [AccountDriftProvider] storing the current user's [UserId].
  final AccountDriftProvider _accountProvider;

  /// [LockDriftProvider] storing the database locks.
  final LockDriftProvider _lockProvider;

  /// [RefreshSecretDriftProvider] storing the [RefreshSessionSecrets].
  final RefreshSecretDriftProvider _secretProvider;

  /// Authorization repository containing required authentication methods.
  final AbstractAuthRepository _authRepository;

  /// [Timer]s used to periodically check and refresh [Session]s of available
  /// accounts.
  final Map<UserId, Timer> _refreshTimers = {};

  /// [_refreshTimers] interval.
  final Duration _refreshTaskInterval = const Duration(seconds: 30);

  /// Minimal allowed [credentials] TTL.
  final Duration _accessTokenMinTtl = const Duration(minutes: 2);

  /// [StreamSubscription] to [WebUtils.onStorageChange] fetching new
  /// [Credentials].
  StreamSubscription? _storageSubscription;

  /// [Mutex] being unlocked only when [AppLifecycleState] is in foreground.
  final Mutex _deltaMutex = Mutex();

  /// [Worker] reacting on the [RouterState.lifecycle] changes to lock/unlock
  /// the [_deltaMutex].
  Worker? _deltaWorker;

  /// [refreshSession] attempt number counter used purely for [Log]s.
  static int _refreshAttempt = 0;

  /// Initial [Duration] to set [_refreshRetryDelay] to.
  static const Duration _initialRetryDelay = Duration(seconds: 2);

  /// Delay between [refreshSession] invokes used to backoff it when failing
  /// over and over again.
  Duration _refreshRetryDelay = _initialRetryDelay;

  /// [Stopwatch] counting since the last successful [refreshSession] occurred.
  final Map<UserId, Stopwatch> _refreshedAt = {};

  /// [Worker] reacting on [credentials] changes to notify [IdentityAware]
  /// dependencies.
  Worker? _credentialsWorker;

  /// Returns the currently authorized [Credentials.userId].
  UserId get userId => credentials.value?.userId ?? UserId.local();

  /// Returns the reactive list of known [MyUser]s.
  RxList<MyUser> get profiles => _authRepository.profiles;

  /// Indicates whether this [AuthService] is considered authorized.
  bool get _hasAuthorization => credentials.value != null;

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _storageSubscription?.cancel();
    _deltaWorker?.dispose();
    _refreshTimers.forEach((_, t) => t.cancel());
    _refreshTimers.clear();
    _credentialsWorker?.dispose();

    _authRepository.authExceptionHandler = null;
  }

  /// Initializes this service.
  ///
  /// Tries to load user data from the storage and navigates to the
  /// [Routes.auth] page if this operation fails. Otherwise, fetches user data
  /// from the server to be up-to-date with it.
  Future<String?> init() async {
    Log.debug('init()', '$runtimeType');

    _authRepository.authExceptionHandler = (e) async {
      // Always try to refresh session, as we cannot rely on the expiry dates.
      await refreshSession(proceedIfRefreshBefore: DateTime.now());
    };

    UserId? previousId;

    _credentialsWorker = ever(credentials, (_) {
      if (previousId == userId) {
        Log.debug(
          '_credentialsWorker -> onIdentityChanged($userId) ignored, since `$previousId` is the same',
          '$runtimeType',
        );
        return;
      }

      final List<IdentityAware> deps = Get.findAll<IdentityAware>();
      deps.sort((a, b) => a.order.compareTo(b.order));

      Log.debug(
        '_credentialsWorker -> onIdentityChanged($userId) for $deps',
        '$runtimeType',
      );

      for (var e in deps) {
        e.onIdentityChanged(userId);
      }
    });

    // Listen to the [Credentials] changes to stay synchronized with another
    // tabs.
    _storageSubscription = WebUtils.onStorageChange.listen((e) {
      if (e.key?.startsWith('credentials_') ?? false) {
        Log.debug(
          '_storageSubscription(${e.key}): received a credentials update',
          '$runtimeType',
        );

        if (e.newValue != null) {
          final Credentials received = Credentials.fromJson(
            json.decode(e.newValue!),
          );
          Credentials? current = credentials.value;
          final bool authorized = _hasAuthorization;

          if (!authorized ||
              received.userId == current?.userId &&
                  received.access.secret != current?.access.secret) {
            // These [Credentials] should be treated as current ones, so just
            // apply them as saving to local storage has already been performed
            // by another tab.
            _authRepository.token = received.access.secret;
            _authRepository.applyToken();
            credentials.value = received;
            _putCredentials(received);
            status.value = RxStatus.success();

            if (!authorized) {
              router.home();
            }
          } else {
            current = accounts[received.userId]?.value;
            if (received.access.secret != current?.access.secret) {
              // These [Credentials] are of another account, so just save them.
              _putCredentials(received);
            }
          }
        } else {
          final UserId? deletedId = accounts.keys.firstWhereOrNull(
            (k) => e.key?.endsWith(k.val) ?? false,
          );

          accounts.remove(deletedId);

          final bool currentAreNull = credentials.value == null;
          final bool currentDeleted = deletedId != null && deletedId == userId;

          if ((currentAreNull || currentDeleted) && !WebUtils.isPopup) {
            router.go(_unauthorized());
          }
        }
      }
    });

    _deltaWorker = ever(PlatformUtils.isDeltaSynchronized, (
      bool synchronized,
    ) async {
      if (synchronized) {
        if (_deltaMutex.isLocked) {
          _deltaMutex.release();
        }
      } else {
        if (!_deltaMutex.isLocked) {
          await _deltaMutex.acquire();
        }
      }
    });

    return await WebUtils.protect(() async {
      if (isClosed) {
        return null;
      }

      final List<Credentials> allCredentials = await _credentialsProvider.all();
      for (final Credentials e in allCredentials) {
        WebUtils.putCredentials(e);
        _putCredentials(e);
      }

      final UserId? userId = _accountProvider.userId;
      final Credentials? creds = userId != null
          ? allCredentials.firstWhereOrNull((e) => e.userId == userId)
          : null;

      if (creds == null) {
        return _unauthorized();
      }

      final AccessToken access = creds.access;
      final RefreshToken refresh = creds.refresh;

      if (access.expireAt.isAfter(PreciseDateTime.now().toUtc())) {
        await _authorized(creds);
        status.value = RxStatus.success();
        return null;
      } else if (refresh.expireAt.isAfter(PreciseDateTime.now().toUtc())) {
        await _authorized(creds);

        if (_areExpired(creds)) {
          refreshSession();
        }
        status.value = RxStatus.success();
        return null;
      } else {
        // Neither [AccessToken] nor [RefreshToken] are valid, should logout.
        return _unauthorized();
      }
    });
  }

  /// Returns authorization status of the [MyUser] identified by the provided
  /// [UserId], if [userId] is non-`null`, or of the active [MyUser] otherwise.
  bool isAuthorized([UserId? userId]) {
    if (userId == null || userId == credentials.value?.userId) {
      return _hasAuthorization;
    }

    return accounts[userId]?.value != null;
  }

  /// Generates and sends a new single-use [ConfirmationCode] for the [MyUser]
  /// identified by the provided [login], [num], [email] and/or [phone].
  Future<void> createConfirmationCode({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    String? locale,
  }) async {
    Log.debug(
      'createConfirmationCode(login: $login, num: $num, email: ${email?.obscured}, phone: ${phone?.obscured}, locale: $locale)',
      '$runtimeType',
    );

    await _authRepository.createConfirmationCode(
      login: num == null ? login : null,
      num: num,
      email: email,
      phone: phone,
      locale: locale,
    );
  }

  /// Validates the provided ConfirmationCode for the MyUser identified by the
  /// provided [login], [num], [email] and/or [phone] without using it.
  Future<void> validateConfirmationCode({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    required ConfirmationCode code,
  }) async {
    Log.debug(
      'validateConfirmationCode(login: $login, num: $num, email: ${email?.obscured}, phone: ${phone?.obscured})',
      '$runtimeType',
    );

    await _authRepository.validateConfirmationCode(
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
  Future<void> updateUserPassword({
    required ConfirmationCode code,
    required UserPassword newPassword,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) async {
    Log.debug(
      'updateUserPassword(code: $code, newPassword: ${newPassword.obscured}, login: $login, num: $num, email: ${email?.obscured}, ${phone?.obscured})',
      '$runtimeType',
    );

    await _authRepository.updateUserPassword(
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
  /// If [status] is already authorized, then this method does nothing, however,
  /// this logic can be ignored by specifying [force] as `true`.
  Future<void> register({
    UserPassword? password,
    UserLogin? login,
    bool force = false,
  }) async {
    Log.debug('register(force: $force)', '$runtimeType');

    status.value = force ? RxStatus.loadingMore() : RxStatus.loading();

    await WebUtils.protect(() async {
      if (isClosed) {
        return;
      }

      // If service is already authorized, then no-op, as this operation is
      // meant to be invoked only during unauthorized phase or account
      // switching, or otherwise the dependencies will be broken as of now.
      if (!force && _hasAuthorization) {
        return;
      }

      try {
        final Credentials data = await _authRepository.signUp(
          login: login,
          password: password,
        );
        await _authorized(data);
        status.value = RxStatus.success();
      } catch (e) {
        if (force) {
          status.value = RxStatus.success();
        } else {
          _unauthorized();
        }
        rethrow;
      }
    });
  }

  /// Creates a new [Session] for the [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of four should be specified).
  ///
  /// The created [Session] expires in 1 day after creation.
  ///
  /// Throws [CreateSessionException].
  ///
  /// If [status] is already authorized, then this method does nothing, however,
  /// this logic can be ignored by specifying [force] as `true`.
  ///
  /// If [unsafe] is `true` then this method ignores possible [WebUtils.protect]
  /// races - you may want to lock it before invoking this method to be
  /// async-safe.
  Future<void> signIn({
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
    UserPassword? password,
    ConfirmationCode? code,
    bool unsafe = false,
    bool force = false,
  }) async {
    Log.debug(
      'signIn(password: ${password?.obscured}, code: $code, login: $login, num: $num, email: ${email?.obscured}, phone: ${phone?.obscured}, unsafe: $unsafe, force: $force)',
      '$runtimeType',
    );

    // If [ignoreLock] is `true`, then [WebUtils.protect] is ignored.
    final Function protect = unsafe ? (fn) => fn() : WebUtils.protect;

    status.value = _hasAuthorization
        ? RxStatus.loadingMore()
        : RxStatus.loading();

    Log.debug('signIn() -> await protect()...', '$runtimeType');
    await protect(() async {
      Log.debug('signIn() -> await protect()... done!', '$runtimeType');

      if (isClosed) {
        return;
      }

      try {
        final Credentials creds = await _authRepository.signIn(
          password: password,
          code: code,
          login: num == null ? login : null,
          num: num,
          email: email,
          phone: phone,
        );
        await _authorized(creds);
        status.value = RxStatus.success();
      } catch (e) {
        if (force) {
          status.value = RxStatus.success();
        } else {
          _unauthorized();
        }

        rethrow;
      }
    });
  }

  /// Authorizes the current [Session] from the provided [credentials].
  @visibleForTesting
  Future<void> signInWith(Credentials credentials) async {
    Log.debug('signInWith(credentials)', '$runtimeType');

    // Check if the [credentials] are valid.
    credentials = await _authRepository.refreshSession(
      credentials.refresh.secret,
    );

    status.value = RxStatus.loadingMore();
    await WebUtils.protect(() async {
      if (isClosed) {
        return;
      }

      await _authorized(credentials);
      status.value = RxStatus.success();
    });
  }

  /// Deletes [Session] with the provided [id], if any, or otherwise [Session]
  /// of the active [MyUser].
  ///
  /// Returns the path of the authentication page.
  ///
  /// If [force] is `true`, then the current [Credentials] will be revoked
  /// unilaterally and immediately.
  Future<String?> deleteSession({
    SessionId? id,
    UserPassword? password,
    ConfirmationCode? code,
    bool force = false,
    bool keepData = true,
  }) async {
    Log.debug(
      'deleteSession($id, password: ${password?.obscured}, code: $code, force: $force, keepData: $keepData)',
      '$runtimeType',
    );

    if (id != null) {
      await _authRepository.deleteSession(
        id: id,
        password: password,
        code: code,
      );

      return null;
    }

    status.value = RxStatus.empty();

    final Future<void> Function({bool keepData})? logoutCallback = onLogout;
    Future<void> handleCallbacks() async {
      if (logoutCallback != null) {
        Log.debug('Invoking `onLogout(keepData: $keepData)`', '$runtimeType');

        try {
          await logoutCallback(keepData: keepData);
        } catch (e) {
          Log.debug('Unable to invoke `onLogout()`: $e', '$runtimeType');
        }

        onLogout = null;
        hasCalls = null;
      }
    }

    if (force) {
      _authRepository.removeAccount(userId);

      _unauthorized();

      await handleCallbacks();

      return Routes.auth;
    }

    return await WebUtils.protect(() async {
      if (isClosed) {
        return null;
      }

      try {
        await _authRepository.deleteSession();
      } catch (e) {
        Log.warning('Failed to delete `Session`: $e');
      }

      _unauthorized();

      await handleCallbacks();

      return Routes.auth;
    });
  }

  /// Deletes [Session] of the active [MyUser] and removes it from the list of
  /// available accounts.
  ///
  /// Returns the path of the authentication page.
  ///
  /// If [keepProfile] is `true`, then keeps the [MyUser] in the [profiles].
  Future<String> logout([bool keepProfile = false]) async {
    Log.debug('logout()', '$runtimeType');

    accounts.remove(userId);
    if (!keepProfile) {
      profiles.removeWhere((e) => e.id == userId);
    }

    _authRepository.removeAccount(userId, keepProfile: keepProfile);

    return await deleteSession(keepData: keepProfile) ?? Routes.auth;
  }

  /// Switches to the account with the provided [UserId] using the persisted
  /// [Credentials].
  ///
  /// Returns `true` if the account was successfully switched, otherwise returns
  /// `false`.
  Future<bool> switchAccount(UserId userId) async {
    Log.debug('switchAccount($userId)', '$runtimeType');

    Credentials? creds = accounts[userId]?.value;
    if (creds == null) {
      return false;
    }

    final bool hadAuthorization = _hasAuthorization;

    status.value = RxStatus.loading();

    try {
      if (_areExpired(creds)) {
        await refreshSession(userId: creds.userId);
      }

      creds = accounts[userId]?.value;
      if (creds == null) {
        status.value = hadAuthorization ? RxStatus.success() : RxStatus.empty();
        return false;
      }

      // TODO: Remove, when remote subscription to each [MyUser] events is up.
      //
      // This workarounds the situation when the password of another account was
      // changed or the account was deleted.
      final bool areValid = await validateToken(creds);
      if (areValid) {
        await WebUtils.protect(() async {
          if (isClosed) {
            return;
          }

          await _authorized(creds!);
          status.value = RxStatus.success();
        });

        return true;
      } else {
        status.value = hadAuthorization ? RxStatus.success() : RxStatus.empty();
        _credentialsProvider.delete(userId);
        accounts.remove(userId);
      }
    } catch (_) {
      status.value = hadAuthorization ? RxStatus.success() : RxStatus.empty();
      rethrow;
    }

    return false;
  }

  /// Deletes the [MyUser] identified by the provided [id] from the accounts and
  /// invalidates their [Session].
  Future<void> removeAccount(UserId id) async {
    Log.debug('removeAccount($id)', '$runtimeType');

    _authRepository.removeAccount(id);

    // Delete [Session] for this account if it's not the current one.
    final AccessTokenSecret? token = accounts[id]?.value.access.secret;
    if (id != userId && token != null) {
      await _authRepository.deleteSession(accessToken: token);
    }
  }

  /// Validates the [AccessToken] of the provided [Credentials].
  ///
  /// If none provided, checks the current [credentials].
  Future<bool> validateToken([Credentials? creds]) async {
    if (creds == null) {
      Log.debug(
        'validateToken($creds) with current being: ${credentials.value}',
        '$runtimeType',
      );
    } else {
      Log.debug('validateToken($creds)', '$runtimeType');
    }

    return await WebUtils.protect(() async {
      if (isClosed) {
        return false;
      }

      // If [creds] are not provided, then validate the current [credentials].
      creds ??= credentials.value;

      if (creds == null) {
        return false;
      }

      try {
        await _authRepository.validateToken(creds!);
        return true;
      } on AuthorizationException {
        return false;
      }
    });
  }

  /// Refreshes [Credentials] of the account with the provided [userId] or of
  /// the active one, if [userId] is not provided.
  Future<void> refreshSession({
    UserId? userId,
    DateTime? proceedIfRefreshBefore,
  }) async {
    final int attempt = _refreshAttempt++;

    final FutureOr<bool> futureOrBool = WebUtils.isLocked;
    final bool isLocked = futureOrBool is bool
        ? futureOrBool
        : await futureOrBool;

    userId ??= this.userId;
    final bool areCurrent = userId == this.userId;

    Log.debug(
      'refreshSession($userId |-> $attempt) with `isLocked` ($isLocked)',
      '$runtimeType',
    );

    LockIdentifier? dbLock;

    try {
      // Acquire a database lock to prevent multiple refreshes of the same
      // [Credentials] from multiple processes.
      dbLock = await _lockProvider.acquire('refreshSession($userId)');

      // Wait for the lock to be released and check the [Credentials] again as
      // some other task may have already refreshed them.
      await WebUtils.protect(() async {
        if (isClosed) {
          return;
        }

        Log.debug(
          'refreshSession($userId |-> $attempt) acquired both `dbLock` and `WebUtils.protect()`',
          '$runtimeType',
        );

        final Stopwatch? watch = _refreshedAt[userId];

        // If previous `refreshSession()` happened less than 10 seconds ago,
        // then ignore this `refreshSession()`, since it might already be new.
        if (watch != null) {
          if (watch.elapsed.inSeconds <= 10) {
            Log.debug(
              'refreshSession($userId |-> $attempt) seems like `Stopwatch` is less than 10 seconds: ${watch.elapsed}, thus ignoring this `refreshSession()`',
              '$runtimeType',
            );

            return Future.value();
          }
        }

        while (!WebUtils.isOnLine && !isClosed) {
          Log.debug(
            'refreshSession($userId |-> $attempt) navigator.onLine returned `false`, retrying in 1 seconds...',
            '$runtimeType',
          );

          await Future.delayed(Duration(seconds: 1));

          // If there's any ongoing call, then ignore the device being in
          // background.
          if (WebUtils.containsCalls() || hasCalls?.call() == true) {
            Log.debug(
              'refreshSession($userId |-> $attempt) navigator.onLine returned `false`, however there\'s a call, thus proceeding: ${WebUtils.containsCalls()} || ${hasCalls?.call()}',
              '$runtimeType',
            );
            break;
          }
        }

        Credentials? oldCreds;

        if (userId != null) {
          oldCreds = await _credentialsProvider.read(userId, refresh: true);

          Log.debug(
            'refreshSession($userId |-> $attempt) read from `drift` the `oldCreds`: $oldCreds',
            '$runtimeType',
          );
        }

        if (areCurrent) {
          Log.debug(
            'refreshSession($userId |-> $attempt) `areCurrent` is `true`, which will apply `credentials.value` to `oldCreds` if ${oldCreds == null} -> ${credentials.value}',
            '$runtimeType',
          );

          oldCreds ??= credentials.value;
        }

        if (userId == null) {
          Log.warning(
            'refreshSession($userId |-> $attempt): `userId` is `null`, unable to proceed',
            '$runtimeType',
          );

          return _refreshRetryDelay = _initialRetryDelay;
        }

        if (oldCreds != null) {
          accounts[userId]?.value = oldCreds;
        } else {
          accounts.remove(userId);
        }

        // Ensure the retrieved credentials are the current ones, or otherwise
        // authorize with those.
        if (oldCreds != null &&
            oldCreds.access.secret != credentials.value?.access.secret &&
            !_areExpired(oldCreds)) {
          Log.debug(
            'refreshSession($userId |-> $attempt): false alarm, applying the retrieved fresh credentials',
            '$runtimeType',
          );

          if (areCurrent) {
            await _authorized(oldCreds);
            status.value = RxStatus.success();
          } else {
            // [Credentials] of another account were refreshed.
            _putCredentials(oldCreds);
          }

          return _refreshRetryDelay = _initialRetryDelay;
        }

        if (isLocked) {
          Log.debug(
            'refreshSession($userId |-> $attempt): acquired the lock, while it was locked -> should refresh: ${_areExpired(oldCreds)} (comparing oldCreds(${oldCreds?.access.expireAt.toUtc()}).subtract($_accessTokenMinTtl) = ${oldCreds?.access.expireAt.toUtc().subtract(_accessTokenMinTtl)} vs now(${PreciseDateTime.now().toUtc()}))',
            '$runtimeType',
          );
        } else {
          Log.debug(
            'refreshSession($userId |-> $attempt): acquired the lock, while it was unlocked -> should refresh: ${_areExpired(oldCreds)} (comparing oldCreds(${oldCreds?.access.expireAt.toUtc()}).subtract($_accessTokenMinTtl) = ${oldCreds?.access.expireAt.toUtc().subtract(_accessTokenMinTtl)} vs now(${PreciseDateTime.now().toUtc()}))',
            '$runtimeType',
          );
        }

        if (!_areExpired(oldCreds)) {
          if (oldCreds != null) {
            if (credentials.value?.access.secret != oldCreds.access.secret ||
                credentials.value?.refresh.secret != oldCreds.refresh.secret) {
              Log.debug(
                'refreshSession($userId |-> $attempt): `credentials.value` differ from `oldCreds`, thus (since `_shouldRefresh` is `false`) authorizing those',
                '$runtimeType',
              );

              _authorized(oldCreds);
            }
          }

          bool shouldProceed = false;

          final Credentials? creds = credentials.value;
          if (creds != null && proceedIfRefreshBefore != null) {
            shouldProceed = proceedIfRefreshBefore.isAfter(
              // Add a delay just to prevent possible races between old access
              // token still being used in WebSocket connection.
              creds.session.lastActivatedAt.val.add(Duration(seconds: 10)),
            );

            if (!shouldProceed) {
              // Shouldn't rely on the time, thus only check whether the session
              // refreshment was locked or not.
              shouldProceed = !isLocked;
            }
          }

          if (!shouldProceed) {
            // [Credentials] are fresh.
            return _refreshRetryDelay = _initialRetryDelay;
          }

          Log.debug(
            'refreshSession($userId |-> $attempt): should refresh is `false`, yet proceeding as !isLocked(${!isLocked}) or ${creds?.session.lastActivatedAt.val.toUtc()} (+10 seconds) is before ${proceedIfRefreshBefore?.toUtc()}',
            '$runtimeType',
          );
        }

        if (oldCreds == null) {
          Log.debug(
            'refreshSession($userId |-> $attempt): `oldCreds` are `null`, seems like during the lock those were removed -> unauthorized',
            '$runtimeType',
          );

          // These [Credentials] were removed while we've been waiting for the
          // lock to be released.
          if (areCurrent) {
            router.go(_unauthorized());
          }

          return _refreshRetryDelay = _initialRetryDelay;
        }

        if (!PlatformUtils.isDeltaSynchronized.value) {
          if (WebUtils.containsCalls() || hasCalls?.call() == true) {
            Log.debug(
              'refreshSession($userId |-> $attempt) should wait for application to be active, however there are calls active, thus ignoring the check',
              '$runtimeType',
            );
          } else {
            Log.debug(
              'refreshSession($userId |-> $attempt) waiting for application to be active...',
              '$runtimeType',
            );

            Completer? completer = Completer();

            // Check for calls in period to proceed refreshing the session if
            // any.
            while (completer?.isCompleted != false) {
              _deltaMutex
                  .acquire()
                  .then((_) => completer?.complete())
                  .catchError((_) => completer?.complete());

              await Future.delayed(Duration(seconds: 2));

              if (WebUtils.containsCalls() || hasCalls?.call() == true) {
                Log.debug(
                  'refreshSession($userId |-> $attempt) waiting for application to be active... seems like there are calls active, thus ignoring the check',
                  '$runtimeType',
                );

                try {
                  completer?.complete();
                } catch (_) {
                  completer = null;
                  // No-op.
                }
              }
            }

            Log.debug(
              'refreshSession($userId |-> $attempt) waiting for application to be active... done! ✨',
              '$runtimeType',
            );

            if (_deltaMutex.isLocked) {
              _deltaMutex.release();
            }
          }
        }

        try {
          final Credentials data = await _authRepository.refreshSession(
            oldCreds.refresh.secret,
            input: await _secretProvider.getOrCreate(oldCreds.userId),
            reconnect: areCurrent,
          );

          Log.debug(
            'refreshSession($userId |-> $attempt): success 🎉 -> writing to `drift`... ✍️',
            '$runtimeType',
          );

          await _secretProvider.delete(oldCreds.userId);
          _refreshedAt[userId]?.stop();
          _refreshedAt[userId] = Stopwatch()..start();

          if (areCurrent) {
            await _authorized(data);
          } else {
            // [Credentials] of not currently active account were updated,
            // just save them.
            //
            // Saving to local storage is safe here, as this callback is
            // guarded by the [WebUtils.protect] lock.
            await _credentialsProvider.upsert(data);
            _putCredentials(data);
          }

          Log.debug(
            'refreshSession($userId |-> $attempt): success 🎉 -> writing to `drift`... done ✅',
            '$runtimeType',
          );

          _refreshRetryDelay = _initialRetryDelay;
          status.value = RxStatus.success();
        } on RefreshSessionException catch (_) {
          Log.debug(
            'refreshSession($userId |-> $attempt): ⛔️ `RefreshSessionException` occurred ⛔️, removing credentials',
            '$runtimeType',
          );

          if (areCurrent) {
            router.go(_unauthorized());
          } else {
            // Remove stale [Credentials].
            accounts.remove(oldCreds.userId);
            await _credentialsProvider.delete(oldCreds.userId);
            await _secretProvider.delete(oldCreds.userId);
          }

          _refreshRetryDelay = _initialRetryDelay;
          rethrow;
        }
      });

      await _lockProvider.release(dbLock);
    } on RefreshSessionException catch (_) {
      _refreshRetryDelay = _initialRetryDelay;

      if (dbLock != null) {
        await _lockProvider.release(dbLock);
      }

      rethrow;
    } catch (e) {
      Log.debug(
        'refreshSession($userId |-> $attempt): ⛔️ exception occurred: $e',
        '$runtimeType',
      );

      if (dbLock != null) {
        await _lockProvider.release(dbLock);
      }

      // If any unexpected exception happens, just retry the mutation.
      await Future.delayed(_refreshRetryDelay);
      if (_refreshRetryDelay.inSeconds < 12) {
        _refreshRetryDelay = _refreshRetryDelay * 2;
      }

      Log.debug(
        'refreshSession($userId |-> $attempt): backoff passed, trying again',
        '$runtimeType',
      );

      await refreshSession(userId: userId);
    }
  }

  /// Uses the specified [ChatDirectLink] by the authenticated [MyUser] creating
  /// a new [Chat]-dialog or joining an existing [Chat]-group.
  Future<Chat> useChatDirectLink(ChatDirectLinkSlug slug) async {
    Log.debug('useChatDirectLink($slug)', '$runtimeType');
    return await _authRepository.useChatDirectLink(slug);
  }

  /// Puts the provided [creds] to [accounts].
  void _putCredentials(Credentials creds) {
    Log.debug('_putCredentials($creds)', '$runtimeType');

    final Rx<Credentials>? stored = accounts[creds.userId];
    if (stored == null) {
      accounts[creds.userId] = Rx(creds);
    } else {
      stored.value = creds;
    }
  }

  /// Initializes the refresh timers for all the authenticated [MyUser]s.
  void _initRefreshTimers() {
    Log.debug('_initRefreshTimers()', '$runtimeType');

    _refreshTimers.forEach((_, t) => t.cancel());
    _refreshTimers.clear();

    for (final UserId id in accounts.keys) {
      _refreshTimers[id] = Timer.periodic(_refreshTaskInterval, (_) async {
        final Credentials? creds = accounts[id]?.value;
        if (creds == null) {
          Log.debug(
            '_initRefreshTimers(): no credentials found for user $id, killing timer',
            '$runtimeType',
          );

          // Cancel the timer to avoid memory leaks.
          _refreshTimers.remove(id)?.cancel();
          return;
        }

        if (_areExpired(creds)) {
          await refreshSession(userId: id);
        }
      });
    }
  }

  /// Sets authorized [status] to `isLoadingMore` (aka "partly authorized").
  Future<void> _authorized(Credentials creds) async {
    Log.debug('_authorized($creds)', '$runtimeType');

    await Future.wait([
      _credentialsProvider.upsert(creds),
      _accountProvider.upsert(creds.userId),
    ]);

    _authRepository.token = creds.access.secret;
    credentials.value = creds;
    _putCredentials(creds);
    WebUtils.putCredentials(creds);

    _initRefreshTimers();

    status.value = RxStatus.loadingMore();
  }

  /// Sets authorized [status] to `isEmpty` (aka "unauthorized").
  String _unauthorized() {
    Log.debug('_unauthorized()', '$runtimeType');

    final UserId id = userId;
    _credentialsProvider.delete(id);
    _secretProvider.delete(id);
    _refreshTimers.remove(id)?.cancel();
    accounts.remove(id);
    WebUtils.removeCredentials(id);

    if (id == _accountProvider.userId) {
      // This workarounds the situation when another tab on Web has already
      // rewritten the value in [_accountProvider] during switching to another
      // account but the tab this code is running on still uses the
      // [credentials] of an old one, which is an expected behavior.
      _accountProvider.delete();
    }

    _authRepository.token = null;
    credentials.value = null;
    status.value = RxStatus.empty();

    onLogout = null;
    hasCalls = null;

    return Routes.auth;
  }

  /// Indicates whether the [credentials] are considered expired by [DateTime].
  ///
  /// If [credentials] aren't provided, then ones of the current session are
  /// checked.
  bool _areExpired([Credentials? credentials]) {
    final Credentials? creds = credentials ?? this.credentials.value;

    return creds?.access.expireAt
            .toUtc()
            .subtract(_accessTokenMinTtl)
            .isBefore(PreciseDateTime.now().toUtc()) ??
        false;
  }
}
