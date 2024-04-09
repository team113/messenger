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

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http_parser/http_parser.dart';
import 'package:messenger/api/backend/schema.dart'
    show ConfirmUserEmailErrorCode, ConfirmUserPhoneErrorCode;
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/account.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/api/backend/extension/credentials.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/phone_field.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/mime.dart';
import 'package:messenger/util/platform_utils.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/text_field.dart';

/// Possible [AccountsView] flow stage.
enum AccountsViewStage {
  accounts,
  add,
  signIn,
  signUp,
  signUpWithEmail,
  signUpWithPhone,
  oauth,
  oauthNoUser,
  oauthOccupied,
  signInWithPhone,
  signInWithPhoneCode,
  signUpWithPhoneCode,
  signUpWithEmailCode,
  signInWithEmailCode,
  signInWithEmail,
  signInWithPassword,
  signInWithQrShow,
  signInWithQrScan,
}

/// Controller of an [AccountsView].
class AccountsController extends GetxController {
  AccountsController(
    this._myUser,
    this._authService,
    this._userService, {
    AccountsViewStage initial = AccountsViewStage.accounts,
  }) : stage = Rx(initial);

  /// [AccountsViewStage] currently being displayed.
  late final Rx<AccountsViewStage> stage;

  /// [MyUser.num]'s copyable [TextFieldState].
  late final TextFieldState login;

  /// [TextFieldState] for a password input.
  late final TextFieldState password;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  final Rx<RxStatus> status = Rx(RxStatus.empty());
  final RxList<AccountWithUser> accounts = RxList();

  late final TextFieldState email = TextFieldState(
    revalidateOnUnfocus: true,
    onChanged: (s) {
      try {
        if (s.text.isNotEmpty) {
          UserEmail(s.text.toLowerCase());
        }

        s.error.value = null;
      } on FormatException {
        s.error.value = 'err_incorrect_email'.l10n;
      }
    },
    onSubmitted: (s) async {
      print(s.error.value);

      if (s.error.value != null) {
        return;
      }

      stage.value = stage.value.registering
          ? AccountsViewStage.signUpWithEmailCode
          : AccountsViewStage.signInWithEmailCode;

      final GraphQlProvider graphQlProvider = Get.find();

      try {
        final response = await graphQlProvider.signUp();
        creds = response.toModel();
        graphQlProvider.token = creds!.access.secret;
        await graphQlProvider.addUserEmail(UserEmail(email.text));
        graphQlProvider.token = null;

        s.unsubmit();
      } on AddUserEmailException catch (e) {
        graphQlProvider.token = null;
        s.error.value = e.toMessage();

        stage.value = stage.value.registering
            ? AccountsViewStage.signUpWithEmail
            : AccountsViewStage.signInWithEmail;
      } catch (e) {
        graphQlProvider.token = null;
        s.error.value = 'err_data_transfer'.l10n;
        s.unsubmit();

        stage.value = stage.value.registering
            ? AccountsViewStage.signUpWithEmail
            : AccountsViewStage.signInWithEmail;

        rethrow;
      }
    },
  );

  late final TextFieldState emailCode = TextFieldState(
    revalidateOnUnfocus: true,
    onSubmitted: (s) async {
      final GraphQlProvider graphQlProvider = Get.find();

      try {
        if (!stage.value.registering && s.text == '2222') {
          throw const ConfirmUserEmailException(
            ConfirmUserEmailErrorCode.occupied,
          );
        }

        graphQlProvider.token = creds!.access.secret;
        await graphQlProvider.confirmEmailCode(ConfirmationCode(s.text));

        router.noIntroduction = false;
        router.signUp = true;
        await switchTo(Account(creds!, myUser.value!));

        // _redirect();
      } on FormatException catch (_) {
        graphQlProvider.token = null;
        s.error.value = 'err_wrong_recovery_code'.l10n;
      } catch (_) {
        graphQlProvider.token = null;
        s.error.value = 'err_data_transfer'.l10n;
        s.unsubmit();
      }
    },
  );

