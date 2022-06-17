// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:hive/hive.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/model_type_id.dart';

part 'media_settings.g.dart';

/// Media settings used in an [OngoingCall] containing the IDs of the devices to
/// use by default.
@HiveType(typeId: ModelTypeId.mediaSettings)
class MediaSettings extends HiveObject {
  MediaSettings({
    this.videoDevice,
    this.audioDevice,
    this.outputDevice,
  });

  /// ID of the video device to use by default.
  @HiveField(0)
  String? videoDevice;

  /// ID of the microphone device to use by default.
  @HiveField(1)
  String? audioDevice;

  /// ID of the output device to use by default.
  @HiveField(2)
  String? outputDevice;
}
