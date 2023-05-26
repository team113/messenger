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
import 'package:medea_jason/medea_jason.dart';

import '../dense.dart';
import '/domain/model/media_settings.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';

/// [Widget] which returns the contents of a [ProfileTab.media] section.
class ProfileMedia extends StatelessWidget {
  const ProfileMedia(
    this.devices,
    this.media, {
    super.key,
    this.videoSwitch,
    this.microphoneSwitch,
    this.outputSwitch,
    this.videoText,
    this.audioText,
    this.outputText,
  });

  /// List of [MediaDeviceDetails] of all the available devices.
  final List<MediaDeviceDetails> devices;

  /// [MediaSettings] that returns the current media settings value.
  final MediaSettings? media;

  /// Label to display for the video control field.
  final String? videoText;

  /// Label to display for the audio control field.
  final String? audioText;

  /// Label to display for the output control field.
  final String? outputText;

  /// Callback, called when the video switch is toggled.
  final void Function()? videoSwitch;

  /// Callback, called when the microphone switch is toggled.
  final void Function()? microphoneSwitch;

  /// Callback, called when the output switch is toggled.
  final void Function()? outputSwitch;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dense(
          FieldButton(
            text: videoText,
            hint: 'label_media_camera'.l10n,
            onPressed: videoSwitch,
            style: TextStyle(color: style.colors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Dense(
          FieldButton(
            text: audioText,
            hint: 'label_media_microphone'.l10n,
            onPressed: microphoneSwitch,
            style: TextStyle(color: style.colors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Dense(
          FieldButton(
            text: outputText,
            hint: 'label_media_output'.l10n,
            onPressed: outputSwitch,
            style: TextStyle(color: style.colors.primary),
          ),
        ),
      ],
    );
  }
}
