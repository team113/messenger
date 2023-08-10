import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/vacancy.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/page/home/widget/vacancy.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/platform_utils.dart';

import 'contact/view.dart';
import 'controller.dart';
import 'widget/vacancy_description.dart';

class VacancyView extends StatelessWidget {
  const VacancyView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: VacancyController(Get.find()),
      builder: (VacancyController c) {
        return Stack(
          children: [
            IgnorePointer(
              child: SvgImage.asset(
                'assets/images/background_light.svg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Scaffold(
              body: LayoutBuilder(builder: (context, constraints) {
                if (context.isNarrow) {
                  return Stack(
                    children: [
                      Obx(() {
                        return AnimatedOpacity(
                          duration: 300.milliseconds,
                          opacity: c.vacancy.value == null ? 1 : 0,
                          child: Container(
                            decoration:
                                BoxDecoration(color: style.sidebarColor),
                            child: _list(c, context),
                          ),
                        );
                      }),
                      Obx(() {
                        return IgnorePointer(
                          ignoring: c.vacancy.value == null,
                          child: _vacancy(c, context),
                        );
                      }),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: style.sidebarColor),
                      width: (constraints.maxWidth / 2).clamp(0, 340),
                      child: _list(c, context),
                    ),
                    Expanded(child: _vacancy(c, context)),
                  ],
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _list(VacancyController c, BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        leading: [StyledBackButton()],
        title: Text('Vacancies'),
        actions: [SizedBox(width: 46)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          ...Vacancies.all.skip(1).map((e) {
            return Obx(() {
              return VacancyWidget(
                e.title,
                selected: c.vacancy.value == e,
                onPressed: () => c.vacancy.value = e,
              );
            });
          }),
        ],
      ),
    );
  }

  Widget _vacancy(VacancyController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Widget child;

      if (c.vacancy.value != null) {
        final e = c.vacancy.value!;

        child = Scaffold(
          key: Key(e.id),
          appBar: CustomAppBar(
            leading: [
              StyledBackButton(onPressed: () => c.vacancy.value = null),
            ],
            title: Text(e.title),
            actions: const [SizedBox(width: 46)],
          ),
          body: Center(
            child: ListView(
              shrinkWrap: !context.isNarrow,
              children: [
                const SizedBox(height: 4),
                Block(
                  title: 'О проекте',
                  children: [
                    Paddings.basic(
                      const VacancyDescription(
                        '''- мессенджер Gapopa;
- фронтэнд часть с открытым исходным кодом;
- используется GetX в качестве DI и State Management;
- используется Navigator 2.0 (Router) в качестве навигации;
- используется Hive в качестве локальной базы данных;
- используется Firebase для push уведомлений;
- используется GraphQL и Artemis для общения с бэкэндом;
- используется Gherkin для написания E2E тестов;
- подробнее: https://github.com/team113/messenger''',
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                Block(
                  title: 'Вакансия',
                  children: [
                    Paddings.basic(
                      VacancyDescription(e.description),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
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
                if (false)
                  Block(
                    title: 'Schedule an interview',
                    children: [
                      Paddings.basic(Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Text(
                                'Интервью проводится онлайн с использованием мессенджера Gapopa. Устойчивая аудио- и видеосвязь обязательна. В процессе интервью сотрудник HR отдела будет готов ответить на Ваши вопросы, попросит Вас рассказать о себе, а также Вам может быть предложено решить техническую задачу.',
                                style: TextStyle(
                                  color: style.colors.secondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ReactiveTextField(state: c.email, label: 'E-mail*'),
                          const SizedBox(height: 16),
                          Obx(() {
                            return FieldButton(
                              text: c.resume.value == null
                                  ? 'Прикрепить резюме*'
                                  : '${c.resume.value!.name} ${c.resume.value!.size ~/ 1000} KB',
                              style: TextStyle(color: style.colors.primary),
                              onPressed: c.pick,
                            );
                          }),
                          const SizedBox(height: 16),
                          ReactiveTextField(
                            state: c.text,
                            hint: 'Сопроводительный текст',
                            maxLines: 5,
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Text(
                                c.status.value.isEmpty
                                    ? '''Доступ к аккаунту без пароля сохраняется в течение одного года с момента создания аккаунта или пока:

• Вы не удалите пользовательские данные из приложения (браузера);

• Вы не нажмёте кнопку "Выйти".

Чтобы не потерять доступ к аккаунту, задайте пароль.'''
                                    // ? 'Аккаунт создаётся автоматически. Доступ к аккаунту без пароля сохраняется в течение одного года. Чтобы не потерять доступ, задайте пароль.'
                                    : 'Вы будете перенаправлены в чат с HR-менеджером.',
                                style: TextStyle(
                                  color: style.colors.secondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(() {
                            final bool enabled = !c.email.isEmpty.value &&
                                c.resume.value != null;

                            return OutlinedRoundedButton(
                              onPressed: enabled ? c.send : null,
                              maxWidth: double.infinity,
                              color: style.colors.primary,
                              title: Text(
                                'Связаться',
                                style: TextStyle(
                                  color: enabled
                                      ? style.colors.onPrimary
                                      : style.colors.onBackground,
                                ),
                              ),
                            );
                          }),
                        ],
                      )),
                    ],
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      } else {
        if (context.isNarrow) {
          child = const SizedBox();
        } else {
          child = const Scaffold(
            body: Center(child: Text('Vacancies...')),
          );
        }
      }

      return AnimatedSwitcher(
        duration: 300.milliseconds,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: CurvedAnimation(
              curve: Curves.ease,
              parent: animation,
            ).drive(
              Tween(
                begin: const Offset(1, 0),
                end: const Offset(0, 0),
              ),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: child,
      );
    });
  }
}
