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

import '/domain/model/session.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for deleting a [Session].
///
/// Intended to be displayed with the [show] method.
class DeleteSessionView extends StatelessWidget {
  const DeleteSessionView({super.key, required this.session});

  /// [Session] to delete.
  final Session session;

  /// Displays a [DeleteSessionView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, Session session) {
    return ModalPopup.show(
      context: context,
      child: DeleteSessionView(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: DeleteSessionController(
        session,
        Get.find(),
        Get.find(),
        pop: context.popModal,
      ),
      builder: (DeleteSessionController c) {
        return Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalPopupHeader(
                text: 'label_delete_device'.l10n,
              ),
              const SizedBox(height: 13),
              Flexible(
                child: Padding(
                  padding: ModalPopup.padding(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          session.userAgent.deviceName,
                          style: style.fonts.big.regular.onBackground,
                        ),
                      ),
                      const SizedBox(height: 21),
                      ReactiveTextField(
                        state: c.password,
                        label: 'label_current_password'.l10n,
                        obscure: c.obscurePassword.value,
                        onSuffixPressed: c.obscurePassword.toggle,
                        treatErrorAsStatus: false,
                        trailing: SvgIcon(
                          c.obscurePassword.value
                              ? SvgIcons.visibleOff
                              : SvgIcons.visibleOn,
                        ),
                      ),
                      const SizedBox(height: 21),
                      OutlinedRoundedButton(
                        key: const Key('Close'),
                        maxWidth: double.infinity,
                        onPressed: c.deleteSession,
                        color: style.colors.primary,
                        child: Text(
                          'btn_proceed'.l10n,
                          style: style.fonts.normal.regular.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        });
      },
    );
  }
}
