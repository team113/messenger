import 'dart:ui';

import 'package:get/get.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/domain/service/balance.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class BalanceProviderController extends GetxController {
  BalanceProviderController(this._balanceService);

  final Rx<WebViewController?> webController = Rx(null);

  final BalanceService _balanceService;

  @override
  void onReady() async {
    try {
      final WebViewController controller =
          WebViewController.fromPlatformCreationParams(
        const PlatformWebViewControllerCreationParams(),
      );

      controller.loadRequest(Uri.parse('https://flutter.dev'));

      webController.value = controller;
    } catch (e) {
      print(e);
      webController.value = null;
    }
  }

  void add(Transaction transaction) {
    _balanceService.add(transaction);
  }
}
