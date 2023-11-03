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

import '/domain/model/application_settings.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [ApplicationSettings.timelineEnabled] value.
///
/// Intended to be displayed with the [show] method.
class MediaButtonsSwitchView extends StatelessWidget {
  const MediaButtonsSwitchView({super.key});

  /// Displays a [MediaButtonsSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      child: const MediaButtonsSwitchView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: MediaButtonsSwitchController(Get.find()),
      builder: (MediaButtonsSwitchController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(
                text: 'Отображать кнопки аудио и видео звонка'.l10n,
              ),
              const SizedBox(height: 13),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: ModalPopup.padding(context),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: MediaButtonsPosition.values.length,
                  itemBuilder: (_, i) {
                    final MediaButtonsPosition position =
                        MediaButtonsPosition.values[i];

                    return Obx(() {
                      return RectangleButton(
                        selected:
                            position == c.settings.value?.mediaButtonsPosition,
                        onPressed: () => c.setMediaButtonsPosition(position),
                        label: switch (position) {
                          MediaButtonsPosition.appBar => 'В верхней панели',
                          MediaButtonsPosition.contextMenu =>
                            'В контекстном меню',
                          MediaButtonsPosition.top => 'В теле сверху',
                          MediaButtonsPosition.bottom => 'В теле снизу',
                          MediaButtonsPosition.more => 'В поле сообщения',
                        },
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: ModalPopup.padding(context),
                child: Obx(() {
                  final asset =
                      switch (c.settings.value?.mediaButtonsPosition) {
                    MediaButtonsPosition.appBar => 'context_menu',
                    MediaButtonsPosition.contextMenu => 'context_menu',
                    MediaButtonsPosition.top => 'context_menu',
                    MediaButtonsPosition.bottom => 'context_menu',
                    MediaButtonsPosition.more => 'context_menu',
                    null => '',
                  };

                  return Image.asset(
                    'assets/images/media_buttons/$asset.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
