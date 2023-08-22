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
import 'package:messenger/ui/page/vacancy/contact/view.dart';
import 'package:messenger/ui/page/vacancy/widget/vacancy_description.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/util/platform_utils.dart';

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
              ..._content(context, vacancy),
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

  List<Widget> _content(BuildContext context, Vacancy vacancy) {
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
