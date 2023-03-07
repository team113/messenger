// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

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
