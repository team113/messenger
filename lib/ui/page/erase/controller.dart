import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

import '/domain/service/auth.dart';

/// Controller of the [Routes.erase] page.
class EraseController extends GetxController {
  EraseController(this._authService, this._myUserService);

  /// [TextFieldState] of a login text input.
  late final TextFieldState login = TextFieldState(
    onChanged: (s) => s.error.value = null,
    onSubmitted: (s) => password.focus.requestFocus(),
  );

  /// [TextFieldState] of a password text input.
  late final TextFieldState password = TextFieldState(
    onChanged: (s) => s.error.value = null,
    onSubmitted: (s) => signIn(),
  );

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [newPassword] should be obscured.
  final RxBool obscureNewPassword = RxBool(true);

  /// [AuthService] user for signing into an account.
  final AuthService _authService;

  /// [MyUserService] used to delete authorized [MyUser].
  final MyUserService? _myUserService;

  /// Returns the authorization status.
  Rx<RxStatus> get authStatus => _authService.status;

  /// Returns the authenticated [MyUser].
  Rx<MyUser?>? get myUser => _myUserService?.myUser;

  /// Signs in and redirects to the [Routes.erase] page.
  ///
  /// Username is [login]'s text and the password is [password]'s text.
  Future<void> signIn() async {
    UserLogin? userLogin;
    UserNum? num;
    UserEmail? email;
    UserPhone? phone;

    login.error.value = null;
    password.error.value = null;

    if (login.text.isEmpty) {
      password.error.value = 'err_incorrect_login_or_password'.l10n;
      password.unsubmit();
      return;
    }

    try {
      userLogin = UserLogin(login.text.toLowerCase());
    } catch (e) {
      // No-op.
    }

    try {
      num = UserNum(login.text);
    } catch (e) {
      // No-op.
    }

    try {
      email = UserEmail(login.text.toLowerCase());
    } catch (e) {
      // No-op.
    }

    try {
      phone = UserPhone(login.text);
    } catch (e) {
      // No-op.
    }

    if (password.text.isEmpty) {
      password.error.value = 'err_incorrect_login_or_password'.l10n;
      password.unsubmit();
      return;
    }

    if (userLogin == null && num == null && email == null && phone == null) {
      password.error.value = 'err_incorrect_login_or_password'.l10n;
      password.unsubmit();
      return;
    }

    try {
      login.status.value = RxStatus.loading();
      password.status.value = RxStatus.loading();

      await _authService.signIn(
        UserPassword(password.text),
        login: userLogin,
        num: num,
        email: email,
        phone: phone,
      );

      router.go(Routes.erase);
      router.tab = HomeTab.menu;
    } on FormatException {
      password.error.value = 'err_incorrect_login_or_password'.l10n;
    } on ConnectionException {
      password.unsubmit();
      password.error.value = 'err_data_transfer'.l10n;
    } catch (e) {
      password.unsubmit();
      password.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      login.status.value = RxStatus.empty();
      password.status.value = RxStatus.empty();
    }
  }

  /// Deletes [myUser]'s account.
  Future<void> deleteAccount() async {
    try {
      await _myUserService?.deleteMyUser();
      router.go(Routes.auth);
      router.tab = HomeTab.chats;
    } catch (_) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }
}
