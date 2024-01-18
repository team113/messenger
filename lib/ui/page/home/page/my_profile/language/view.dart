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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for changing the [L10n.chosen].
///
/// Intended to be displayed with the [show] method.
class LanguageSelectionView extends StatelessWidget {
  const LanguageSelectionView(this.settingsRepository, {super.key});

  /// [AbstractSettingsRepository] persisting the selected [Language].
  final AbstractSettingsRepository? settingsRepository;

  /// Displays a [LanguageSelectionView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    AbstractSettingsRepository? settingsRepository,
  ) {
    return ModalPopup.show(
      context: context,
      child: LanguageSelectionView(settingsRepository),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: LanguageSelectionController(settingsRepository),
      builder: (LanguageSelectionController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(text: 'label_language'.l10n),
              const SizedBox(height: 4),
              Flexible(
                child: Scrollbar(
                  controller: c.scrollController,
                  child: ListView.separated(
                    controller: c.scrollController,
                    shrinkWrap: true,
                    padding: ModalPopup.padding(context),
                    itemBuilder: (context, i) {
                      final Language e = L10n.languages[i];

                      return Obx(() {
                        return RectangleButton(
                          key: Key('Language_${e.locale.languageCode}'),
                          label: 'label_language_entry'.l10nfmt({
                            'code': e.locale.languageCode.toUpperCase(),
                            'name': e.name,
                          }),
                          selected: c.selected.value == e,
                          onPressed: () async {
                            c.selected.value = e;

                            if (c.selected.value != null) {
                              await c.setLocalization(c.selected.value!);
                            }
                          },
                        );
                      });
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: L10n.languages.length,
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }
}
