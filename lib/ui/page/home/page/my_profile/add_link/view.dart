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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/config.dart';
import '/domain/model/link.dart';
import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View displaying a [DirectLink] input.
class AddLinkView extends StatelessWidget {
  const AddLinkView({super.key, this.onAdded});

  /// Callback, called when a new [DirectLinkSlug] is submitted.
  final FutureOr<void> Function(DirectLinkSlug)? onAdded;

  /// Displays a [AddLinkView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    FutureOr<void> Function(DirectLinkSlug)? onAdded,
  }) {
    return ModalPopup.show(
      context: context,
      child: AddLinkView(onAdded: onAdded),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: AddLinkController(onAdded: onAdded, pop: context.popModal),
      builder: (AddLinkController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(text: 'label_add_link'.l10n),
            Flexible(
              child: ListView(
                padding: ModalPopup.padding(context),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.state,
                    hint: c.generated,
                    floatingAccent: true,
                    label: 'label_add_link'.l10n,
                    prefixText: Config.link,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    spellCheck: false,
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    key: const Key('CreateLinkButton'),
                    title: 'btn_save_and_copy'.l10n,
                    onPressed: () async {
                      if (c.state.text.isEmpty) {
                        c.state.text = c.generated;
                      }

                      PlatformUtils.copy(text: '${Config.link}${c.state.text}');
                      MessagePopup.success('label_copied'.l10n);

                      await c.submit();
                    },
                    leading: SvgIcon(SvgIcons.copy19White),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
