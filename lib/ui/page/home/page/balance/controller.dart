import 'dart:ui';

import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class BalanceProviderController extends GetxController {
  final Rx<WebViewController?> webController = Rx(null);

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
}
