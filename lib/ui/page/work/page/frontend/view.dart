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

import 'package:flutter/gestures.dart';
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
import '/ui/page/work/widget/source_block.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of [WorkTab.frontend] section of [Routes.work] page.
class FrontendWorkView extends StatelessWidget {
  const FrontendWorkView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: FrontendWorkController(Get.find()),
      builder: (FrontendWorkController c) {
        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('Frontend Developer'),
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
                      '- от 2000 EUR;\n'
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
                      '- понимание принципов UX дизайна;\n'
                      '- знание GraphQL и WebSocket;\n'
                      '- умение документировать код;\n'
                      '- умение покрывать код юнит и/или интеграционными тестами;\n'
                      '- умение читать и понимать техническую литературу на английском языке;\n'
                      '- возможность обеспечить качественную аудио и видеосвязь;',
                    ),
                  ],
                ),
                const Block(
                  title: 'Стек технологий',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- Язык - Dart;\n'
                      '- Flutter - фреймворк;\n'
                      '- GetX - Dependency Injection и State Management;\n'
                      '- Navigator 2.0 (Router) - навигация;\n'
                      '- Hive - локальная база данных;\n'
                      '- Firebase - push уведомления;\n'
                      '- GraphQL и Artemis - связь с бэкэндом;\n'
                      '- Gherkin - E2E тестирование.',
                    ),
                  ],
                ),
                const SourceCodeBlock(),
                Block(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                'В том случае, если у Вас есть желание изучить/подтянуть свои знания в технологии Flutter, Вы можете воспользоваться нашей ',
                            style: style.fonts.bodyMedium,
                          ),
                          TextSpan(
                            text: 'корпоративной песочницей.',
                            style: style.fonts.bodyMediumPrimary,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrlString(
                                    'https://github.com/team113/flutter-incubator',
                                  ),
                          ),
                          TextSpan(
                            text: '\n'
                                '\n'
                                'Кроме того, предусмотрена возможность сотрудничества в качестве фриланс разработчика. Со списком задач и условиями сотрудничества можно ознакомится на странице ',
                            style: style.fonts.bodyMedium,
                          ),
                          TextSpan(
                            text: 'Freelance.',
                            style: style.fonts.bodyMediumPrimary,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => router.work(WorkTab.freelance),
                          ),
                        ],
                      ),
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
                                onSuccess: () async => await c.useLink(),
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