  Credentials? creds;

  late final PhoneFieldState phone = PhoneFieldState(
    revalidateOnUnfocus: true,
    onChanged: (s) {
      try {
        if (!s.isEmpty.value) {
          UserPhone(s.phone!.international);

          if (!s.phone!.isValid()) {
            throw const FormatException('Does not match validation RegExp');
          }
        }

        s.error.value = null;
      } on FormatException {
        s.error.value = 'err_incorrect_phone'.l10n;
      }
    },
    onSubmitted: (s) async {
      if (s.error.value != null) {
        return;
      }

      stage.value = stage.value.registering
          ? AccountsViewStage.signUpWithPhoneCode
          : AccountsViewStage.signInWithPhoneCode;

      final GraphQlProvider graphQlProvider = Get.find();

      try {
        final response = await graphQlProvider.signUp();
        creds = response.toModel();
        graphQlProvider.token = creds!.access.secret;
        await graphQlProvider.addUserPhone(
          UserPhone(phone.controller2.value!.international.toLowerCase()),
        );
        graphQlProvider.token = null;

        s.unsubmit();
      } on AddUserPhoneException catch (e) {
        graphQlProvider.token = null;
        s.error.value = e.toMessage();
        stage.value = stage.value.registering
            ? AccountsViewStage.signUpWithPhone
            : AccountsViewStage.signInWithPhone;
      } catch (_) {
        graphQlProvider.token = null;
        s.error.value = 'err_data_transfer'.l10n;
        s.unsubmit();
        stage.value = stage.value.registering
            ? AccountsViewStage.signUpWithPhone
            : AccountsViewStage.signInWithPhone;
      }

      stage.value = stage.value.registering
          ? AccountsViewStage.signUpWithPhoneCode
          : AccountsViewStage.signInWithPhoneCode;
    },
  );

  late final TextFieldState phoneCode = TextFieldState(
    revalidateOnUnfocus: true,
    onSubmitted: (s) async {
      try {
        if (ConfirmationCode(s.text).val == '1111') {
          if (stage.value.registering) {
            router.noIntroduction = false;
            router.signUp = true;

            await switchTo(Account(creds!, myUser.value!));
            // _redirect();
          }
        } else if (ConfirmationCode(s.text).val == '2222') {
          throw const ConfirmUserPhoneException(
            ConfirmUserPhoneErrorCode.occupied,
          );
        } else {
          throw const ConfirmUserPhoneException(
            ConfirmUserPhoneErrorCode.wrongCode,
          );
        }
      } on FormatException catch (_) {
        s.error.value = 'err_wrong_recovery_code'.l10n;
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
        s.unsubmit();
      }
    },
  );

  /// [MyUserService] setting the password.
  final MyUserService _myUser;

  final AuthService _authService;
  final UserService _userService;

  final Map<UserId, StreamSubscription> _userSubscriptions = {};

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUser.myUser;

  List<Account> get _accounts => _authService.accounts;

