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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '../controller.dart';
import '/ui/page/home/page/my_profile/language/controller.dart';

/// Language selector that can be used to select a language and display
/// the currently selected language.
class CupertinoPopUp extends StatelessWidget {
  const CupertinoPopUp(this.c, {super.key});

  /// Responsible for displaying the language.
  final AuthController c;

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        context.textTheme.bodySmall?.copyWith(color: Colors.black);
    final Color primary = Theme.of(context).colorScheme.primary;
    return CupertinoButton(
      key: c.languageKey,
      child: Text(
        'label_language_entry'.l10nfmt({
          'code': L10n.chosen.value!.locale.countryCode,
          'name': L10n.chosen.value!.name,
        }),
        style: thin?.copyWith(fontSize: 13, color: primary),
      ),
      onPressed: () => LanguageSelectionView.show(context, null),
    );
  }
}
