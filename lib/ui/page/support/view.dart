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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
import '/l10n/l10n.dart';
import '/pubspec.g.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/login/widget/prefix_button.dart';
import '/ui/page/work/widget/project_block.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// [Routes.support] page.
class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: SupportController(Get.find()),
      builder: (SupportController c) {
        return Scaffold(
          appBar: CustomAppBar(
            leading: const [StyledBackButton()],
            title: Text('label_support_service'.l10n),
            actions: const [SizedBox(width: 24)],
          ),
          body: ListView(
            children: [
              const ProjectBlock(),
              Block(
                title: 'label_what_we_can_help_you_with'.l10n,
                children: [
                  _button(
                    context,
                    title: 'btn_report_a_concern'.l10n,
                    onPressed: () async {
                      await _mail(
                        context,
                        subject: '[Concern] Report a concern',
                        body: 'label_replace_this_text_with_concern'.l10n,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _button(
                    context,
                    title: 'btn_report_a_bug'.l10n,
                    onPressed: () async {
                      await launchUrlString(Config.repository);
                    },
                  ),
                  const SizedBox(height: 8),
                  _button(
                    context,
                    title: 'btn_feedback'.l10n,
                    onPressed: () async {
                      await _mail(
                        context,
                        subject: '[Feedback] Feedback',
                        body: 'label_replace_this_text_with_feedback'.l10n,
                      );
                    },
                  ),
                ],
              ),
              Block(
                children: [
                  if (Config.downloadable && !PlatformUtils.isWeb) ...[
                    Obx(() {
                      return PrefixButton(
                        title: 'btn_check_for_updates'.l10n,
                        onPressed: c.checkingForUpdates.value
                            ? null
                            : c.checkForUpdates,
                        prefix: c.checkingForUpdates.value
                            ? const Padding(
                                key: Key('Loading'),
                                padding: EdgeInsets.only(left: 14),
                                child: CustomProgressIndicator(),
                              )
                            : null,
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'label_version_semicolon'.l10nfmt({'version': Pubspec.ref}),
                    style: style.fonts.small.regular.secondary,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Returns an [OutlinedRoundedButton] with the provided [title].
  Widget _button(
    BuildContext context, {
    required String title,
    void Function()? onPressed,
  }) {
    final style = Theme.of(context).style;

    return OutlinedRoundedButton(
      maxWidth: double.infinity,
      height: null,
      onPressed: onPressed,
      color: style.colors.primary,
      child: Text(
        title,
        style: style.fonts.medium.regular.onPrimary,
        maxLines: 10,
      ),
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
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
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
      await MessagePopup.error('label_contact_us_via_provided_email'.l10nfmt({
        'email': Config.support,
      }));
    }
  }
}
