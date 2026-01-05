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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// View for [Routes.prices] page.
class PricesView extends StatelessWidget {
  const PricesView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: PricesController(),
      builder: (PricesController c) {
        return Scaffold(
          appBar: CustomAppBar(
            title: Text('label_set_your_prices'.l10n),
            leading: const [SizedBox(width: 4), StyledBackButton()],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
            children: [
              Block(
                title: 'label_thats_easy'.l10n,
                children: [
                  SvgImage.asset(
                    'assets/images/blocks/prices_info.svg',
                    width: 296,
                    height: 296,
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'label_set_prices_description1'.l10n),
                        TextSpan(
                          text: 'label_set_prices_description2'.l10n,
                          style: style.fonts.small.regular.onBackground,
                        ),
                        TextSpan(text: 'label_set_prices_description3'.l10n),
                      ],
                    ),
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
              ),
              Block(
                title: 'label_monetization_settings'.l10n,
                folded: true,
                foldedColor: style.colors.currencyPrimary,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'label_monetization_settings_description1'.l10n,
                        ),
                        TextSpan(
                          text: 'label_monetization_settings_description2'.l10n,
                          style: style.fonts.small.regular.primary,
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                        TextSpan(
                          text: 'label_monetization_settings_description3'.l10n,
                        ),
                      ],
                    ),
                    style: style.fonts.small.regular.secondary,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              Block(
                title: 'label_individual_monetization'.l10n,
                folded: true,
                foldedColor: style.colors.currencyPrimary,
                children: [
                  Text(
                    'label_individual_monetization_description'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                  const SizedBox(height: 24),
                  LineDivider(
                    'label_individual_users_count'.l10nfmt({'count': 0}),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'label_you_can_set_individual_monetization_in_profile'.l10n,
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
}
