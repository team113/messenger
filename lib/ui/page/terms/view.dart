import 'package:flutter/material.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';

class TermsAndConditionsView extends StatelessWidget {
  const TermsAndConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        leading: [StyledBackButton()],
        title: Text('T & C'),
        actions: [SizedBox(width: 36)],
      ),
      body: Center(child: Text('Conditions are good, don\'t worry.')),
    );
  }
}
