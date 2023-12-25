import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/widget/modal_popup.dart';

import 'controller.dart';

class AddInfoView extends StatelessWidget {
  const AddInfoView({super.key});

  /// Displays a [AddInfoView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      child: const AddInfoView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: AddInfoController(),
      builder: (AddInfoController c) {
        return Container();
      },
    );
  }
}
