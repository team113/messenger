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
import '/ui/page/home/widget/info_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
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
    return GetBuilder(
      init: DeleteSessionController(Get.find(), pop: context.popModal),
      builder: (DeleteSessionController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(text: 'label_delete_device'.l10n),
            const SizedBox(height: 13),
            Flexible(
              child: Padding(
                padding: ModalPopup.padding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoTile(
                      title: session.lastActivatedAt.val.yMdHm,
                      content: session.userAgent.deviceName,
                    ),
                    const SizedBox(height: 21),
                    Obx(() {
                      return ReactiveTextField(
                        key: const Key('PasswordField'),
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
                      );
                    }),
                    const SizedBox(height: 21),
                    Obx(() {
                      return PrimaryButton(
                        key: const Key('ProceedButton'),
                        onPressed: c.password.isEmpty.isTrue
                            ? null
                            : () => c.deleteSession(session),
                        title: 'btn_proceed'.l10n,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
