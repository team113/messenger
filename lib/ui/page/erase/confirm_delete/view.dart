import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/widget/modal_popup.dart';
import 'controller.dart';

class ConfirmDeleteView extends StatelessWidget {
  const ConfirmDeleteView({super.key});

  /// Displays a [ConfirmDeleteView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const ConfirmDeleteView());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ConfirmDeleteController(Get.find()),
      builder: (ConfirmDeleteController c) {
        return Obx(() {
          final List<Widget> children = [];

          if (c.myUser.value?.emails.confirmed.isNotEmpty == true) {}

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalPopupHeader(text: ''),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: children,
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
