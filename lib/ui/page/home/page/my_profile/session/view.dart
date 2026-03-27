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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/session.dart';
import '/domain/repository/session.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/widget/session_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for deleting a [Session].
///
/// Intended to be displayed with the [show] method.
class DeleteSessionView extends StatelessWidget {
  const DeleteSessionView({
    super.key,
    this.sessions = const [],
    this.exceptCurrent = false,
  });

  /// [Session]s to delete.
  final List<RxSession> sessions;

  /// Indicator whether the [sessions] don't include the current.
  final bool exceptCurrent;

  /// Displays a [DeleteSessionView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    List<RxSession> sessions, {
    bool exceptCurrent = false,
  }) {
    return ModalPopup.show(
      context: context,
      child: DeleteSessionView(
        sessions: sessions,
        exceptCurrent: exceptCurrent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: DeleteSessionController(
        Get.find(),
        Get.find(),
        pop: context.popModal,
        sessions: sessions,
      ),
      builder: (DeleteSessionController c) {
        return Obx(() {
          final List<Widget> children;

          switch (c.stage.value) {
            case DeleteSessionStage.info:
              children = [
                ModalPopupHeader(text: 'label_terminate_sessions'.l10n),
                const SizedBox(height: 13),
                Flexible(
                  child: ListView(
                    padding: ModalPopup.padding(context),
                    shrinkWrap: true,
                    children: [
                      if (sessions.length > 1 || exceptCurrent)
                        Center(
                          child: Text(
                            'label_all_session_except_current_terminated'.l10n,
                            style: style.fonts.small.regular.secondary,
                          ),
                        )
                      else
                        SessionTileWidget(sessions.first),
                      SizedBox(height: 21),
                      PrimaryButton(
                        key: const Key('ProceedButton'),
                        onPressed: () =>
                            c.stage.value = DeleteSessionStage.confirm,
                        title: 'btn_proceed'.l10n,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case DeleteSessionStage.confirm:
              final bool hasPassword = c.myUser.value?.hasPassword == true;
              final bool hasEmail =
                  c.myUser.value?.emails.confirmed.isNotEmpty == true;

              children = [
                ModalPopupHeader(text: 'label_terminate_sessions'.l10n),
                const SizedBox(height: 13),
                Flexible(
                  child: ListView(
                    padding: ModalPopup.padding(context),
                    shrinkWrap: true,
                    children: [
                      if (hasEmail) ...[
                        Text(
                          hasPassword
                              ? 'label_enter_password_or_one_time_code'.l10n
                              : 'label_enter_one_time_code'.l10n,
                          style: style.fonts.small.regular.secondary,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (hasEmail || hasPassword) ...[
                        const SizedBox(height: 7),
                        ReactiveTextField.password(
                          key: const Key('PasswordField'),
                          state: c.password,
                          label: hasEmail && hasPassword
                              ? 'label_password_or_one_time_code'.l10n
                              : hasEmail
                              ? 'label_one_time_password'.l10n
                              : 'label_password'.l10n,
                          hint: hasEmail && hasPassword
                              ? 'label_enter_password_or_code'.l10n
                              : hasEmail
                              ? 'label_enter_code'.l10n
                              : 'label_enter_password'.l10n,
                          obscured: c.obscurePassword,
                          treatErrorAsStatus: false,
                        ),
                        const SizedBox(height: 21),
                      ],
                      Obx(() {
                        return Row(
                          children: [
                            if (hasEmail) ...[
                              Expanded(
                                child: PrimaryButton(
                                  key: const Key('Resend'),
                                  onPressed: c.resendEmailTimeout.value == 0
                                      ? c.sendConfirmationCode
                                      : null,
                                  title: c.resendEmailTimeout.value == 0
                                      ? 'label_resend'.l10n
                                      : 'label_resend_timeout'.l10nfmt({
                                          'timeout': c.resendEmailTimeout.value,
                                        }),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: PrimaryButton(
                                key: const Key('ProceedButton'),
                                danger: true,
                                onPressed:
                                    c.password.isEmpty.isTrue &&
                                        (hasEmail || hasPassword)
                                    ? null
                                    : c.password.submit,
                                title: 'btn_terminate'.l10n,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case DeleteSessionStage.done:
              children = [
                ModalPopupHeader(text: 'label_terminate_sessions'.l10n),
                const SizedBox(height: 13),
                Text(
                  'label_sessions_terminated'.l10n,
                  textAlign: TextAlign.center,
                  style: style.fonts.small.regular.secondary,
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: PrimaryButton(
                    onPressed: Navigator.of(context).pop,
                    title: 'btn_ok'.l10n,
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: Duration(milliseconds: 250),
            sizeDuration: Duration(milliseconds: 250),
            child: Column(
              key: Key('${c.stage.value}'),
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          );
        });
      },
    );
  }
}
