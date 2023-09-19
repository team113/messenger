import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';

class FaqView extends StatelessWidget {
  const FaqView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: FaqController(),
      builder: (FaqController c) {
        // final style = Theme.of(context).style;

        return Scaffold(
          appBar: const CustomAppBar(
            title: Text('Questions and answers'),
            leading: [StyledBackButton()],
          ),
          body: Center(
            child: ListView(
              shrinkWrap: !context.isNarrow,
              children: const [
                SizedBox(height: 4),
                Block(
                  title: 'Question?',
                  children: [Text('Answer')],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
