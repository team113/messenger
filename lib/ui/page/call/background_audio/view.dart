// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import 'controller.dart';

/// Disclaimer displayed with a text regarding outgoing microphone and camera
/// not working in background.
class BackgroundAudioDisclaimerView extends StatelessWidget {
  const BackgroundAudioDisclaimerView({super.key});

  /// Displays a [BackgroundAudioDisclaimerView] wrapped in a [ModalPopup].
  static Future<bool?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      child: BackgroundAudioDisclaimerView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: BackgroundAudioDisclaimerController(),
      builder: (BackgroundAudioDisclaimerController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(text: 'label_attention'.l10n),
            Padding(
              padding: ModalPopup.padding(context),
              child: Text(
                'label_ongoing_audio_and_video_may_be_blocked'.l10n,
                style: style.fonts.small.regular.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: ModalPopup.padding(context),
              child: PrimaryButton(
                title: 'btn_ok'.l10n,
                onPressed: Navigator.of(context).pop,
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
