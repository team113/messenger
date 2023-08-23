import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/vacancy.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/animated_logo.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/page/login/controller.dart';
import 'package:messenger/ui/page/login/view.dart';
import 'package:messenger/ui/page/login/widget/sign_button.dart';
import 'package:messenger/ui/page/vacancy/contact/view.dart';
import 'package:messenger/ui/page/vacancy/widget/vacancy_description.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'controller.dart';

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
    final style = Theme.of(context).style;

    return GetBuilder(
      init: VacancyBodyController(Get.find()),
      builder: (VacancyBodyController c) {
        return Center(
          child: ListView(
            shrinkWrap: !context.isNarrow,
            children: [
              const SizedBox(height: 4),
              ..._content(context, vacancy, c),
              Block(
                children: [
                  Paddings.basic(
                    OutlinedRoundedButton(
                      onPressed: () async {
                        if (c.authorized) {
                          await c.useLink();
                        } else {
                          await LoginView.show(
                            context,
                            stage: LoginViewStage.choice,
                            onAuth: () async {
                              await c.useLink();
                            },
                          );
                        }
                      },
                      maxWidth: double.infinity,
                      color: style.colors.primary,
                      title: Text(
                        'Записаться на интервью',
                        style: TextStyle(color: style.colors.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _content(
    BuildContext context,
    Vacancy vacancy,
    VacancyBodyController c,
  ) {
    final style = Theme.of(context).style;

    const double multiplier = 0.8;

    switch (vacancy.id) {
      case 'dart':
        return [
          Block(
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
              const SizedBox(height: 16 * multiplier),
              const VacancyDescription('https://github.com/team113/messenger'),
            ],
          ),
          const Block(
            title: 'Условия',
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
          const Block(
            // title: 'Курс для самостоятельного обучения',
            children: [
              VacancyDescription(
                '''В том случае, если у Вас есть желание изучить/подтянуть свои знания в технологии Dart/Flutter, Вы можете воспользоваться нашей корпоративной песочницей.

https://github.com/team113/flutter-incubator''',
              ),
            ],
          ),
        ];

      case 'backend':
        return [
          Block(
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
              const SizedBox(height: 16 * multiplier),
              const VacancyDescription('https://github.com/team113/messenger'),
            ],
          ),
          const Block(
            title: 'Условия',
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
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: VacancyDescription(
                  '''- Язык - Rust;
- actix-web - веб-фреймворк;
- CockroachDB - база данных;
- baza - файловое хранилище;
- Medea - медиа сервер;
- Firebase - push уведомления;
- GraphQL - API;
- Cucumber - E2E тестирование.''',
                ),
              ),
            ],
          ),
          const Block(
            // title: 'Курс для самостоятельного обучения',
            children: [
              VacancyDescription(
                '''В том случае, если у Вас есть желание изучить/подтянуть свои знания в технологии Rust, Вы можете воспользоваться нашей корпоративной песочницей.

https://github.com/instrumentisto/rust-incubator''',
              ),
            ],
          ),
        ];

      case 'freelance':
        return [
          Block(
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
              const SizedBox(height: 16 * multiplier),
              const VacancyDescription('https://github.com/team113/messenger'),
            ],
          ),
          const Block(
            title: 'Деньги',
            children: [
              Align(
                alignment: Alignment.centerLeft,
                // - деньги обсуждаются только приватно;
                child: VacancyDescription(
                  '''- стоимость, способы оплаты и сроки выполнения каждой задачи обсуждаются приватно в индивидуальном порядке;
- оплата по факту выполнения задачи. Выполненной считается задача, прошедшая ревью;
- заключается договор.''',
                ),
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
                          '- при необходимости код должен быть покрыт модульными, виджет и/или интеграционными тестами.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Block(
            title: 'Ревью',
            children: [
              VacancyDescription(
                '''- выполненная задача должна пройти ревью кода;
- ревью кода, пояснения, комментарии ведутся публично на GitHub.''',
              )
            ],
          ),
          const Block(
            title: 'Оплата',
            children: [VacancyDescription('''...''')],
          ),
          const Block(
            title: 'Оплата',
            children: [VacancyDescription('''...''')],
          ),
          const Block(
            title: 'Оплата',
            children: [VacancyDescription('''...''')],
          ),
          const Block(
            title: 'Условия',
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
          Obx(() {
            final Widget child;

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
              children: c.issues.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ElevatedButton(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(e.title),
                    ),
                    onPressed: () {
                      launchUrlString(e.url);
                    },
                    // subtitle: e.description == null ? null : Text(e.description!),
                  ),
                );
              }).toList(),
            );
          }),
          const Block(
            children: [
              VacancyDescription(
                '''В том случае, если у Вас есть желание изучить/подтянуть свои знания в технологии Dart/Flutter, Вы можете воспользоваться нашей корпоративной песочницей.

https://github.com/team113/flutter-incubator''',
              ),
            ],
          ),
        ];
    }

    return [const SizedBox()];
  }
}
