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

import '/domain/model/application_settings.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [ApplicationSettings.callButtonsPosition] value.
///
/// Intended to be displayed with the [show] method.
class CallButtonsSwitchView extends StatelessWidget {
  const CallButtonsSwitchView({super.key});

  /// Displays a [CallButtonsSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      child: const CallButtonsSwitchView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Duration duration = Duration(milliseconds: 250);

    return GetBuilder(
      init: CallButtonsSwitchController(Get.find()),
      builder: (CallButtonsSwitchController c) {
        return AnimatedSizeAndFade(
          fadeDuration: duration,
          sizeDuration: duration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(
                text: 'label_display_audio_and_video_call_buttons'.l10n,
              ),
              const SizedBox(height: 13),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: ModalPopup.padding(context),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: CallButtonsPosition.values.length,
                  itemBuilder: (_, i) {
                    final CallButtonsPosition position =
                        CallButtonsPosition.values[i];

                    return Obx(() {
                      return RectangleButton(
                        label: switch (position) {
                          CallButtonsPosition.appBar =>
                            'label_media_buttons_in_app_bar'.l10n,
                          CallButtonsPosition.contextMenu =>
                            'label_media_buttons_in_context_menu'.l10n,
                          CallButtonsPosition.top =>
                            'label_media_buttons_in_top'.l10n,
                          CallButtonsPosition.bottom =>
                            'label_media_buttons_in_bottom'.l10n,
                          CallButtonsPosition.more =>
                            'label_media_buttons_in_more'.l10n,
                        },
                        selected: position ==
                                c.settings.value?.callButtonsPosition ||
                            (c.settings.value?.callButtonsPosition == null &&
                                position == CallButtonsPosition.appBar),
                        onPressed: () => c.setCallButtonsPosition(position),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: ModalPopup.padding(context),
                child: Obx(() {
                  final asset = switch (c.settings.value?.callButtonsPosition) {
                    CallButtonsPosition.appBar || null => 'app_bar',
                    CallButtonsPosition.contextMenu => 'context_menu',
                    CallButtonsPosition.top => 'top',
                    CallButtonsPosition.bottom => 'bottom',
                    CallButtonsPosition.more => 'more',
                  };

                  return AspectRatio(
                    aspectRatio: 680 / 314,
                    child: SafeAnimatedSwitcher(
                      duration: duration,
                      child: Image.asset(
                        'assets/images/media_buttons/$asset.jpg',
                        key: Key(asset),
                        width: double.infinity,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
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
