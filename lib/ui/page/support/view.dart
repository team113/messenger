// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:url_launcher/url_launcher.dart';

import '/config.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/domain/service/session.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/login/controller.dart';
import '/ui/page/login/view.dart';
import '/ui/page/work/widget/project_block.dart';
import '/ui/widget/primary_button.dart';
import '/util/get.dart';
import '/util/message_popup.dart';
import 'controller.dart';
import 'log/controller.dart';
import 'log/view.dart';

/// [Routes.support] page.
class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: SupportController(
        Get.find(),
        Get.find(),
        Get.findOrNull<MyUserService>(),
        Get.findOrNull<SessionService>(),
        Get.findOrNull<NotificationService>(),
      ),
      builder: (SupportController c) {
        return Scaffold(
          appBar: CustomAppBar(
            leading: const [StyledBackButton()],
            title: Text('label_support_service'.l10n),
            actions: const [SizedBox(width: 24)],
          ),
          body: ListView(
            children: [
              ProjectBlock(onPressed: () => LogView.show(context)),
              Block(
                title: 'label_report_a_problem'.l10n,
                children: [
                  Text(
                    'label_report_a_problem_description'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    title: 'btn_download_tech_info_file'.l10n,
                    onPressed: () async {
                      await LogController.download(
                        sessions: c.sessions,
                        sessionId: c.sessionId,
                        userAgent: c.userAgent.value,
                        myUser: c.myUser?.value,
                        token: c.token,
                        pushNotifications: c.pushNotifications,
                        notificationSettings:
                            await LogController.getNotificationSettings(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              Obx(() {
                final authorized = c.credentials.value != null;

                if (authorized) {
                  return const SizedBox();
                }

                return Block(
                  title: 'btn_sign_in'.l10n,
                  children: [
                    Text(
                      'label_to_contact_support_sign_in'.l10n,
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FieldButton(
                            onPressed: () async => await c.register(),
                            text: 'btn_guest'.l10n,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PrimaryButton(
                            onPressed: () async {
                              await LoginView.show(
                                context,
                                initial: LoginViewStage.signIn,
                              );
                            },
                            title: 'btn_sign_in'.l10n,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
              Block(
                title: 'label_send_an_email'.l10n,
                children: [
                  Text(
                    'label_send_an_email_description'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    onPressed: () async {
                      await _mail(
                        context,
                        subject: 'E-mail from Help page',
                        body: '',
                      );
                    },
                    title: 'btn_send_email'.l10n,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Launches the email scheme to the [Config.support] with provided [subject]
  /// and [body].
  Future<void> _mail(
    BuildContext context, {
    required String subject,
    required String body,
  }) async {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');
    }

    try {
      await launchUrl(
        Uri(
          scheme: 'mailto',
          path: Config.support,
          query: encodeQueryParameters({
            'subject': subject,
            'body': '$body\n\n',
          }),
        ),
      );
    } catch (e) {
      await MessagePopup.error(
        'label_contact_us_via_provided_email'.l10nfmt({
          'email': Config.support,
        }),
      );
    }
  }
}
