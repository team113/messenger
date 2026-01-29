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

import 'package:get/get.dart';

import '/ui/widget/svg/svg.dart';

/// Controller of a [IconsView].
class IconsController extends GetxController {
  /// Currently selected [IconDetails] to display.
  final Rx<IconDetails?> icon = Rx(
    IconDetails(
      'application/iOS.png',
      invert: true,
      download: 'application/iOS.zip',
    ),
  );
}

/// [SvgData] or its path representing a single icon.
class IconDetails {
  IconDetails(String asset, {this.invert = false, this.download})
    : data = null,
      asset = asset.replaceFirst('assets/icons/', '');

  IconDetails.svg(this.data, {this.invert = false, this.download})
    : asset = null;

  /// Path to the asset these details represent.
  final String? asset;

  /// [SvgData] these details represent.
  final SvgData? data;

  /// Indicator whether the icon represented should be presented on the inverted
  /// background.
  final bool invert;

  /// Path to the asset to download.
  final String? download;
}
