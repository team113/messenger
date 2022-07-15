import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/provider/gql/exceptions.dart' show UpdateUserPasswordException;
import '/ui/widget/text_field.dart';

class IntroductionController extends GetxController {
  IntroductionController(this._myUser, {this.pop});

  final RxBool displayPassword = RxBool(false);
  final RxBool displaySuccess = RxBool(false);
  final Function()? pop;

  final MyUserService _myUser;

  late final TextFieldState num;
  late final TextFieldState password;
  late final TextFieldState repeat;

  final RxBool obscurePassword = RxBool(true);
  final RxBool obscureRepeat = RxBool(true);

  Rx<MyUser?> get myUser => _myUser.myUser;

  @override
  void onInit() {
    num = TextFieldState(
      text: _myUser.myUser.value!.num.val
          .replaceAllMapped(RegExp(r'.{4}'), (match) => '${match.group(0)} '),
      editable: false,
    );

    password = TextFieldState(
      onChanged: (s) {
        password.error.value = null;
        repeat.error.value = null;

        if (s.text.isEmpty) {
          return;
        }

        try {
          UserPassword(s.text);

          if (repeat.text != password.text && repeat.isValidated) {
            repeat.error.value = 'err_passwords_mismatch'.tr;
          }
        } on FormatException {
          if (s.text.isEmpty) {
            s.error.value = 'err_password_empty'.tr;
          } else {
            s.error.value = 'err_password_incorrect'.tr;
          }
        }
      },
    );

    repeat = TextFieldState(
      onChanged: (s) {
        password.error.value = null;
        repeat.error.value = null;

        if (s.text.isEmpty) {
          return;
        }

        try {
          if (s.text.isEmpty) {
            throw const FormatException();
          }

          UserPassword(s.text);

          if (repeat.text != password.text && password.isValidated) {
            repeat.error.value = 'err_passwords_mismatch'.tr;
          }
        } on FormatException {
          if (s.text.isEmpty) {
            s.error.value = 'err_repeat_password_empty'.tr;
          } else {
            s.error.value = 'err_password_incorrect'.tr;
          }
        }
      },
    );

    super.onInit();
  }

  Future<void> setPassword() async {
    if (password.error.value != null ||
        repeat.error.value != null ||
        !password.editable.value ||
        !repeat.editable.value) {
      return;
    }

    if (password.text.isEmpty) {
      password.error.value = 'err_password_empty'.tr;
      return;
    }

    if (repeat.text.isEmpty) {
      repeat.error.value = 'err_repeat_password_empty'.tr;
      return;
    }

    password.editable.value = false;
    repeat.editable.value = false;
    password.status.value = RxStatus.loading();
    repeat.status.value = RxStatus.loading();
    try {
      await _myUser.updateUserPassword(newPassword: UserPassword(repeat.text));
      password.status.value = RxStatus.success();
      repeat.status.value = RxStatus.success();
      await Future.delayed(1.seconds);
      displaySuccess.value = true;
    } on UpdateUserPasswordException catch (e) {
      repeat.error.value = e.toMessage();
    } catch (e) {
      repeat.error.value = e.toString();
      rethrow;
    } finally {
      password.status.value = RxStatus.empty();
      repeat.status.value = RxStatus.empty();
      password.editable.value = true;
      repeat.editable.value = true;
    }
  }
}
