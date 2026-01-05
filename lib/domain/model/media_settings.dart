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

import 'package:medea_jason/medea_jason.dart' show NoiseSuppressionLevel;

import '/domain/model/ongoing_call.dart';

/// Media settings used in an [OngoingCall] containing the IDs of the devices to
/// use by default.
class MediaSettings {
  MediaSettings({
    this.videoDevice,
    this.audioDevice,
    this.outputDevice,
    this.screenDevice,
    this.noiseSuppression = true,
    this.noiseSuppressionLevel = NoiseSuppressionLevel.veryHigh,
    this.echoCancellation = true,
    this.autoGainControl = true,
    this.highPassFilter = true,
  });

  /// ID of the video device to use by default.
  String? videoDevice;

  /// ID of the microphone device to use by default.
  String? audioDevice;

  /// ID of the output device to use by default.
  String? outputDevice;

  /// ID of the screen to use in screen sharing by default.
  String? screenDevice;

  /// Indicator whether noise suppression should be enabled for local tracks.
  bool? noiseSuppression;

  /// Desired noise suppression level for local tracks, if enabled.
  NoiseSuppressionLevel? noiseSuppressionLevel;

  /// Indicator whether echo cancellation should be enabled for local tracks.
  bool? echoCancellation;

  /// Indicator whether auto gain control should be enabled for local tracks.
  bool? autoGainControl;

  /// Indicator whether high pass filter should be enabled for local tracks.
  bool? highPassFilter;
}
