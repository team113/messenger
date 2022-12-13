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

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';

/// View for displaying confirmation of deleting some [ChatContact]s record.
///
/// Intended to be displayed with the [show] method.
class DeleteContactRecordView extends StatelessWidget {
  const DeleteContactRecordView(
    this.onSubmit, {
    Key? key,
    this.email,
    this.phone,
  }) : super(key: key);

  /// That [UserEmail] would be deleted.
  final UserEmail? email;

  /// That [UserPhone] would be deleted.
  final UserPhone? phone;

  /// Callback called when submit button was pressed.
  final void Function() onSubmit;

  /// Displays a [DeleteContactRecordView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required void Function() onSubmit,
    UserEmail? email,
    UserPhone? phone,
  }) {
    assert(
      email == null && phone != null || email != null && phone == null,
      'Only email or phone should be specified',
    );
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
      child: DeleteContactRecordView(onSubmit, email: email, phone: phone),
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
          const SizedBox(height: 4),
          ModalPopupHeader(
            header: Center(
              child: Text(
                email != null
                    ? 'label_delete_email'.l10n
                    : 'label_delete_phone_number'.l10n,
                style: thin?.copyWith(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 13),
          Padding(
            padding: ModalPopup.padding(context),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text:
                          '${email != null ? 'label_email'.l10n : 'label_phone_number'.l10n}${'space'.l10n}'),
                  TextSpan(
                    text: email?.val ?? phone!.val,
                    style: const TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text:
                        '${'space'.l10n}${'label_will_be_removed'.l10n}${'dot'.l10n}',
                  )
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
