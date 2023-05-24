import 'package:get/get.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/ui/widget/text_field.dart';

enum GetPaidMode { user, users, contacts }

class GetPaidController extends GetxController {
  GetPaidController(
    this._myUserService, {
    this.mode = GetPaidMode.users,
    this.user,
  });

  final GetPaidMode mode;
  final RxUser? user;

  late final TextFieldState messageCost;
  late final TextFieldState callsCost;

  final RxBool verified = RxBool(false);

  final MyUserService _myUserService;
  Worker? _myUserWorker;

  /// Returns current [MyUser] value.
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    _fetchUser();
    super.onInit();
  }

  @override
  void onClose() {
    _myUserWorker?.dispose();
    super.onClose();
  }

  /// Fetches the [user] value from the [_userService].
  void _fetchUser() {
    final int messages;
    final int calls;

    switch (mode) {
      case GetPaidMode.user:
        messages = user!.user.value.messageCost;
        calls = user!.user.value.callCost;
        break;

      case GetPaidMode.users:
        messages = 0;
        calls = 0;
        break;

      case GetPaidMode.contacts:
        messages = 0;
        calls = 0;
        break;
    }

    messageCost = TextFieldState(
      text: messages == 0 ? null : '${messages.toString()}.00',
      onChanged: (s) {
        user?.user.value.messageCost = int.tryParse(s.text) ?? 0;
        user?.dialog.value?.chat.refresh();
      },
    );

    messageCost.isFocused.listen((b) {
      if (b) {
        messageCost.unchecked = messageCost.text.replaceAll('.00', '');
      } else if (messageCost.text.isNotEmpty) {
        if (!messageCost.text.contains('.')) {
          messageCost.text = '${messageCost.text}.00';
        }
      }
    });

    callsCost = TextFieldState(
      text: calls == 0 ? null : '${calls.toString()}.00',
      onChanged: (s) {
        user?.user.value.callCost = int.tryParse(s.text) ?? 0;
        user?.dialog.value?.chat.refresh();
      },
    );

    callsCost.isFocused.listen((b) {
      if (b) {
        callsCost.unchecked = callsCost.text.replaceAll('.00', '');
      } else if (callsCost.text.isNotEmpty) {
        if (!callsCost.text.contains('.')) {
          callsCost.text = '${callsCost.text}.00';
        }
      }
    });

    verified.value =
        _myUserService.myUser.value?.emails.confirmed.isNotEmpty == true;

    _myUserWorker = ever(
      _myUserService.myUser,
      (MyUser? v) {
        verified.value = v?.emails.confirmed.isNotEmpty == true;
      },
    );
  }
}
