import 'dart:async';

import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show DeleteMyUserException;
import '/ui/widget/text_field.dart';

/// [ConfirmDeleteView] controller.
class ConfirmDeleteController extends GetxController {
  ConfirmDeleteController(this._myUserService, this._authService);

  /// [TextFieldState] of the [ConfirmationCode] input.
  late final TextFieldState code = TextFieldState(
    onChanged: (_) {
      code.error.value = null;
      password.error.value = null;
    },
  );

  /// [TextFieldState] of the [UserPassword] input.
  late final TextFieldState password = TextFieldState(
    onChanged: (_) {
      code.error.value = null;
      password.error.value = null;
    },
  );

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Timeout of a [sendConfirmationCode] next invoke attempt.
  final RxInt resendEmailTimeout = RxInt(0);

  /// [AuthService] to [sendConfirmationCode].
  final AuthService _authService;

  /// [MyUserService] maintaining the [MyUser].
  final MyUserService _myUserService;

  /// [Timer] used to disable resend code button [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    if (myUser.value?.emails.confirmed.isNotEmpty == true) {
      sendConfirmationCode();
    }

    super.onInit();
  }

  /// Sends a [ConfirmationCode] to confirm the [deleteAccount].
  Future<void> sendConfirmationCode() async {
    _setResendEmailTimer();

    try {
      await _authService.createConfirmationCode();
    } catch (e) {
      code.resubmitOnError.value = true;
      code.error.value = 'err_data_transfer'.l10n;
      _setResendEmailTimer(false);
      rethrow;
    }
  }

  /// Deletes the currently authenticated [MyUser] account.
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
    } on FormatException {
      code.error.value = 'err_wrong_code'.l10n;
      password.error.value = 'err_wrong_code'.l10n;
    } catch (e) {
      code.error.value = 'err_data_transfer'.l10n;
      password.error.value = 'err_data_transfer'.l10n;
      rethrow;
    }
  }

  /// Starts or stops the [_resendEmailTimer] based on [enabled] value.
  void _setResendEmailTimer([bool enabled = true]) {
    if (enabled) {
      resendEmailTimeout.value = 30;
      _resendEmailTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          resendEmailTimeout.value--;
          if (resendEmailTimeout.value <= 0) {
            resendEmailTimeout.value = 0;
            _resendEmailTimer?.cancel();
            _resendEmailTimer = null;
          }
        },
      );
    } else {
      resendEmailTimeout.value = 0;
      _resendEmailTimer?.cancel();
      _resendEmailTimer = null;
    }
  }
}
