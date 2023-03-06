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
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';
import 'support/view.dart';
import 'widget/downloadable_button.dart';
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

        const spacer =
            TableRow(children: [SizedBox(height: 16), SizedBox(height: 16)]);

        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('Transaction'),
            leading: const [StyledBackButton()],
            // onBottom: context.isNarrow ? () {} : null,
            actions: [
              WidgetButton(
                onPressed: () => ContactSupportView.show(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.support_agent,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  // child: Stack(
                  //   alignment: Alignment.center,
                  //   children: [
                  //     SvgLoader.asset(
                  //       'assets/icons/balance.svg',
                  //       width: 30,
                  //       height: 30,
                  //     ),
                  //     const Positioned.fill(
                  //       child: Center(
                  //         child: Text(
                  //           '100',
                  //           style: TextStyle(color: Colors.white, fontSize: 12),
                  //           textAlign: TextAlign.center,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ),
              ),
              // Container(
              //   padding: const EdgeInsets.only(right: 16),
              //   child: Icon(
              //     Icons.line_style,
              //     color: Theme.of(context).colorScheme.secondary,
              //   ),
              // ),
            ],
          ),
          body: Center(
            child: ListView(
              shrinkWrap: !context.isNarrow,
              children: [
                const SizedBox(height: 4),
                Block(
                  title: 'Details',
                  children: [
                    _padding(
                      CopyableTextField(
                        label: 'Number',
                        state: TextFieldState(text: e.id),
                        copy: e.id,
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _padding(
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFFD0D0D0)),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            margin: const EdgeInsets.only(top: 5),
                            padding: const EdgeInsets.fromLTRB(21, 16, 21, 16),
                            child: DefaultTextStyle(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 15,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w300,
                                  ),
                              child: Table(
                                defaultColumnWidth:
                                    const IntrinsicColumnWidth(),
                                columnWidths: const {
                                  0: IntrinsicColumnWidth(),
                                  1: FlexColumnWidth(),
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      Text(
                                        'Дата: ',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      Text('${e.at}'),
                                    ],
                                  ),
                                  spacer,
                                  TableRow(
                                    children: [
                                      Text(
                                        'Способ: ',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      const Text('SWIFT Transfer'),
                                    ],
                                  ),
                                  spacer,
                                  TableRow(
                                    children: [
                                      Text(
                                        'Сумма: ',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      Text('${e.amount.abs()}'),
                                    ],
                                  ),
                                  spacer,
                                  TableRow(
                                    children: [
                                      Text(
                                        'Cтатус: ',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      Text('${e.status.name.capitalizeFirst}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              color: Colors.white,
                              child: Text(
                                'Details',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w300,
                                      color: const Color(0xFFC4C4C4),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // _padding(
                    //   Stack(
                    //     children: [
                    //       Container(
                    //         decoration: BoxDecoration(
                    //           border:
                    //               Border.all(color: const Color(0xFFD0D0D0)),
                    //           borderRadius: BorderRadius.circular(25),
                    //         ),
                    //         margin: const EdgeInsets.only(top: 5),
                    //         padding: const EdgeInsets.fromLTRB(21, 16, 21, 16),
                    //         child: DefaultTextStyle(
                    //           style: Theme.of(context)
                    //               .textTheme
                    //               .bodyMedium!
                    //               .copyWith(
                    //                 fontSize: 15,
                    //                 color: Colors.black,
                    //                 fontWeight: FontWeight.w300,
                    //               ),
                    //           child: Column(
                    //             children: [
                    //               Row(
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   Text(
                    //                     'Дата: ',
                    //                     style: TextStyle(
                    //                       color: Theme.of(context)
                    //                           .colorScheme
                    //                           .primary,
                    //                     ),
                    //                   ),
                    //                   Expanded(child: Text('${e.at}')),
                    //                 ],
                    //               ),
                    //               const SizedBox(height: 16),
                    //               Row(
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   Text(
                    //                     'Способ: ',
                    //                     style: TextStyle(
                    //                       color: Theme.of(context)
                    //                           .colorScheme
                    //                           .primary,
                    //                     ),
                    //                   ),
                    //                   const Expanded(
                    //                     child: Text('SWIFT transfer'),
                    //                   ),
                    //                 ],
                    //               ),
                    //               const SizedBox(height: 16),
                    //               Row(
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   Text(
                    //                     'Cумма: ',
                    //                     style: TextStyle(
                    //                       color: Theme.of(context)
                    //                           .colorScheme
                    //                           .primary,
                    //                     ),
                    //                   ),
                    //                   Expanded(
                    //                     child: Text('${e.amount.abs()}'),
                    //                   ),
                    //                 ],
                    //               ),
                    //               const SizedBox(height: 16),
                    //               Row(
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   Text(
                    //                     'Статус: ',
                    //                     style: TextStyle(
                    //                       color: Theme.of(context)
                    //                           .colorScheme
                    //                           .primary,
                    //                     ),
                    //                   ),
                    //                   Expanded(
                    //                     child: Text(
                    //                       '${e.status.name.capitalizeFirst}',
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //       Positioned(
                    //         left: 18,
                    //         child: Container(
                    //           padding:
                    //               const EdgeInsets.symmetric(horizontal: 4),
                    //           color: Colors.white,
                    //           child: Text(
                    //             'Details',
                    //             style: Theme.of(context)
                    //                 .textTheme
                    //                 .headlineSmall
                    //                 ?.copyWith(
                    //                   fontSize: 11,
                    //                   fontWeight: FontWeight.w300,
                    //                   color: const Color(0xFFC4C4C4),
                    //                 ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
//                     _padding(
//                       ReactiveTextField(
//                         label: 'Details',
//                         maxLines: null,
//                         state: TextFieldState(
//                           editable: false,
//                           text: '''Дата: ${e.at}

// Cпособ: SWIFT transfer

// Сумма: ${e.amount.abs()}

// Статус: ${e.status.name.capitalizeFirst}''',
//                         ),
//                       ),
//                     ),

                    // const SizedBox(height: 4),
                    // _padding(
                    //   CopyableTextField(
                    //     label: 'Дата',
                    //     state: TextFieldState(text: e.at.toString()),
                    //     copy: e.at.toString(),
                    //   ),
                    // ),
                    // const SizedBox(height: 4),
                    // _padding(
                    //   CopyableTextField(
                    //     label: 'Способ',
                    //     state: TextFieldState(text: 'SWIFT transfer'),
                    //     copy: 'SWIFT transfer',
                    //   ),
                    // ),
                    // const SizedBox(height: 4),
                    // _padding(
                    //   CopyableTextField(
                    //     label: 'Сумма',
                    //     state: TextFieldState(text: '${e.amount.abs()}'),
                    //     copy: '${e.amount.abs()}',
                    //   ),
                    // ),
                    // const SizedBox(height: 4),
                    // _padding(
                    //   CopyableTextField(
                    //     label: 'Статус',
                    //     state:
                    //         TextFieldState(text: e.status.name.capitalizeFirst),
                    //     copy: e.status.name.capitalizeFirst,
                    //   ),
                    // ),
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
                    _padding(
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
                      // DownloadableButton(
                      //   FileAttachment(
                      //     id: const AttachmentId('id'),
                      //     original: StorageFile(
                      //       relativeRef: 'resume.pdf',
                      //       size: 200000,
                      //     ),
                      //     filename: 'resume.pdf',
                      //   ),
                      // ),
                      // FieldButton(
                      //   onPressed: () {},
                      //   text: 'Invoice №12353519',
                      //   style: TextStyle(
                      //     color: Theme.of(context).colorScheme.secondary,
                      //   ),
                      //   trailing: Transform.scale(
                      //     scale: 1.15,
                      //     child: SvgLoader.asset(
                      //       'assets/icons/download_contour.svg',
                      //       width: 18,
                      //       height: 18,
                      //     ),
                      //   ),
                      // ),
                    ),
                    // if (e.status != TransactionStatus.completed)
                    //   _padding(
                    //     FieldButton(
                    //       onPressed: () {},
                    //       text: 'Support',
                    //       style: TextStyle(
                    //         color: Theme.of(context).colorScheme.secondary,
                    //       ),
                    //       trailing: Transform.scale(
                    //         scale: 1.15,
                    //         child: SvgLoader.asset(
                    //           'assets/icons/download_contour.svg',
                    //           width: 18,
                    //           height: 18,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // const SizedBox(height: 8),
                    // DownloadableFile(
                    //   FileAttachment(
                    //     id: const AttachmentId('id'),
                    //     original: StorageFile(
                    //       relativeRef: 'resume.pdf',
                    //       size: 200000,
                    //     ),
                    //     filename: 'resume.pdf',
                    //   ),
                    // ),
                    // FieldButton(
                    //   onPressed: () {},
                    //   text: 'Download invoice',
                    // ),
                  ],
                ),
                const SizedBox(height: 4),
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
