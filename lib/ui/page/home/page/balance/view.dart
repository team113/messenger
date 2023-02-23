import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      init: BalanceProviderController(),
      builder: (BalanceProviderController c) {
        return Obx(() {
          if (c.webController.value != null) {
            return Scaffold(
              appBar: CustomAppBar(
                title: Text(provider.toString()),
                leading: const [StyledBackButton()],
              ),
              body: WebViewWidget(controller: c.webController.value!),
            );
          }

          return Scaffold(
            body: Center(
              child: Text(provider.toString()),
            ),
          );
        });
      },
    );
  }
}
