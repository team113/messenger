import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show DeleteMyUserException;
import '/ui/widget/text_field.dart';

class ConfirmDeleteController extends GetxController {
  ConfirmDeleteController(this._myUserService, this._authService);

  late final TextFieldState code = TextFieldState(
    onChanged: (_) {
      code.error.value = null;
      password.error.value = null;
    },
  );

  late final TextFieldState password = TextFieldState(
    onChanged: (_) {
      code.error.value = null;
      password.error.value = null;
    },
  );

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  final AuthService _authService;
  final MyUserService _myUserService;

  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    if (myUser.value?.emails.confirmed.isNotEmpty == true) {
      sendConfirmationCode();
    }

    super.onInit();
  }

  Future<void> sendConfirmationCode() async {
    await _authService.createConfirmationCode();
  }

  Future<void> deleteAccount() async {
    code.error.value = null;
    password.error.value = null;

    try {
      await _myUserService.deleteMyUser(
        confirmation: code.text.isNotEmpty ? ConfirmationCode(code.text) : null,
        password: password.text.isNotEmpty ? UserPassword(password.text) : null,
      );
    } on DeleteMyUserException catch (e) {
      code.error.value = e.toMessage();
      password.error.value = e.toMessage();
    } catch (e) {
      code.error.value = 'err_data_transfer'.l10n;
      password.error.value = 'err_data_transfer'.l10n;
    }
  }
}
