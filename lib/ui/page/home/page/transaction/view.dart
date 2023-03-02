import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/file.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';

import 'controller.dart';
import 'widget/downloadable_file.dart';

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

        final ThemeData theme = Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                // floatingLabelAlignment: FloatingLabelAlignment.center,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
                  // borderSide: const BorderSide(color: Colors.transparent),
                ),
              ),
        );

        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('Transaction'),
            leading: const [StyledBackButton()],
            actions: [
              Container(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.line_style,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          body: Center(
            child: ListView(
              children: [
                Block(
                  title: 'Details',
                  children: [
                    _padding(
                      CopyableTextField(
                        label: 'Номер',
                        state: TextFieldState(text: e.id),
                        copy: e.id,
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      CopyableTextField(
                        label: 'Дата',
                        state: TextFieldState(text: e.at.toString()),
                        copy: e.at.toString(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      CopyableTextField(
                        label: 'Способ',
                        state: TextFieldState(text: 'SWIFT transfer'),
                        copy: 'SWIFT transfer',
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      CopyableTextField(
                        label: 'Сумма',
                        state: TextFieldState(text: '${e.amount.abs()}'),
                        copy: '${e.amount.abs()}',
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      CopyableTextField(
                        label: 'Статус',
                        state:
                            TextFieldState(text: e.status.name.capitalizeFirst),
                        copy: e.status.name.capitalizeFirst,
                      ),
                    ),
                    // const SizedBox(height: 4),
                    // _padding(
                    //   Theme(
                    //     data: theme,
                    //     child: IgnorePointer(
                    //       child: ReactiveTextField(
                    //         label: 'Идентификатор мерчанта',
                    //         state: TextFieldState(text: '...'),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 4),
                    // _padding(
                    //   Theme(
                    //     data: theme,
                    //     child: IgnorePointer(
                    //       child: ReactiveTextField(
                    //         label: 'Фактура',
                    //         state: TextFieldState(text: '...'),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                Block(
                  title: 'Actions',
                  children: [
                    // FieldButton(
                    //   onPressed: () {},
                    //   text: 'Invoice №12353519',
                    //   style: TextStyle(
                    //       color: Theme.of(context).colorScheme.secondary),
                    //   trailing: Icon(
                    //     Icons.download_outlined,
                    //     color: Theme.of(context).colorScheme.secondary,
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    DownloadableFile(
                      FileAttachment(
                        id: const AttachmentId('id'),
                        original: StorageFile(
                          relativeRef: 'resume.pdf',
                          size: 200000,
                        ),
                        filename: 'resume.pdf',
                      ),
                    ),
                    // FieldButton(
                    //   onPressed: () {},
                    //   text: 'Download invoice',
                    // ),
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
