import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/vacancy.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/animated_logo.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/page/login/controller.dart';
import 'package:messenger/ui/page/login/view.dart';
import 'package:messenger/ui/page/vacancy/widget/vacancy_description.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'controller.dart';
import 'widget/github.dart';

class VacancyBodyView extends StatelessWidget {
  const VacancyBodyView(
    this.vacancy, {
    super.key,
    this.detailed = true,
  });

  final Vacancy vacancy;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VacancyBodyController(Get.find()),
      builder: (VacancyBodyController c) {
        return Center(
          child: ListView(
            shrinkWrap: !context.isNarrow,
            children: [
              const SizedBox(height: 4),
              ..._content(context, vacancy, c),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _button(
    BuildContext context,
    VacancyBodyController c, {
    String title = 'Записаться на интервью',
    String? welcome,
  }) {
    final style = Theme.of(context).style;

    return Block(
      children: [
        Paddings.basic(
          OutlinedRoundedButton(
            onPressed: () async {
              if (c.authorized) {
                await c.useLink(welcome);
              } else {
                await LoginView.show(
                  context,
                  stage: LoginViewStage.choice,
                  onAuth: () async {
                    await c.useLink(welcome);
                  },
                );
              }
            },
            maxWidth: double.infinity,
            color: style.colors.primary,
            title: Text(
              title,
              style: TextStyle(color: style.colors.onPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _project(BuildContext context) {
    final style = Theme.of(context).style;

    const double multiplier = 0.8;

    return Block(
      children: [
        Text(
          'Messenger',
          style: style.fonts.titleLargeSecondary
              .copyWith(fontSize: 27 * multiplier),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2 * multiplier),
        Text(
          'by Gapopa',
          style: style.fonts.titleLargeSecondary
              .copyWith(fontSize: 21 * multiplier),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 25 * multiplier),
        const InteractiveLogo(height: (190 * 0.75 + 25) * multiplier),
        const SizedBox(height: 7),
      ],
    );
  }

  Widget _source(BuildContext context) {
    final style = Theme.of(context).style;

    return Block(
      title: 'Исходный код',
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              text: '- GitHub repository',
              style: style.fonts.bodyMediumPrimary,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrlString(
                      'https://github.com/team113/messenger',
                    ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              text: '- Styles page',
              style: style.fonts.bodyMediumPrimary,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrlString(
                      'https://gapopa.net/style',
                    ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              text: '- GraphQL API',
              style: style.fonts.bodyMediumPrimary,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrlString(
                      'https://messenger.soc.stg.t11913.org/api/graphql/playground',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _content(
    BuildContext context,
    Vacancy vacancy,
    VacancyBodyController c,
  ) {
    final style = Theme.of(context).style;

    switch (vacancy.id) {
      case 'dart':
        return [
          _project(context),
          const Block(
            title: 'Условия',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- ежедневная оплата;
- от 2000 EUR;
- 4-х, 6-ти или 8-ми часовой рабочий день;
- учёт рабочего времени и оплата переработок;
- удалённое сотрудничество.''',
              ),
            ],
          ),
          const Block(
            title: 'Требования',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- понимание принципов UX дизайна;
- знание GraphQL и WebSocket;
- умение документировать код;
- умение покрывать код юнит и/или интеграционными тестами;
- умение читать и понимать техническую литературу на английском языке;
- возможность обеспечить качественную аудио и видеосвязь.''',
              ),
            ],
          ),
          const Block(
            title: 'Стек технологий',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- Язык - Dart;
- Flutter - фреймворк;
- GetX - Dependency Injection и State Management;
- Navigator 2.0 (Router) - навигация;
- Hive - локальная база данных;
- Firebase - push уведомления;
- GraphQL и Artemis - связь с бэкэндом;
- Gherkin - E2E тестирование.''',
              ),
            ],
          ),
          _source(context),
          Block(
            // title: 'Курс для самостоятельного обучения',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          'В том случае, если у Вас есть желание изучить/подтянуть свои знания в технологии Rust, Вы можете воспользоваться нашей ',
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
          _button(context, c),
        ];

      case 'backend':
        return [
          _project(context),
          const Block(
            title: 'Условия',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- ежедневная оплата;
- от 2000 EUR;
- 4-х, 6-ти или 8-ми часовой рабочий день;
- учёт рабочего времени и оплата переработок;
- удалённое сотрудничество.''',
              ),
            ],
          ),
          const Block(
            title: 'Требуется',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- знание языка Rust;
- понимание FFI и UB;
- навык оптимизации программ и умение использовать профилировщик;
- понимание принципов работы клиент-серверных web-приложений;
- понимание принципов проектирования структур баз данных;
- понимание принципов DDD и слоенной архитектуры;
- навык написания модульных и функциональных тестов;
- навык работы с Git;
- умение использовать операционные системы типа *nix.''',
              ),
            ],
          ),
          const Block(
            title: 'Приветствуется',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- навык работы с языками C, C++;
- навык работы по CQRS+ES парадигме;
- навык работы с технологиями Memcached, Redis, RabbitMQ, MongoDB, Cassandra, Kafka;
- навык работы с другими языками Java, Go, Python, Ruby, TypeScript, JavaScript.''',
              ),
            ],
          ),
          const Block(
            title: 'Стек технологий',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- Язык - Rust;
- actix-web - веб-фреймворк;
- CockroachDB - база данных;
- baza - файловое хранилище;
- Medea - медиа сервер;
- Firebase - push уведомления;
- GraphQL - API;
- Cucumber - E2E тестирование.''',
              ),
            ],
          ),
          Block(
            crossAxisAlignment: CrossAxisAlignment.start,
            // title: 'Курс для самостоятельного обучения',
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          'В том случае, если у Вас есть желание изучить/подтянуть свои знания в технологии Rust, Вы можете воспользоваться нашей ',
                      style: style.fonts.bodyMedium,
                    ),
                    TextSpan(
                      text: 'корпоративной песочницей.',
                      style: style.fonts.bodyMediumPrimary,
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
          _button(context, c),
        ];

      case 'freelance':
        return [
          _project(context),
          const Block(
            title: 'Деньги',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- оплата по факту выполнения задачи. Выполненной считается задача, прошедшая ревью;
- оплата отправляется на основании договора о предоставлении услуг и/или инвойса;
- оплата осуществляется криптовалютой USDT (TRC-20).''',
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
                    const TextSpan(text: '- код должен отвечать правилам '),
                    TextSpan(
                      text: 'Contribution Guide',
                      style: TextStyle(color: style.colors.primary),
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
                      style: TextStyle(color: style.colors.primary),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrlString(
                              'https://dart.dev/effective-dart/documentation',
                            ),
                    ),
                    const TextSpan(text: ';'),
                  ],
                ),
              ),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '- код должен быть покрыт модульными, виджет и/или интеграционными тестами (при необходимости).',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Block(
            title: 'Ревью',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- выполненная задача должна пройти ревью кода;
- запрос на ревью выполненной задачи, комментарии, пояснения, аргументы должны размещаться публично на GitHub в соответствующей ветке или пул-реквесте.''',
              )
            ],
          ),
          const Block(
            title: 'Регламент',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''1. Выбрать задачу из списка ниже
2. Сделать форк проекта и по нему оформить PR (Pull Request)
3. Связаться с командой фронтэнда (кнопка ниже) и отправить заявку, указав:
    - логин на GitHub'е
    - номер PR (Pull Request)
    - предполагаемый срок выполнения задачи (дедлайн)
    - предполагаемый способ решения задачи
4. В ответном сообщении Вы получите подтверждение, что задача закреплена за Вами (задача переводится в статус `In progress`)
5. В процессе работы над задачей Вы должны делать push commit'ов в свой PR не реже, чем каждые 72 часа''',
              ),
            ],
          ),
          const Block(
            title: 'Стек технологий',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacancyDescription(
                '''- Язык - Dart;
- Flutter - фреймворк;
- GetX - Dependency Injection и State Management;
- Navigator 2.0 (Router) - навигация;
- Hive - локальная база данных;
- Firebase - push уведомления;
- GraphQL и Artemis - связь с бэкэндом;
- Gherkin - E2E тестирование.''',
              ),
            ],
          ),
          _source(context),
          Block(
            // title: 'Курс для самостоятельного обучения',
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          'В том случае, если у Вас есть желание изучить/подтянуть свои знания в технологии Rust, Вы можете воспользоваться нашей ',
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
            if (c.status.value.isEmpty) {
              return Block(
                title: 'Задачи',
                children: [
                  ElevatedButton(
                    onPressed: c.fetchIssues,
                    child: const Text('Fetch'),
                  ),
                ],
              );
            } else if (c.status.value.isLoading) {
              return const Block(
                title: 'Задачи',
                children: [Center(child: CustomProgressIndicator())],
              );
            } else if (c.status.value.isError) {
              return Block(
                title: 'Задачи',
                children: [
                  Text(c.status.value.errorMessage ?? 'Error'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: c.fetchIssues,
                    child: const Text('Try again'),
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
                    child: GitHubIssueWidget(
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
          _button(
            context,
            c,
            title: 'Отправить заявку',
            welcome: '''Добрый день. Пожалуйста, укажите:
- логин на GitHub'е;
- номер PR (Pull Request);
- предполагаемый срок выполнения задачи (дедлайн);
- предполагаемый способ решения задачи.''',
          ),
        ];
    }

    return [const SizedBox()];
  }
}
