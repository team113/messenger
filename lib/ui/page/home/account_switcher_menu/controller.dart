import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../../../api/backend/schema.graphql.dart';
import '../../../../domain/model/my_user.dart';
import '../../../../domain/model/user.dart';
import '../../../../domain/service/auth.dart';
import '../../../../domain/service/my_user.dart';
import '../../../../l10n/l10n.dart';
import '../../../widget/text_field.dart';
import '../tab/menu/accounts/controller.dart';

class AccountSwitcherMenuController extends AccountsController {
  AccountSwitcherMenuController(this._myUserService, AuthService _authService)
    : super(_myUserService, _authService);

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// [MyUserService] to obtain [accounts] and [me].
  final MyUserService _myUserService;

  /// [MyUser.status] field state.
  late final TextFieldState status = TextFieldState(
    text: myUser.value?.status?.val,
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.isNotEmpty) {
        try {
          UserTextStatus(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }
      }

      final UserTextStatus? status = UserTextStatus.tryParse(s.text);

      try {
        await updateUserStatus(status);
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
      }
    },
  );

  /// Updates or resets [MyUser.status] field for the authenticated [MyUser].
  Future<void> updateUserStatus(UserTextStatus? status) async {
    await _myUserService.updateUserStatus(status);
  }

  /// Toggles [MyUser.presence] between [Presence.present] and [Presence.away].
  void togglePresence() {
    Presence newPresence;
    if (myUser.value?.presence == Presence.present) {
      newPresence = Presence.away;
    } else {
      newPresence = Presence.present;
    }
    _myUserService.updateUserPresence(newPresence);
  }
}
