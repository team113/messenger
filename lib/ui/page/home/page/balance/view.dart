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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'controller.dart';

class BalanceProviderView extends StatelessWidget {
  const BalanceProviderView(this.provider, {super.key});

  final BalanceProvider provider;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: BalanceProviderController(Get.find()),
      builder: (BalanceProviderController c) {
        return Obx(() {
          if (c.webController.value != null) {
            return Scaffold(
              appBar: CustomAppBar(
                title: Text(provider.toString()),
                leading: const [StyledBackButton()],
                actions: [
                  IconButton(
                    onPressed: () => c.add(
                      OutgoingTransaction(
                        amount: -100,
                        at: DateTime.now(),
                      ),
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    onPressed: () => c.add(
                      IncomingTransaction(
                        amount: 100,
                        at: DateTime.now(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              body: WebViewWidget(controller: c.webController.value!),
            );
          }

          return Scaffold(
            appBar: CustomAppBar(
              title: Text(provider.toString()),
              leading: const [StyledBackButton()],
              actions: [
                IconButton(
                  onPressed: () => c.add(
                    OutgoingTransaction(
                      amount: -100,
                      at: DateTime.now(),
                    ),
                  ),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: () => c.add(
                    IncomingTransaction(
                      amount: 100,
                      at: DateTime.now(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            body: Center(
              child: Text(provider.toString()),
            ),
          );
        });
      },
    );
  }
}
