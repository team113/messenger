import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/service/my_user.dart';

enum ConfirmDeleteScreen { password, email }

class ConfirmDeleteController extends GetxController {
  ConfirmDeleteController(this._myUserService);

  final Rx<ConfirmDeleteScreen> screen = Rx(ConfirmDeleteScreen.email);

  final MyUserService _myUserService;

  Rx<MyUser?> get myUser => _myUserService.myUser;
}
