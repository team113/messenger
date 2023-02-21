import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';

import 'controller.dart';

class PublicsTabView extends StatelessWidget {
  const PublicsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: PublicsTabController(),
      builder: (PublicsTabController c) {
        return Scaffold(
          appBar: CustomAppBar(title: Text('label_tab_public'.l10n)),
          body: const Center(child: Text('Publics')),
        );
      },
    );
  }
}
