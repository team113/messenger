import 'package:flutter/material.dart';
import 'package:messenger/domain/model/vacancy.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/animated_logo.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/page/vacancy/contact/view.dart';
import 'package:messenger/ui/page/vacancy/widget/vacancy_description.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

class VacancyBodyView extends StatelessWidget {
  const VacancyBodyView(this.vacancy, {super.key});

  final Vacancy vacancy;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Center(
      child: ListView(
        shrinkWrap: !context.isNarrow,
        children: [
          const SizedBox(height: 4),
          ..._content(context, vacancy),
          // ...vacancy.blocks.map((e) {
          //   return Block(
          //     title: e.title,
          //     children: [
          //       VacancyDescription(e.description),
          //       const SizedBox(height: 4),
          //     ],
          //   );
          // }),
          Block(
            title: 'Schedule an interview',
            children: [
              Paddings.basic(
                OutlinedRoundedButton(
                  onPressed: () async {
                    await VacancyContactView.show(context);
                  },
                  maxWidth: double.infinity,
                  color: style.colors.primary,
                  title: Text(
                    'Связаться',
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
              WidgetButton(
                onPressed: () async {
                  await launchUrlString('https://gapopa.net');
                },
                child: Text(
                  'gapopa.net',
                  style: style.fonts.labelLargePrimary,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
          const Block(
            title: 'Фронтэнд',
            children: [
              VacancyDescription(
                '''Язык - Dart

Фреймворк - Flutter

Открытый исходный код-  https://github.com/team113/messenger

Курс для изучения Dart/Flutter - https://github.com/team113/flutter-incubator''',
              ),
              // const SizedBox(height: 4),
              // Text(
              //   '(курс уроков для самостоятельного изучения языка Dart и фреймворка Flutter)',
              //   style: style.fonts.labelSmallSecondary,
              // ),
            ],
          ),
          const Block(
            title: 'Стек технологий',
            children: [
              VacancyDescription(
                '''GetX - Dependency Injection и State Management;

Navigator 2.0 (Router) - навигация;

Hive - локальная база данных;

Firebase - push уведомления;

GraphQL и Artemis - связь с бэкэндом;

Gherkin - E2E тестирование.''',
              ),
            ],
          ),
          const Block(
            title: 'Frontend Developer',
            children: [
              VacancyDescription(
                '''Обязанности:

- разработка, тестирование и поддержка проекта на Dart/Flutter.


Требования:

- понимание принципов UX дизайна;
- знание GraphQL и WebSocket;
- умение документировать код;
- умение использововать автоматическое тестирование;
- умение читать и понимать техническую литературу на английском языке;
- возможность обеспечить качественную аудио и видеосвязь.


Условия:

- полная занятость;
- начальная ставка заработной платы от 2000 EUR в месяц;
- ежедневное зачисление заработной платы;
- удалённое сотрудничество;
- предусмотрен учёт рабочего времени;
- рабочее время: с 11:30 по 13:00 UTC находиться онлайн обязательно, остальное время выбирается самостоятельно по согласованию с тимлидом.


Дополнительно:

- оказывается помощь при переезде в одну из штаб-квартир компании.''',
              ),
            ],
          ),
        ];
    }

    return [const SizedBox()];
  }
}
