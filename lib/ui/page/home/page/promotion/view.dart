// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/promo_share.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';

/// View of the [Routes.promotion] page.
class PromotionView extends StatelessWidget {
  const PromotionView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: PromotionController(),
      builder: (PromotionController c) {
        return Scaffold(
          appBar: CustomAppBar(
            title: Text('label_your_promotion'.l10n),
            leading: const [SizedBox(width: 4), StyledBackButton()],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
            children: [
              Block(
                title: 'label_your_author_partner_program_tapopa_author'.l10n,
                children: [
                  SvgImage.asset(
                    'assets/images/blocks/promotion_partner_program.svg',
                    width: 296,
                    height: 285,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'label_your_promotion_program_description'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
              ),
              Block(
                title: 'label_partner_percentage'.l10n,
                padding: EdgeInsets.fromLTRB(4, 16, 4, 16),
                children: [
                  Obx(() {
                    final List<Widget> children;

                    if (c.percentEditing.value) {
                      children = [
                        WidgetButton(
                          onPressed: () => c.percentEditing.value = false,
                          child: Text(
                            'btn_save'.l10n,
                            style: style.fonts.small.regular.primary,
                          ),
                        ),
                      ];
                    } else {
                      children = [
                        Text(
                          '5%',
                          style: style.fonts.giant.regular.onBackground,
                        ),
                        const SizedBox(height: 12),
                        WidgetButton(
                          onPressed: () => c.percentEditing.value = true,
                          child: Text(
                            'btn_change'.l10n,
                            style: style.fonts.small.regular.primary,
                          ),
                        ),
                      ];
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(32 - 4, 0, 32 - 4, 0),
                      child: AnimatedSizeAndFade(
                        sizeDuration: const Duration(milliseconds: 300),
                        fadeDuration: const Duration(milliseconds: 300),
                        child: Column(
                          key: Key(c.percentEditing.value.toString()),
                          children: children,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32 - 4, 0, 32 - 4, 0),
                    child: LineDivider('label_change_history'.l10n),
                  ),
                  const SizedBox(height: 16),
                  LineDivider(''),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(),
                      1: IntrinsicColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: _percents(context),
                  ),
                  LineDivider(''),
                  const SizedBox(height: 6),
                ],
              ),
              Block(
                title: 'label_program_terms'.l10n,
                children: [
                  LineDivider('label_partner_percentage'.l10n),
                  const SizedBox(height: 20),
                  Text(
                    'label_your_promotion_program_description'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                  const SizedBox(height: 24),
                  LineDivider('label_partner_number_tapopa_author'.l10n),
                  const SizedBox(height: 20),
                  Text(
                    'label_partner_number_tapopa_author_description'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the [TableRow] of [PromoShare] history.
  List<TableRow> _percents(BuildContext context) {
    final style = Theme.of(context).style;

    final List<TableRow> percents = [];
    final List<PromoShare> shares = [
      PromoShare(percentage: Percentage('5'), addedAt: PreciseDateTime.now()),
    ];

    for (var i = 0; i < shares.length; ++i) {
      final e = shares[i];

      percents.add(
        TableRow(
          decoration: BoxDecoration(
            color: i % 2 == 0
                ? style.colors.background
                : style.colors.onPrimary,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 4, 10),
              child: Text(
                '${e.percentage.val}%',
                style: style.fonts.medium.regular.onBackground,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    child: Text(
                      e.addedAt.val.yMd,
                      style: style.fonts.smaller.regular.secondary,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Text('  —  ', style: style.fonts.smaller.regular.secondary),
                  SizedBox(
                    child: Text(
                      e.removedAt == null
                          ? 'label_present_time'.l10n.toLowerCase()
                          : e.removedAt!.val.yMd,
                      style: style.fonts.smaller.regular.secondary,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return percents;
  }
}
