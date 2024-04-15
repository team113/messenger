import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/page/work/widget/project_block.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

import 'controller.dart';

class ConsentView extends StatelessWidget {
  const ConsentView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: ConsentController(),
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
            Scaffold(
              appBar: AppBar(
                title: const Text('Анонимные отчёты'),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        children: [
                          // const SizedBox(height: 16),
                          // const InteractiveLogo(),
                          ProjectBlock(
                            children: [
                              const SizedBox(height: 16),
                              Text(
                                'Приложение может собирать абсолютно анонимно технические данные работы приложения и подробные отчёты об ошибках в случае их возникновения.\n'
                                '\n'
                                'Разрешить приложению собирать и отправлять эти данные?',
                                style: style.fonts.medium.regular.onBackground,
                              ),
                            ],
                          ),
                          // const SizedBox(height: 16),
                          // Block(
                          //   children: [
                          //     Text(
                          //       'Приложение может собирать абсолютно анонимно технические данные работы приложения и подробные отчёты об ошибках в случае их возникновения.\n'
                          //       '\n'
                          //       'Разрешить приложению собирать и отправлять эти данные?',
                          //       style: style.fonts.big.regular.onBackground,
                          //     ),
                          //   ],
                          // ),
                        ],
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
            ),
          ],
        );
      },
    );
  }
}
