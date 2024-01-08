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
                  title: 'Требуется',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- знание языка Rust;\n'
                      '- понимание FFI и UB;\n'
                      '- навык оптимизации программ и умение использовать профилировщик;\n'
                      '- понимание принципов работы клиент-серверных web-приложений;\n'
                      '- понимание принципов проектирования структур баз данных;\n'
                      '- понимание принципов DDD и слоенной архитектуры;\n'
                      '- навык написания модульных и функциональных тестов;\n'
                      '- навык работы с Git;\n'
                      '- умение использовать операционные системы типа *nix.',
                    ),
                  ],
                ),
                const Block(
                  title: 'Приветствуется',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- навык работы с языками C, C++;\n'
                      '- навык работы по CQRS+ES парадигме;\n'
                      '- навык работы с технологиями Memcached, Redis, RabbitMQ, MongoDB, Cassandra, Kafka;\n'
                      '- навык работы с другими языками Java, Go, Python, Ruby, TypeScript, JavaScript.',
                    ),
                  ],
                ),
                const Block(
                  title: 'Стек технологий',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- Язык - Rust;\n'
                      '- actix-web - веб-фреймворк;\n'
                      '- CockroachDB - база данных;\n'
                      '- baza - файловое хранилище;\n'
                      '- Medea - медиа сервер;\n'
                      '- Firebase - push уведомления;\n'
                      '- GraphQL - API;\n'
                      '- Cucumber - E2E тестирование.',
                    ),
                  ],
                ),
                Block(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                'В том случае, если у Вас есть желание изучить/подтянуть свои знания в технологии Rust, Вы можете воспользоваться нашей ',
                            style: style.fonts.normal.regular.onBackground,
                          ),
                          TextSpan(
                            text: 'корпоративной песочницей.',
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
