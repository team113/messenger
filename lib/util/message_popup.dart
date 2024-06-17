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
import 'package:messenger/ui/page/login/widget/primary_button.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/floating_snack_bar.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import 'localized_exception.dart';

/// Helper to display a popup message in UI.
class MessagePopup {
  /// Shows an error popup with the provided argument.
  static Future<void> error(
    dynamic e, {
    String? title = 'label_error',
    Widget Function(BuildContext) button = _okButton,
  }) async {
    final message = e is LocalizedExceptionMixin ? e.toMessage() : e.toString();

    final style = Theme.of(router.context!).style;

    return ModalPopup.show(
      context: router.context!,
      child: Builder(
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(text: title?.l10n),
              const SizedBox(height: 13),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(
                        child: Text(
                          message,
                          style: style.fonts.normal.regular.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: ModalPopup.padding(context),
                child: button(context),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// Shows a confirmation popup with the specified [title], [description],
  /// and [additional] widgets to put under the [description].
  static Future<bool?> alert(
    String title, {
    List<TextSpan> description = const [],
    List<Widget> additional = const [],
    Widget Function(BuildContext) button = _defaultButton,
  }) {
    final style = Theme.of(router.context!).style;

    return ModalPopup.show(
      context: router.context!,
      child: Builder(
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(text: title),
              const SizedBox(height: 13),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (description.isNotEmpty)
                      Padding(
                        padding: ModalPopup.padding(context),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              children: description,
                              style: style.fonts.normal.regular.secondary,
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
                child: button(context),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// Shows a [FloatingSnackBar] with the [title] message.
  static void success(
    String title, {
    double bottom = 16,
    Offset? at,
  }) =>
      FloatingSnackBar.show(title, bottom: bottom, at: at);

  /// Returns the proceed button, which invokes [NavigatorState.pop].
  static Widget _defaultButton(BuildContext context) {
    final style = Theme.of(context).style;

    return OutlinedRoundedButton(
      key: const Key('Proceed'),
      maxWidth: double.infinity,
      onPressed: () => Navigator.of(context).pop(true),
      color: style.colors.primary,
      child: Text(
        'btn_proceed'.l10n,
        style: style.fonts.normal.regular.onPrimary,
      ),
    );
  }

  /// Returns the proceed button, which invokes [NavigatorState.pop].
  static Widget _okButton(BuildContext context) {
    return PrimaryButton(
      key: const Key('Ok'),
      onPressed: () => Navigator.of(context).pop(true),
      title: 'btn_ok'.l10n,
    );
  }
}
