// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class DeleteEmailView extends StatelessWidget {
  const DeleteEmailView(this.email, {Key? key, required this.onSubmit})
      : super(key: key);

  final UserEmail email;

  final void Function() onSubmit;

  /// Displays a [DeleteEmailView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required UserEmail email,
    required void Function() onSubmit,
  }) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      showPrimaryCloseButton: false,
      child: DeleteEmailView(email, onSubmit: onSubmit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return AnimatedSizeAndFade(
      fadeDuration: const Duration(milliseconds: 250),
      sizeDuration: const Duration(milliseconds: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16 - 12),
          ModalPopupHeader(
            header: Center(
              child: Text(
                'label_delete_email'.l10n,
                style: thin?.copyWith(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 25 - 12),
          Padding(
            padding: ModalPopup.padding(context),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '${'label_email'.l10n}${'space'.l10n}'),
                  TextSpan(
                    text: email.val,
                    style: const TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                      text:
                          '${'space'.l10n}${'label_will_be_removed'.l10n}${'dot'.l10n}'),
                ],
                style: thin?.copyWith(
                  fontSize: 15,
                  color: const Color(0xFF888888),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Padding(
            padding: ModalPopup.padding(context),
            child: OutlinedRoundedButton(
              key: const Key('Proceed'),
              maxWidth: null,
              title: Text(
                'btn_proceed'.l10n,
                style: thin?.copyWith(color: Colors.white),
              ),
              onPressed: () {
                // c.deleteEmail();
                onSubmit.call();
                Navigator.of(context).pop();
              },
              color: const Color(0xFF63B4FF),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
