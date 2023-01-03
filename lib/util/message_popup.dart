// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import 'localized_exception.dart';

/// Helper to display a popup message in UI.
class MessagePopup {
  /// Shows an error popup with the provided argument.
  static Future<void> error(dynamic e) async {
    var message = e is LocalizedExceptionMixin ? e.toMessage() : e.toString();
    await showDialog(
      context: router.context!,
      builder: (context) => AlertDialog(
        title: Text('label_error'.l10n),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(router.context!).pop(),
            child: Text('btn_ok'.l10n),
          )
        ],
      ),
    );
  }

  /// Shows an alert popup with [title], [description] and `yes`/`no` buttons
  /// that returns `true`, `false` or `null` based on the button that was
  /// pressed.
  static Future<bool?> alert(
    String title, {
    List<TextSpan> description = const [],
    List<Widget> additional = const [],
  }) {
    return ModalPopup.show(
      context: router.context!,
      child: Builder(
        builder: (context) {
          final TextStyle? thin = Theme.of(context)
              .textTheme
              .bodyText1
              ?.copyWith(color: Colors.black);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(
                header: Center(
                  child: Text(
                    title,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (description.isNotEmpty)
                      Padding(
                        padding: ModalPopup.padding(context),
                        child: RichText(
                          text: TextSpan(
                            children: description,
                            style: thin?.copyWith(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ...additional.map(
                      (e) => Padding(
                        padding: ModalPopup.padding(context),
                        child: e,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: ModalPopup.padding(context),
                child: OutlinedRoundedButton(
                  key: const Key('Proceed'),
                  maxWidth: double.infinity,
                  title: Text(
                    'btn_proceed'.l10n,
                    style: thin?.copyWith(color: Colors.white),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// Shows a [SnackBar] with the [title] message.
  static void success(String title) {
    ScaffoldMessenger.of(router.context!).showSnackBar(
      SnackBar(
        elevation: 6,
        width: 240,
        content: Text(title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          // side: BorderSide(color: const Color(0xFFB0B0B0)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
