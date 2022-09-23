import 'package:flutter/material.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';

class FinanceTabView extends StatelessWidget {
  const FinanceTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.from(
        context: context,
        title: const Text('Finance'),
      ),
      body: const Text('Finance'),
    );
  }
}
