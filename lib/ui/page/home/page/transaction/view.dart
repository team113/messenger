import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';

import 'controller.dart';

class TransactionView extends StatelessWidget {
  const TransactionView(this.id, {super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      tag: id,
      init: TransactionController(id, Get.find(), Get.find()),
      builder: (TransactionController c) {
        if (c.transaction.value == null) {
          return const Scaffold(
            appBar: CustomAppBar(leading: [StyledBackButton()]),
            body: Center(child: CustomProgressIndicator()),
          );
        }

        final Transaction e = c.transaction.value!;

        return Scaffold(
          appBar: const CustomAppBar(
            title: Text('Transaction'),
            leading: [StyledBackButton()],
          ),
          body: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Номер: ${e.id}'),
                  Text('Дата: ${e.at}'),
                  const Text('Способ: SWIFT transfet'),
                  Text('Сумма: ${e.amount.abs()}'),
                  Text('Статус: ${e.status.name}'),
                  const Text('Идентификатор мерчанта: ...'),
                  const Text('Фатура: ...'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
