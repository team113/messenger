import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../util/platform_utils.dart';
import '../../../../widget/animated_button.dart';
import '../../../../widget/context_menu/region.dart';
import '../../../../widget/text_field.dart';
import '../../../../widget/widget_button.dart';
import '../../widget/app_bar.dart';
import '../chat/message_field/view.dart';
import '/domain/service/balance.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/chat/widget/time_label.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';
import 'widget/transaction.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: TransactionsController(Get.find(), Get.find()),
      builder: (TransactionsController c) {
        return Obx(() {
          final List<Widget> children = [];

          // if (c.transactions.isNotEmpty) {
          //   children.add(TimeLabelWidget(c.transactions.first.at));
          // }

          final List<Transaction> transactions = [];
          for (var e in c.transactions) {
            if (c.includeHold.value && c.includeCompleted.value) {
              transactions.add(e);
            } else if (!c.includeHold.value && c.includeCompleted.value) {
              if (e.status == TransactionStatus.done) {
                transactions.add(e);
              }
            } else if (c.includeHold.value && !c.includeCompleted.value) {
              if (e.status == TransactionStatus.hold) {
                transactions.add(e);
              }
            } else if (!c.includeHold.value && !c.includeCompleted.value) {
              if (e.status != TransactionStatus.done &&
                  e.status != TransactionStatus.hold) {
                transactions.add(e);
              }
            }
          }

          for (int i = 0; i < transactions.length; ++i) {
            final Transaction e = transactions[i];

            Transaction? previous;
            if (i < transactions.length - 1) {
              previous = transactions[i + 1];
            }

            children.add(
              Center(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 1.5, 10, 1.5),
                  constraints: context.isNarrow
                      ? null
                      : const BoxConstraints(maxWidth: 400),
                  child: Obx(() {
                    return WidgetButton(
                      onPressed: c.expanded.value
                          ? null
                          : () {
                              if (c.ids.contains(e.id)) {
                                c.ids.remove(e.id);
                              } else {
                                c.ids.add(e.id);
                              }
                            },
                      child: TransactionWidget(
                        e,
                        id: '${10000000 + transactions.length - i - 1}',
                        expanded: c.expanded.value || c.ids.contains(e.id),
                      ),
                    );
                  }),
                ),
              ),
            );

            if (previous != null) {
              final DateTime a = e.at.toDay();
              final DateTime b = previous.at.toDay();

              if (a != b) {
                children.add(TimeLabelWidget(a));
              }
            }
          }

          if (c.transactions.isNotEmpty) {
            children.add(TimeLabelWidget(c.transactions.last.at));
          }

          return Scaffold(
            appBar: CustomAppBar(
              leading: const [StyledBackButton()],
              title: Text('btn_transactions'.l10n),
              actions: [
                Text(
                  '\$ ${c.hold.value.toInt().withSpaces}',
                  style: style.fonts.small.regular.onBackground.copyWith(
                    color: style.colors.secondary,
                  ),
                ),
                AnimatedButton(
                  onPressed: () {
                    c.ids.clear();
                    c.expanded.toggle();
                  },
                  decorator: (child) => Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                    child: child,
                  ),
                  child: const SvgIcon(SvgIcons.more),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    reverse: true,
                    children: [
                      const SizedBox(height: 8),
                      ...children,
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: Insets.dense.copyWith(top: 0),
                  child: _bottomBar(c, context),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _bottomBar(TransactionsController c, BuildContext context) {
    final style = Theme.of(context).style;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: style.cardRadius,
          boxShadow: [
            CustomBoxShadow(
              blurRadius: 8,
              color: style.colors.onBackgroundOpacity13,
            ),
          ],
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 57),
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            color: style.cardColor,
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const SvgIcon(SvgIcons.search),
              Expanded(
                child: Theme(
                  data: MessageFieldView.theme(context),
                  child: ReactiveTextField(
                    dense: true,
                    state: TextFieldState(),
                    hint: 'Search...',
                    style: style.fonts.medium.regular.onBackground,
                  ),
                ),
              ),
              Obx(() {
                return ContextMenuRegion(
                  enableSecondaryTap: false,
                  enablePrimaryTap: true,
                  enableLongTap: false,
                  selector: c.filterKey,
                  alignment: Alignment.bottomRight,
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  actions: [
                    if (!c.includeHold.value || !c.includeCompleted.value)
                      ContextMenuButton(
                        label: 'Display all transactions',
                        onPressed: () {
                          c.includeHold.value = true;
                          c.includeCompleted.value = true;
                        },
                      ),
                    if (!c.includeHold.value || c.includeCompleted.value)
                      ContextMenuButton(
                        label: 'Display hold only',
                        onPressed: () {
                          c.includeHold.value = true;
                          c.includeCompleted.value = false;
                        },
                      ),
                    if (!c.includeCompleted.value || c.includeHold.value)
                      ContextMenuButton(
                        label: 'Display completed only',
                        onPressed: () {
                          c.includeHold.value = false;
                          c.includeCompleted.value = true;
                        },
                      ),
                  ],
                  child: AnimatedButton(
                    key: c.filterKey,
                    onPressed: () {},
                    decorator: (child) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 24, 8),
                        child: child,
                      );
                    },
                    child: const SvgIcon(SvgIcons.more),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

extension on DateTime {
  /// Returns a [DateTime] containing only the date.
  ///
  /// For example, `2022-09-22 16:54:44.100` -> `2022-09-22 00:00:00.000`,
  DateTime toDay() {
    return DateTime(year, month, day);
  }
}
