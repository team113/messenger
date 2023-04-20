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
import 'package:get/get.dart';

import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
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
    final Style style = Theme.of(context).extension<Style>()!;

    final TextStyle? thin = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: style.colors.onBackground);

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
              ModalPopupHeader(
                header: Center(
                  child: Text(
                    'label_language'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
              ),
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
                        final bool selected = c.selected.value == e;
                        return SizedBox(
                          key: Key('Language_${e.locale.languageCode}'),
                          child: Material(
                            borderRadius: BorderRadius.circular(10),
                            color: selected
                                ? style.cardSelectedColor.withOpacity(0.8)
                                : style.colors.onPrimary.darken(0.05),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => c.selected.value = e,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Text(
                                      'label_language_entry'.l10nfmt({
                                        'code':
                                            e.locale.languageCode.toUpperCase(),
                                        'name': e.name,
                                      }),
                                      style: const TextStyle(fontSize: 17),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: AnimatedSwitcher(
                                        duration: 200.milliseconds,
                                        child: selected
                                            ? CircleAvatar(
                                                backgroundColor:
                                                    style.colors.primary,
                                                radius: 12,
                                                child: Icon(
                                                  Icons.check,
                                                  color: style.colors.onPrimary,
                                                  size: 12,
                                                ),
                                              )
                                            : const SizedBox(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      });
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: L10n.languages.length,
                  ),
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
                    style: thin?.copyWith(color: style.colors.onPrimary),
                  ),
                  onPressed: () {
                    if (c.selected.value != null) {
                      c.setLocalization(c.selected.value!);
                    }

                    Navigator.of(context).pop();
                  },
                  color: style.colors.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
