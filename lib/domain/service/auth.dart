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
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';

import '../model/chat.dart';
import '../model/my_user.dart';
import '../model/precise_date_time/precise_date_time.dart';
import '../model/session.dart';
import '../model/user.dart';
import '../repository/auth.dart';
import '/provider/gql/exceptions.dart';
import '/provider/hive/session.dart';
import '/routes.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// Authentication service exposing [credentials] of the authenticated session.
///
/// It contains all the required methods to do the authentication process and
/// exposes [credentials] (a session and an user) of the authorized session.
class AuthService extends GetxService {
  AuthService(this._authRepository, this._sessionProvider);

  /// Currently authorized session's [Credentials].
  final Rx<Credentials?> credentials = Rx(null);

  /// [SessionDataHiveProvider] used to store user [Session].
  final SessionDataHiveProvider _sessionProvider;

  /// Authorization repository containing required authentication methods.
  final AbstractAuthRepository _authRepository;

  /// Authorization status.
  final Rx<RxStatus> _status = Rx<RxStatus>(RxStatus.loading());

  /// [Timer] used to periodically check the [Session.expireAt] and refresh it
  /// if necessary.
  Timer? _refreshTimer;

  /// [_refreshTimer] interval.
  final Duration _refreshTaskInterval = const Duration(minutes: 1);

  /// Minimal allowed [_session] TTL.
  final Duration _accessTokenMinTtl = const Duration(minutes: 2);

  /// Guard used to track [renewSession] completion.
  final Mutex _tokenGuard = Mutex();

  /// [StreamSubscription] to [SessionDataHiveProvider.boxEvents] saving new
  /// [Credentials] to the browser's storage.
  StreamSubscription? _sessionSubscription;

  /// [StreamSubscription] to [WebUtils.onStorageChange] fetching new
  /// [Credentials].
  StreamSubscription? _storageSubscription;

  /// Authorization status.
  ///
  /// Can be:
  /// - `status.isEmpty` meaning that `MyUser` is unauthorized;
  /// - `status.isLoading` meaning that authorization data is being fetched
  ///   from storage;
  /// - `status.isLoadingMore` meaning that `MyUser` is authorized according to
  ///   the storage, but network request to the server is still in-flight;
  /// - `status.isSuccess` meaning successful authorization.
  Rx<RxStatus> get status => _status;

  /// Returns the currently authorized [Credentials.userId].
  UserId? get userId => credentials.value?.userId;

  @override
  void onClose() {
    _storageSubscription?.cancel();
    _sessionSubscription?.cancel();
    _sessionProvider.close();
    _refreshTimer?.cancel();
  }

  /// Initializes this service.
  ///
  /// Tries to load user data from the storage and navigates to the
  /// [Routes.auth] page if this operation fails. Otherwise, fetches user data
  /// from the server to be up-to-date with it.
  Future<String?> init() async {
    // Try to refresh session, otherwise just force logout.
    _authRepository.authExceptionHandler = (e) async {
      if (credentials.value?.rememberedSession.expireAt
              .isAfter(PreciseDateTime.now().toUtc()) ==
          true) {
        await renewSession();
      } else {
        router.go(_unauthorized());
        throw e;
      }
    };

    await _sessionProvider.init();
    Credentials? creds = _sessionProvider.getCredentials();
    Session? session = creds?.session;
    RememberedSession? remembered = creds?.rememberedSession;

    // Listen to the [Credentials] changes if this window is a popup.
    if (PlatformUtils.isPopup) {
      if (PlatformUtils.isWeb) {
        _storageSubscription = WebUtils.onStorageChange.listen((e) {
          if (e.key == 'credentials') {
            if (e.newValue == null) {
              _authRepository.token = null;
              credentials.value = null;
              _status.value = RxStatus.empty();
            } else {
              Credentials creds =
                  Credentials.fromJson(json.decode(e.newValue!));
              _authRepository.token = creds.session.token;
              _authRepository.applyToken();
              credentials.value = creds;
              _status.value = RxStatus.success();
            }

            if (_tokenGuard.isLocked) {
              _tokenGuard.release();
            }
          }
        });
      } else {
        DesktopMultiWindow.addMethodHandler((methodCall, fromWindowId) async {
          if (methodCall.method == 'credentials') {
            if (methodCall.arguments != null) {
              Credentials creds =
                  Credentials.fromJson(json.decode(methodCall.arguments!));
              _authRepository.token = creds.session.token;
              _authRepository.applyToken();
              credentials.value = creds;
              _status.value = RxStatus.success();
            }

            if (_tokenGuard.isLocked) {
              _tokenGuard.release();
            }
          }
        });
      }
    } else {
      // Update the [Credentials] otherwise.
      WebUtils.credentials = creds;
      _sessionSubscription = _sessionProvider.boxEvents.listen((e) async {
        if (PlatformUtils.isWeb) {
          WebUtils.credentials = e.value?.credentials;
        } else if (!PlatformUtils.isPopup) {
          try {
            List<int> windows = await DesktopMultiWindow.getAllSubWindowIds();
            for (var w in windows) {
              DesktopMultiWindow.invokeMethod(
                w,
                'credentials',
                e.value?.credentials == null
                    ? null
                    : json.encode(e.value?.credentials.toJson()),
              );
            }
          } catch (_) {
            // No-op.
          }
        }
      });
      WebUtils.removeAllCalls();
    }

    if (session == null) {
      return _unauthorized();
    } else {
      if (remembered == null) {
        if (session.expireAt.isAfter(PreciseDateTime.now().toUtc())) {
          _authorized(creds!);
          _status.value = RxStatus.success();
          return null;
        }
      } else if (remembered.expireAt.isAfter(PreciseDateTime.now().toUtc())) {
        _authorized(creds!);
        if (session.expireAt
            .subtract(_accessTokenMinTtl)
            .isBefore(PreciseDateTime.now().toUtc())) {
          renewSession();
        }
        _status.value = RxStatus.success();
        return null;
      }

      return _unauthorized();
    }
  }

