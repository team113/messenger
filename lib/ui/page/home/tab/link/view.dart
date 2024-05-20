import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/widget/direct_link.dart';

import '/l10n/l10n.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import 'controller.dart';

class LinkTabView extends StatelessWidget {
  const LinkTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: LinkTabController(Get.find(), Get.find()),
      builder: (LinkTabController c) {
        return Scaffold(
          appBar: CustomAppBar(title: Text('btn_share'.l10n)),
          body: ListView(
            children: [
              Block(
                title: 'label_your_direct_link'.l10n,
                children: [
                  Obx(() {
                    return DirectLinkField(
                      c.myUser.value?.chatDirectLink,
                      onSubmit: (s) async {
                        if (s == null) {
                          await c.deleteChatDirectLink();
                        } else {
                          await c.createChatDirectLink(s);
                        }
                      },
                      background: c.background.value,
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
