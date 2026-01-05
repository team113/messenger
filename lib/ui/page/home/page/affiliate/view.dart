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

class AffiliateView extends StatelessWidget {
  const AffiliateView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: AffiliateController(),
      builder: (AffiliateController c) {
        return Scaffold(
          appBar: CustomAppBar(
            title: Text('label_partner_programs'.l10n),
            leading: const [SizedBox(width: 4), StyledBackButton()],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
            children: [
              Block(
                title: 'label_thats_easy'.l10n,
                children: [
                  SvgImage.asset(
                    'assets/images/blocks/partner_programs_info.svg',
                    width: 296,
                    height: 280,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'label_partner_programs_easy_description'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
              ),
              Block(
                title: 'label_partner_program_tapopa_partner'.l10n,
                folded: true,
                foldedColor: style.colors.currencyPrimary,
                children: [
                  SvgImage.asset(
                    'assets/images/blocks/partner_program_tapopa_partner.svg',
                    width: 296,
                    height: 242,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'label_it_works_for_years'.l10n,
                      style: style.fonts.big.regular.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              '1%',
                              style: style.fonts.giant.bold.currencyPrimary,
                            ),
                            Text(
                              '+',
                              style: style.fonts.giant.bold.currencyPrimary,
                            ),
                            Text(
                              '1%',
                              style: style.fonts.giant.bold.currencyPrimary,
                            ),
                            Text(
                              '+',
                              style: style.fonts.giant.bold.currencyPrimary,
                            ),
                            Text(
                              '10%',
                              style: style.fonts.giant.bold.currencyPrimary,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'label_from_purchases_lowercase'.l10n,
                                style: style.fonts.small.regular.secondary,
                                textAlign: TextAlign.left,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'label_from_sales_lowercase'.l10n,
                                style: style.fonts.small.regular.secondary,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'label_from_earnings_lowercase'.l10n,
                                style: style.fonts.small.regular.secondary,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LineDivider('label_description'.l10n),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'label_partner_program_tapopa_partner_description1'
                                  .l10n,
                        ),
                        TextSpan(
                          text:
                              'label_partner_program_tapopa_partner_description2'
                                  .l10nfmt({'percent': 1}),
                          style: style.fonts.small.regular.currencyPrimary,
                        ),
                        TextSpan(
                          text:
                              'label_partner_program_tapopa_partner_description3'
                                  .l10n,
                        ),
                        TextSpan(
                          text:
                              'label_partner_program_tapopa_partner_description4'
                                  .l10nfmt({'percent': 1}),
                          style: style.fonts.small.regular.currencyPrimary,
                        ),
                        TextSpan(
                          text:
                              'label_partner_program_tapopa_partner_description5'
                                  .l10n,
                        ),
                        TextSpan(
                          text:
                              'label_partner_program_tapopa_partner_description6'
                                  .l10nfmt({'percent': 10}),
                          style: style.fonts.small.regular.currencyPrimary,
                        ),
                        TextSpan(
                          text:
                              'label_partner_program_tapopa_partner_description7'
                                  .l10n,
                        ),
                      ],
                    ),
                    style: style.fonts.small.regular.secondary,
                  ),
                  const SizedBox(height: 24),
                  LineDivider('label_partner_number_tapopa_partner'.l10n),
                  const SizedBox(height: 20),
                  Text(
                    'label_partner_program_tapopa_partner_number'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
              ),
              Block(
                title: 'label_partner_program_tapopa_author'.l10n,
                folded: true,
                foldedColor: style.colors.currencyPrimary,
                children: [
                  SvgImage.asset(
                    'assets/images/blocks/partner_program_tapopa_author.svg',
                    width: 296,
                    height: 296,
                  ),
                  const SizedBox(height: 24),
                  LineDivider('label_partner_percentage'.l10n),
                  const SizedBox(height: 20),
                  Text(
                    'label_partner_program_tapopa_author_percentage'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                  const SizedBox(height: 24),
                  LineDivider('label_partner_number_tapopa_author'.l10n),
                  const SizedBox(height: 20),
                  Text(
                    'label_partner_program_tapopa_author_number'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
              ),
              Block(
                title: 'label_partner_links'.l10n,
                children: [
                  SvgImage.asset(
                    'assets/images/blocks/partner_links.svg',
                    width: 296,
                    height: 252,
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'label_partner_program_links_description1'.l10n,
                        ),
                        TextSpan(
                          text: 'label_partner_program_links_description2'.l10n,
                          style: style.fonts.small.regular.primary,
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                        TextSpan(
                          text: 'label_partner_program_links_description3'.l10n,
                        ),
                        TextSpan(
                          text: 'label_partner_program_links_description4'.l10n,
                          style: style.fonts.small.regular.primary,
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                        TextSpan(
                          text: 'label_partner_program_links_description5'.l10n,
                        ),
                      ],
                    ),
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
