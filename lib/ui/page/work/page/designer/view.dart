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
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
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
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of [WorkTab.designer] section of [Routes.work] page.
class DesignerWorkView extends StatelessWidget {
  const DesignerWorkView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: DesignerWorkController(Get.find()),
      builder: (DesignerWorkController c) {
        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('UI/UX Designer'),
            leading: const [StyledBackButton()],
            actions: [ShareIconButton('${Config.origin}${router.route}')],
          ),
          body: Center(
            child: ListView(
              shrinkWrap: !context.isNarrow,
              children: [
                const SizedBox(height: 4),
                const ProjectBlock(),
                const Block(
                  title: 'Условия',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- ежедневная оплата;\n'
                      '- от 1500 EUR;\n'
                      '- 4-х, 6-ти или 8-ми часовой рабочий день;\n'
                      '- учёт рабочего времени и оплата переработок;\n'
                      '- удалённое сотрудничество.',
                    ),
                  ],
                ),
                const Block(
                  title: 'Требования',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- понимание принципов UI/UX дизайна;\n'
                      '- уверенное владение Figma;\n'
                      '- возможность обеспечить качественную аудио и видеосвязь.',
                    ),
                  ],
                ),
                const Block(
                  title: 'Стек технологий',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('- Figma - вёрстка и прототипирование.'),
                  ],
                ),
                Block(
                  title: 'Исходный код',
                  children: [
                    Row(
                      children: [
                        WidgetButton(
                          onPressed: () => launchUrlString(
                            '${Config.origin}${Routes.style}',
                          ),
                          child: Text(
                            '- Styles page (UI-kit)',
                            style: style.fonts.normal.regular.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Obx(() {
                  return ProceedBlock(
                    'Записаться на интервью',
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
