import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/service/my_user.dart';

class AccountsOverlayController extends GetxController {
  AccountsOverlayController(this._myUserService);

  final MyUserService _myUserService;
  Stopwatch? _startedAt;

  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    _scheduleRebuild();
    super.onInit();
  }

  void _scheduleRebuild() {
    if (isClosed) {
      return;
    }

    _startedAt ??= Stopwatch()..start();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_startedAt == null) {
        return;
      }

      // This should equal the duration of `AccountsOverlayView.show()`
      // transition so that any changes of `GlobalKey` are applied during that.
      if (_startedAt!.elapsedMilliseconds >= 300) {
        _startedAt?.stop();
        _startedAt = null;
        return;
      }

      refresh();
      _scheduleRebuild();
    });
  }
}
