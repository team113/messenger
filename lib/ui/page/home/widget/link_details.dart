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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/widget/modal_popup.dart';

/// View showing details about a chat direct link.
///
/// Intended to be displayed with the [show] method.
class LinkDetails extends StatelessWidget {
  const LinkDetails({super.key, this.header, this.description});

  /// Header text of this [LinkDetails].
  final String? header;

  /// Description text of this [LinkDetails].
  final String? description;

  /// Displays a [LinkDetails] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    String header,
    String description,
  ) {
    return ModalPopup.show(
      context: context,
      child: LinkDetails(
        description: description,
        header: header,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return AnimatedSizeAndFade(
      fadeDuration: const Duration(milliseconds: 250),
      sizeDuration: const Duration(milliseconds: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          ModalPopupHeader(text: header),
          const SizedBox(height: 13),
          Padding(
            padding: ModalPopup.padding(context),
            child: RichText(
              text: TextSpan(
                children: [TextSpan(text: description)],
                style: fonts.bodyMedium!.copyWith(
                  color: style.colors.secondary,
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
