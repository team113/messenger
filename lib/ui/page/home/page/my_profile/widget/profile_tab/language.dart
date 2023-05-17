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
import 'package:get/get.dart';

import '../dense.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/my_profile/language/view.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';

/// [Widget] which returns the contents of a [ProfileTab.language] section.
class ProfileLanguage extends StatelessWidget {
  const ProfileLanguage({super.key});

  @override
  Widget build(BuildContext context) {
    return Dense(
      FieldButton(
        key: const Key('ChangeLanguage'),
        onPressed: () => LanguageSelectionView.show(
          context,
          Get.find<AbstractSettingsRepository>(),
        ),
        text: 'label_language_entry'.l10nfmt({
          'code': L10n.chosen.value!.locale.countryCode,
          'name': L10n.chosen.value!.name,
        }),
        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }
}
