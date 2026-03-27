// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/login/controller.dart';
import '/ui/page/login/view.dart';
import '/ui/page/work/widget/proceed_block.dart';
import '/ui/page/work/widget/project_block.dart';
import '/ui/page/work/widget/share_icon_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of [WorkTab.backend] section of [Routes.work] page.
class BackendWorkView extends StatelessWidget {
  const BackendWorkView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: BackendWorkController(Get.find()),
      builder: (BackendWorkController c) {
        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('Backend Developer'),
            leading: const [StyledBackButton()],
            actions: [ShareIconButton('${Config.origin}${router.route}')],
          ),
          body: Center(
            child: ListView(
              shrinkWrap: !context.isNarrow,
              children: [
                const SizedBox(height: 4),
                const ProjectBlock(),
                Block(
                  title: 'label_conditions'.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('label_conditions_backend_developer'.l10n)],
                ),
                Block(
                  title: 'label_requirements'.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('label_requirements_backend_developer'.l10n)],
                ),
                Block(
                  title: 'label_we_welcome'.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('label_we_welcome_backend_developer'.l10n)],
                ),
                Block(
                  title: 'label_tech_stack'.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('label_tech_stack_backend_developer'.l10n)],
                ),
                Block(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'label_for_learning_use_our_rust_incubator1'
                                .l10n,
                            style: style.fonts.normal.regular.onBackground,
                          ),
                          TextSpan(
                            text: 'label_for_learning_use_our_rust_incubator2'
                                .l10n,
                            style: style.fonts.normal.regular.primary,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrlString(
                                'https://github.com/instrumentisto/rust-incubator',
                              ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Obx(() {
                  return ProceedBlock(
                    'btn_schedule_an_interview'.l10n,
                    onPressed: c.linkStatus.value.isLoading
                        ? null
                        : () async {
                            if (c.status.value.isSuccess) {
                              await c.useLink();
                            } else {
                              await LoginView.show(
                                context,
                                initial: LoginViewStage.signUpOrSignIn,
                                onSuccess: c.useLink,
                              );
                            }
                          },
                  );
                }),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