  @override
  void onInit() {
    login = TextFieldState(onSubmitted: (s) {
      password.focus.requestFocus();
    });

    password = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        if (s.text.isNotEmpty) {
          try {
            UserPassword(s.text);
          } on FormatException {
            if (s.text.isEmpty) {
              s.error.value = 'err_password_empty'.l10n;
            } else {
              s.error.value = 'err_password_incorrect'.l10n;
            }
          }
        }
      },
      onSubmitted: (s) async {
        if (!password.status.value.isEmpty) {
          return;
        }

        password.status.value = RxStatus.loading();
        await _authService.signIn(
          UserPassword(password.text),
          login: UserLogin(login.text),
        );
        password.status.value = RxStatus.empty();

        router.go(Routes.nowhere);
        await Future.delayed(const Duration(milliseconds: 500));
        router.home();
      },
    );

    _initUsers();

    super.onInit();
  }

  void _initUsers() async {
    status.value = RxStatus.loading();

    final List<Future> futures = [];

    for (var e in _accounts) {
      final user = await _userService.get(e.myUser.id);
      if (user != null) {
        accounts.add(AccountWithUser(e, user));
        futures.add(user.ensureRefreshed());
      }
    }

    await Future.wait(futures);

    accounts.sort((a, b) {
      if (_authService.credentials.value?.userId == a.id) {
        return -1;
      } else if (_authService.credentials.value?.userId == b.id) {
        return 1;
      } else if (a.user.user.value.online && !b.user.user.value.online) {
        return -1;
      } else if (!a.user.user.value.online && b.user.user.value.online) {
        return 1;
      } else if (a.user.user.value.lastSeenAt == null ||
          b.user.user.value.lastSeenAt == null) {
        return -1;
      }

      return -a.user.user.value.lastSeenAt!.compareTo(
        b.user.user.value.lastSeenAt!,
      );
    });

    status.value = RxStatus.success();

    // for (var e in accounts) {
    //   if (!_userSubscriptions.containsKey(e.id)) {
    //     final user = await _userService.get(e.id);
    //     if (user != null) {
    //       _userSubscriptions[user.id]?.cancel();
    //       _userSubscriptions[user.id] = user.updates.listen((event) {});
    //     }
    //   }
    // }
  }

  @override
  void onClose() {
    for (var e in _userSubscriptions.values) {
      e.cancel();
    }
    _userSubscriptions.clear();

    super.onClose();
  }

  Future<void> delete(Account account) async {
    await _authService.deleteAccount(account);

    if (_authService.userId == account.myUser.id) {
      final next = accounts.skip(1);

      if (next.isEmpty) {
        router.go(await _authService.logout());
      } else {
        await switchTo(next.first.account);
      }
    }
  }

  FutureOr<RxUser?> getUser(UserId id) => _userService.get(id);

  Future<void> switchTo(Account? account) async {
    router.go(Routes.nowhere);

    try {
      if (account == null) {
        await _authService.register();
      } else {
        await _authService.signInWith(account.credentials);
      }
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 1000)).then((v) {
        MessagePopup.error(e);
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));

    router.home();
  }

  AccountsViewStage fallbackStage = AccountsViewStage.signUp;

  UserCredential? credential;
  OAuthProvider? oAuthProvider;

  Future<void> continueWithGoogle() async {
    fallbackStage = stage.value;
    oAuthProvider = OAuthProvider.google;
    stage.value = AccountsViewStage.oauth;

    if (kDebugMode) {
      try {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');

        final auth = FirebaseAuth.instanceFor(app: router.firebase!);

        if (PlatformUtils.isWeb) {
          credential = await auth.signInWithPopup(googleProvider);
        } else {
          credential = await auth.signInWithProvider(googleProvider);
        }

        await registerWithCredentials(credential!);
      } catch (_) {
        stage.value = fallbackStage;
      }

      return;
    }

    try {
      final googleUser =
          await GoogleSignIn(clientId: Config.googleClientId).signIn();

      final googleAuth = await googleUser?.authentication;

      if (googleAuth != null) {
        final creds = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final auth = FirebaseAuth.instanceFor(app: router.firebase!);

        credential = await auth.signInWithCredential(creds);

        await registerWithCredentials(credential!);
      }
    } catch (_) {
      stage.value = fallbackStage;
    }
  }

  Future<void> continueWithApple() async {
    fallbackStage = stage.value;
    oAuthProvider = OAuthProvider.apple;
    stage.value = AccountsViewStage.oauth;

    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');

      final auth = FirebaseAuth.instanceFor(app: router.firebase!);

      if (PlatformUtils.isWeb) {
        credential = await auth.signInWithPopup(appleProvider);
      } else {
        credential = await auth.signInWithProvider(appleProvider);
      }

      await registerWithCredentials(credential!);
    } catch (_) {
      stage.value = fallbackStage;
    }
  }

  Future<void> continueWithGitHub() async {
    fallbackStage = stage.value;
    oAuthProvider = OAuthProvider.github;
    stage.value = AccountsViewStage.oauth;

    try {
      final githubProvider = GithubAuthProvider();
      githubProvider.addScope('email');

      final auth = FirebaseAuth.instanceFor(app: router.firebase!);

      if (PlatformUtils.isWeb) {
        credential = await auth.signInWithPopup(githubProvider);
      } else {
        credential = await auth.signInWithProvider(githubProvider);
      }

      await registerWithCredentials(credential!);
    } catch (_) {
      stage.value = fallbackStage;
    }
  }

  Future<void> registerWithCredentials(
    UserCredential credential, [
    bool ignore = false,
  ]) async {
    print(
      '[OAuth] Registering with the provided `UserCredential`:\n\n$credential\n\n',
    );

    if (!ignore) {
      if (fallbackStage == AccountsViewStage.signUp &&
          credential.additionalUserInfo?.isNewUser == false) {
        stage.value = AccountsViewStage.oauthOccupied;
        return;
      } else if (fallbackStage == AccountsViewStage.signIn &&
          (credential.additionalUserInfo?.isNewUser == true || true)) {
        stage.value = AccountsViewStage.oauthNoUser;
        return;
      }
    }

    router.directLink = false;
    router.validateEmail = false;
    router.noIntroduction = false;
    router.signUp = true;

    await switchTo(null);
    // _redirect();

    while (!Get.isRegistered<MyUserService>()) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    final MyUserService myUserService = Get.find();

    if (credential.user?.displayName != null) {
      try {
        await myUserService
            .updateUserName(UserName(credential.user!.displayName!));
      } catch (e) {
        print('[OAuth] Unable to `updateUserName`: ${e.toString()}');
      }
    }

    if (credential.user?.email != null) {
      try {
        await myUserService.addUserEmail(UserEmail(credential.user!.email!));
      } catch (e) {
        print('[OAuth] Unable to `addUserEmail`: ${e.toString()}');
      }
    }

    if (credential.user?.phoneNumber != null) {
      try {
        await myUserService
            .addUserPhone(UserPhone(credential.user!.phoneNumber!));
      } catch (e) {
        print('[OAuth] Unable to `addUserPhone`: ${e.toString()}');
      }
    }

    if (credential.user?.photoURL != null) {
      try {
        final Response data = await (await PlatformUtils.dio).get(
          credential.user!.photoURL!,
          options: Options(responseType: ResponseType.bytes),
        );

        if (data.data != null && data.statusCode == 200) {
          var type = MimeResolver.lookup(
            '${DateTime.now()}.jpg',
            headerBytes: data.data,
          );

          final file = NativeFile(
            name: '${DateTime.now()}.jpg',
            size: (data.data as Uint8List).length,
            bytes: data.data,
            mime: type != null ? MediaType.parse(type) : null,
          );

          await myUserService.updateAvatar(file);
          await myUserService.updateCallCover(file);
        }
      } catch (e) {
        print('[OAuth] Unable to `updateAvatar`: ${e.toString()}');
      }
    }
  }

  // void _redirect() {
  //   router.home();
  // }
}

enum OAuthProvider {
  apple,
  google,
  github,
}

extension on AccountsViewStage {
  bool get registering => switch (this) {
        AccountsViewStage.signIn ||
        AccountsViewStage.signInWithPassword ||
        AccountsViewStage.signInWithEmail ||
        AccountsViewStage.signInWithEmailCode ||
        // AccountsViewStage.signInWithEmailOccupied ||
        AccountsViewStage.signInWithPhone ||
        AccountsViewStage.signInWithPhoneCode ||
        // AccountsViewStage.signInWithPhoneOccupied ||
        AccountsViewStage.signInWithQrScan ||
        AccountsViewStage.signInWithQrShow =>
          false,
        (_) => true,
      };
}

class AccountWithUser {
  const AccountWithUser(this.account, this.user);

  final Account account;
  final RxUser user;

  UserId get id => account.myUser.id;
  MyUser get myUser => account.myUser;
}
