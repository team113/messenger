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

import 'package:collection/collection.dart';
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
import '/ui/page/work/widget/source_block.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/issue.dart';

/// View of [WorkTab.freelance] section of [Routes.work] page.
class FreelanceWorkView extends StatelessWidget {
  const FreelanceWorkView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: FreelanceWorkController(Get.find()),
      builder: (FreelanceWorkController c) {
        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('Freelance'),
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
                  title: 'Деньги',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- оплата по факту выполнения задачи. Выполненной считается задача, прошедшая ревью;\n'
                      '- оплата отправляется на основании договора о предоставлении услуг и/или инвойса;\n'
                      '- оплата осуществляется криптовалютой USDT (TRC-20).',
                    ),
                  ],
                ),
                Block(
                  title: 'Требования к коду',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '- код должен отвечать правилам ',
                          ),
                          TextSpan(
                            text: 'Contribution Guide',
                            style: style.fonts.bodyMediumPrimary,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrlString(
                                    'https://github.com/team113/messenger/blob/main/CONTRIBUTING.md',
                                  ),
                          ),
                          const TextSpan(text: ';'),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text:
                                '- код должен быть покрыт документацией по правилам ',
                          ),
                          TextSpan(
                            text: 'Effective Dart: Documentation',
                            style: style.fonts.bodyMediumPrimary,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrlString(
                                    'https://dart.dev/effective-dart/documentation',
                                  ),
                          ),
                          const TextSpan(text: ';'),
                        ],
                      ),
                    ),
                    const Text(
                      '- код должен быть покрыт модульными, виджет и/или интеграционными тестами (при необходимости).',
                    ),
                  ],
                ),
                const Block(
                  title: 'Ревью',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- выполненная задача должна пройти ревью кода;\n'
                      '- запрос на ревью выполненной задачи, комментарии, пояснения, аргументы должны размещаться публично на GitHub в соответствующей ветке или пул-реквесте.',
                    ),
                  ],
                ),
                const Block(
                  title: 'Регламент',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Выбрать задачу из списка ниже\n'
                      '2. Сделать форк проекта и по нему оформить PR (Pull Request)\n'
                      '3. Связаться с командой фронтэнда (кнопка ниже) и отправить заявку, указав:\n'
                      '    - логин на GitHub\'е\n'
                      '    - номер PR (Pull Request)\n'
                      '    - предполагаемый срок выполнения задачи (дедлайн)\n'
                      '    - предполагаемый способ решения задачи\n'
                      '4. В ответном сообщении Вы получите подтверждение, что задача закреплена за Вами (задача переводится в статус `In progress`)\n'
                      '5. В процессе работы над задачей Вы должны делать push commit\'ов в свой PR не реже, чем каждые 72 часа',
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
                        ],
                      ),
                    ),
                  ],
                ),
                Obx(() {
                  if (c.issuesStatus.value.isEmpty) {
                    return const SizedBox();
                  } else if (c.issuesStatus.value.isLoading) {
                    return const Block(
                      title: 'Задачи',
                      children: [Center(child: CustomProgressIndicator())],
                    );
                  } else if (c.issuesStatus.value.isError) {
                    return Block(
                      title: 'Задачи',
                      children: [
                        Text(
                          c.issuesStatus.value.errorMessage ??
                              'err_unknown'.l10n,
                        ),
                      ],
                    );
                  }

                  return Block(
                    title: 'Задачи',
                    children: c.issues.mapIndexed((i, e) {
                      return Obx(() {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: IssueWidget(
                            e,
                            expanded: c.expanded.value == i,
                            onPressed: () {
                              if (c.expanded.value == i) {
                                c.expanded.value = null;
                              } else {
                                c.expanded.value = i;
                              }
                            },
                          ),
                        );
                      });
                    }).toList(),
                  );
                }),
                Obx(() {
                  return ProceedBlock(
                    'Отправить заявку',
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
