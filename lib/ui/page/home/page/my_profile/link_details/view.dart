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

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';

/// View showing details about a direct link.
///
/// Intended to be displayed with the [show] method.
class LinkDetailsView extends StatelessWidget {
  const LinkDetailsView({Key? key}) : super(key: key);

  /// Displays a [LinkDetailsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
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
      child: const LinkDetailsView(),
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
                'label_your_chat_link'.l10n,
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
                  TextSpan(text: 'label_direct_chat_link_description'.l10n),
                ],
                style: thin?.copyWith(
                  fontSize: 15,
                  color: const Color(0xFF888888),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
