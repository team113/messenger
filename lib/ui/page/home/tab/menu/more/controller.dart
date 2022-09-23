import 'package:get/get.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/tab/menu/confirm/view.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/web/web_utils.dart';

class MoreController extends GetxController {
  MoreController(this._authService, this._callService, this._myUserService);

  final AuthService _authService;
  final CallService _callService;
  final MyUserService _myUserService;

  /// Determines whether the [logout] action may be invoked or not.
  ///
  /// Shows a confirmation popup if there's any ongoing calls.
  Future<bool> confirmLogout() async {
    if (_callService.calls.isNotEmpty || WebUtils.containsCalls()) {
      if (await MessagePopup.alert('alert_are_you_sure_want_to_log_out'.l10n) !=
          true) {
        return false;
      }
    }

    // TODO: [MyUserService.myUser] might still be `null` here.
    if (_myUserService.myUser.value?.hasPassword != true) {
      if (await ConfirmLogoutView.show(router.context!) != true) {
        return false;
      }
    }

    return true;
  }

  /// Logs out the current session and go to the [Routes.auth] page.
  Future<String> logout() => _authService.logout();
}
