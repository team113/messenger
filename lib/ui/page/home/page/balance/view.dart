import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/domain/service/partner.dart';
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
