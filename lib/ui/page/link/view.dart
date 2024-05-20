import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/widget/direct_link.dart';
import 'package:messenger/ui/widget/modal_popup.dart';

import '../../../l10n/l10n.dart';
import '../home/widget/app_bar.dart';
import '../home/widget/block.dart';
import 'controller.dart';

class LinkView extends StatelessWidget {
  const LinkView({super.key});

  /// Displays a [LinkView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const LinkView());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: LinkController(Get.find(), Get.find()),
      builder: (LinkController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(text: 'label_your_direct_link'.l10n),
            Flexible(
              child: ListView(
                padding: ModalPopup.padding(context),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );

        return Scaffold(
          appBar: CustomAppBar(title: Text('btn_share'.l10n)),
          body: Center(
            child: ListView(
              shrinkWrap: true,
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
          ),
        );
      },
    );
  }
}
