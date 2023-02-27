import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';

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
            // actions: [
            //   Container(
            //     padding: const EdgeInsets.only(right: 16),
            //     child: SvgLoader.asset('assets/icons/transaction_in.svg'),
            //   ),
            // ],
          ),
          body: Center(
            child: ListView(
              shrinkWrap: true,
              children: [
                Block(
                  title: 'Транзакция',
                  children: [
                    _padding(
                      CopyableTextField(
                        label: 'Номер',
                        state: TextFieldState(text: e.id),
                        copy: e.id,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      IgnorePointer(
                        child: ReactiveTextField(
                          label: 'Дата',
                          state: TextFieldState(text: e.at.toString()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      IgnorePointer(
                        child: ReactiveTextField(
                          label: 'Способ',
                          state: TextFieldState(text: 'SWIFT transfer'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      IgnorePointer(
                        child: ReactiveTextField(
                          label: 'Сумма',
                          state: TextFieldState(text: '${e.amount.abs()}'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      IgnorePointer(
                        child: ReactiveTextField(
                          label: 'Статус',
                          state: TextFieldState(
                            text: e.status.name.capitalizeFirst,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      IgnorePointer(
                        child: ReactiveTextField(
                          label: 'Идентификатор мерчанта',
                          state: TextFieldState(text: '...'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      IgnorePointer(
                        child: ReactiveTextField(
                          label: 'Фактура',
                          state: TextFieldState(text: '...'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);
}
