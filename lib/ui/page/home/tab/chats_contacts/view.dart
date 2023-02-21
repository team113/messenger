import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/page/home/tab/chats/controller.dart';
import '/ui/page/home/tab/contacts/view.dart';

import 'controller.dart';

class ChatsContactsTabView extends StatelessWidget {
  const ChatsContactsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ChatsContactsTabController(),
      builder: (ChatsContactsTabController c) {
        return Obx(() {
          if (c.switched.value) {
            return ContactsTabView(onSwitched: c.switched.toggle);
          }

          return ChatsTabView(onSwitched: c.switched.toggle);
        });
      },
    );
  }
}
