// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/page/login/widget/primary_button.dart';
import '/ui/page/work/widget/project_block.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// Page for acquiring user's consent about [Sentry] data collection.
class ConsentView extends StatelessWidget {
  const ConsentView(this.callback, {super.key});

  /// Callback, called when consent is acquired.
  final Future<void> Function(bool) callback;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: ConsentController(Get.find(), callback),
      builder: (ConsentController c) {
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: ColoredBox(color: style.colors.background),
            ),
            const IgnorePointer(
              child: SvgImage.asset(
                'assets/images/background_light.svg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Obx(() {
              if (c.status.value.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Scaffold(
                appBar: AppBar(title: Text('label_anonymous_reports'.l10n)),
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            shrinkWrap: true,
                            children: [
                              ProjectBlock(
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    'label_anonymous_reports_description'.l10n,
                                    style:
                                        style.fonts.medium.regular.onBackground,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: PrimaryButton(
                          title: 'btn_allow'.l10n,
                          onPressed: () => c.proceed(true),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: StyledCupertinoButton(
                          onPressed: () => c.proceed(false),
                          label: 'btn_do_not_allow'.l10n,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