  /// Indicates whether some [User] can be identified by the given [num],
  /// [login], [email] or [phone].
  ///
  /// Exactly one of [num]/[login]/[email]/[phone] arguments must be specified.
  Future<bool> checkUserIdentifiable(
          {UserLogin? login,
          UserNum? num,
          UserEmail? email,
          UserPhone? phone}) async =>
      await _authRepository.checkUserIdentifiable(login, num, email, phone);

  /// Initiates password recovery for a [MyUser] identified by the provided
  /// [num]/[login]/[email]/[phone] (exactly one of fourth should be specified).
  ///
  /// Sends a recovery [ConfirmationCode] to [MyUser]'s `email` and `phone`.
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
  }) =>
      _authRepository.recoverUserPassword(
        login: login,
        num: num,
        email: email,
        phone: phone,
      );

  /// Validates the provided password recovery [ConfirmationCode] for a [MyUser]
  /// identified by the provided [num]/[login]/[email]/[phone] (exactly one of
  /// fourth should be specified).
  Future<void> validateUserPasswordRecoveryCode({
    required ConfirmationCode code,
    UserLogin? login,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  }) =>
      _authRepository.validateUserPasswordRecoveryCode(
        login: login,
        num: num,
        email: email,
        phone: phone,
        code: code,
      );

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
  }) =>
      _authRepository.resetUserPassword(
        login: login,
        num: num,
        email: email,
        phone: phone,
        code: code,
        newPassword: newPassword,
      );

  /// Creates a new [MyUser] having only [UserId] and [UserNum] fields, and
  /// creates a new [Session] for this [MyUser] (valid for 24 hours).
  ///
  /// Once the created [Session] expires, the created [MyUser] looses access, if
  /// he doesn't re-sign in within that period of time.
  Future<void> register() async {
    _status.value = RxStatus.loading();
    return _tokenGuard.protect(() async {
      try {
        var data = await _authRepository.signUp();
        _authorized(data);
        _sessionProvider.setCredentials(data);
        _status.value = RxStatus.success();
      } catch (e) {
        _unauthorized();
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
  Future<void> signIn(UserPassword password,
      {UserLogin? login,
      UserNum? num,
      UserEmail? email,
      UserPhone? phone}) async {
    _status.value = RxStatus.loadingMore();
    return _tokenGuard.protect(() async {
      try {
        Credentials data = await _authRepository.signIn(
          password,
          login: login,
          num: num,
          email: email,
          phone: phone,
        );
        _authorized(data);
        _sessionProvider.setCredentials(data);
        _status.value = RxStatus.success();
      } catch (e) {
        _unauthorized();
        rethrow;
      }
    });
  }

  // TODO: Clean Hive storage on logout.
  /// Deletes [Session] of the currently authenticated [MyUser].
  Future<String> logout() async {
    _status.value = RxStatus.loading();

    try {
      await _authRepository.logout();
    } catch (e) {
      printError(info: e.toString());
    }
    return _unauthorized();
  }

  /// Validates the current [AccessToken].
  Future<bool> validateToken() async {
    try {
      await _authRepository.validateToken();
      return true;
    } on AuthorizationException {
      return false;
    }
  }

  /// Refreshes the current [session].
  Future<void> renewSession() async {
    bool alreadyRenewing = _tokenGuard.isLocked;

    // Acquire the lock if this window is a popup.
    if (PlatformUtils.isPopup) {
      // The lock will be release once new [Credentials] are acquired via the
      // [WebUtils.onStorageChange] stream or method handler.
      await _tokenGuard.acquire();
      alreadyRenewing = true;
    }

    // Do not perform renew since some other task has already renewed it. But
    // still wait for the lock to be sure that session was renewed when current
    // renewSession() call resolves.
    return _tokenGuard.protect(() async {
      if (!alreadyRenewing) {
        try {
          Credentials data = await _authRepository
              .renewSession(credentials.value!.rememberedSession.token);
          _authorized(data);

          _sessionProvider.setCredentials(data);
          _status.value = RxStatus.success();
        } on RenewSessionException catch (_) {
          router.go(_unauthorized());
          rethrow;
        }
      }
    });
  }

  /// Uses the specified [ChatDirectLink] by the authenticated [MyUser] creating
  /// a new [Chat]-dialog or joining an existing [Chat]-group.
  Future<ChatId> useChatDirectLink(ChatDirectLinkSlug slug) =>
      _authRepository.useChatDirectLink(slug);

  /// Sets authorized [status] to `isLoadingMore` (aka "partly authorized").
  void _authorized(Credentials creds) {
    _authRepository.token = creds.session.token;
    credentials.value = creds;
    _refreshTimer?.cancel();
    // TODO: Offload refresh task to the background process?
    _refreshTimer = Timer.periodic(_refreshTaskInterval, (timer) {
      if (credentials.value?.rememberedSession != null &&
          credentials.value?.session.expireAt
                  .subtract(_accessTokenMinTtl)
                  .isBefore(PreciseDateTime.now().toUtc()) ==
              true) {
        renewSession();
      }
    });
    _status.value = RxStatus.loadingMore();
  }

  /// Sets authorized [status] to `isEmpty` (aka "unauthorized").
  String _unauthorized() {
    _sessionProvider.clear();
    _authRepository.token = null;
    credentials.value = null;
    _status.value = RxStatus.empty();
    _refreshTimer?.cancel();
    return Routes.auth;
  }
}
