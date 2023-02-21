// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';

class BalanceTabView extends StatelessWidget {
  const BalanceTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: BalanceTabController(),
      builder: (BalanceTabController c) {
        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('Balance: \$10.00'),
            leading: [
              WidgetButton(
                onPressed: () {},
                child: Container(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  height: double.infinity,
                  child: SvgLoader.asset(
                    'assets/icons/search.svg',
                    width: 17.77,
                  ),
                ),
              ),
            ],
            actions: [
              Obx(() {
                final Widget child;

                if (c.adding.value) {
                  child = SvgLoader.asset(
                    key: const Key('CloseSearch'),
                    'assets/icons/close_primary.svg',
                    height: 15,
                    width: 15,
                  );
                }

                return WidgetButton(
                  onPressed: () {},
                  child: Container(
                    padding: const EdgeInsets.only(left: 12, right: 20),
                    height: double.infinity,
                    child: SvgLoader.asset(
                      'assets/icons/add_funds.svg',
                      width: 20.28,
                      height: 19.94,
                    ),
                  ),
                );
              }),
            ],
          ),
          body: Column(
            children: [
              // SizedBox(
              //   height: 50,
              //   child: CustomAppBar(
              //     border: c.search.isEmpty.value || !c.search.focus.hasFocus
              //         ? null
              //         : Border.all(
              //             color: Theme.of(context).colorScheme.secondary,
              //             width: 2,
              //           ),
              //     title: Theme(
              //       data: Theme.of(context).copyWith(
              //         shadowColor: const Color(0x55000000),
              //         iconTheme: const IconThemeData(color: Colors.blue),
              //         inputDecorationTheme: InputDecorationTheme(
              //           border: OutlineInputBorder(
              //             borderRadius: BorderRadius.circular(25),
              //             borderSide: BorderSide.none,
              //           ),
              //           errorBorder: OutlineInputBorder(
              //             borderRadius: BorderRadius.circular(25),
              //             borderSide: BorderSide.none,
              //           ),
              //           enabledBorder: OutlineInputBorder(
              //             borderRadius: BorderRadius.circular(25),
              //             borderSide: BorderSide.none,
              //           ),
              //           focusedBorder: OutlineInputBorder(
              //             borderRadius: BorderRadius.circular(25),
              //             borderSide: BorderSide.none,
              //           ),
              //           disabledBorder: OutlineInputBorder(
              //             borderRadius: BorderRadius.circular(25),
              //             borderSide: BorderSide.none,
              //           ),
              //           focusedErrorBorder: OutlineInputBorder(
              //             borderRadius: BorderRadius.circular(25),
              //             borderSide: BorderSide.none,
              //           ),
              //           focusColor: Colors.white,
              //           fillColor: Colors.white,
              //           hoverColor: Colors.transparent,
              //           filled: true,
              //           isDense: true,
              //           contentPadding: EdgeInsets.fromLTRB(
              //             15,
              //             PlatformUtils.isDesktop ? 30 : 23,
              //             15,
              //             0,
              //           ),
              //         ),
              //       ),
              //       child: Padding(
              //         padding: const EdgeInsets.symmetric(horizontal: 10),
              //         child: Transform.translate(
              //           offset: const Offset(0, 1),
              //           child: ReactiveTextField(
              //             key: const Key('SearchField'),
              //             state: c.search,
              //             hint: 'label_search'.l10n,
              //             maxLines: 1,
              //             filled: false,
              //             dense: true,
              //             padding: const EdgeInsets.symmetric(vertical: 8),
              //             style: style.boldBody.copyWith(fontSize: 17),
              //             onChanged: () => c.query.value = c.search.text,
              //           ),
              //         ),
              //       ),
              //     ),
              //     leading: [
              //       Container(
              //         padding: const EdgeInsets.only(left: 20, right: 12),
              //         height: double.infinity,
              //         child: SvgLoader.asset(
              //           'assets/icons/search.svg',
              //           width: 17.77,
              //         ),
              //       )
              //     ],
              //     actions: [
              //       Obx(() {
              //         final Widget? child;

              //         if (!c.search.isEmpty.value) {
              //           child = SvgLoader.asset(
              //             'assets/icons/close_primary.svg',
              //             height: 15,
              //           );
              //         } else {
              //           child = null;
              //         }

              //         return WidgetButton(
              //           onPressed: () {
              //             c.search.clear();
              //             c.search.unsubmit();
              //             c.query.value = null;
              //           },
              //           child: Container(
              //             padding: const EdgeInsets.only(left: 12, right: 18),
              //             height: double.infinity,
              //             child: SizedBox(
              //               width: 21.77,
              //               child: AnimatedSwitcher(
              //                 duration: 250.milliseconds,
              //                 child: child,
              //               ),
              //             ),
              //           ),
              //         );
              //       }),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  children: [
                    TransactionWidget(),
                    TransactionWidget(),
                    TransactionWidget(),
                    TransactionWidget(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TransactionWidget extends StatelessWidget {
  const TransactionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: SizedBox(
        height: 73,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            border: style.cardBorder,
            color: Colors.transparent,
          ),
          child: Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius,
            color: style.cardColor,
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: () {},
              hoverColor: style.cardHoveredColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle(
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.headlineSmall!,
                            child: Text('\$1023.00'),
                          ),
                          const SizedBox(height: 6),
                          DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: Text('Зачисление'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
