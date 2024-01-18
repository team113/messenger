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

import 'package:flutter/material.dart';

import '/config.dart';
import '/themes.dart';
import '/ui/page/login/widget/prefix_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/web/web_utils.dart';

/// [PrefixButton] stylized with the provided [asset] and [title] downloading a
/// file by the specified [link] when pressed.
class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    this.asset,
    required this.title,
    this.link,
  });

  /// Constructs a [DownloadButton] for downloading the Windows application.
  const DownloadButton.windows({super.key})
      : asset = SvgIcons.windows,
        title = 'Windows',
        link = 'messenger-windows.zip';

  /// Constructs a [DownloadButton] for downloading the macOS application.
  const DownloadButton.macos({super.key})
      : asset = SvgIcons.apple,
        title = 'macOS',
        link = 'messenger-macos.zip';

  /// Constructs a [DownloadButton] for downloading the Linux application.
  const DownloadButton.linux({super.key})
      : asset = SvgIcons.linux,
        title = 'Linux',
        link = 'messenger-linux.zip';

  /// Constructs a [DownloadButton] for downloading the iOS application.
  const DownloadButton.appStore({super.key})
      : asset = SvgIcons.appStore,
        title = 'App Store',
        link = 'messenger-ios.zip';

  /// Constructs a [DownloadButton] for downloading the Android application from
  /// Google Play.
  const DownloadButton.googlePlay({super.key})
      : asset = SvgIcons.googlePlay,
        title = 'Google Play',
        link = 'messenger-android.apk';

  /// Constructs a [DownloadButton] for downloading the Android application.
  const DownloadButton.android({super.key})
      : asset = SvgIcons.android,
        title = 'Android',
        link = 'messenger-android.apk';

  /// Asset to display as a prefix to this [DownloadButton].
  final SvgData? asset;

  /// Title of this [DownloadButton].
  final String title;

  /// Relative link to the downloadable asset.
  final String? link;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return PrefixButton(
      title: title,
      onPressed: link == null
          ? null
          : () => WebUtils.download('${Config.origin}/artifacts/$link', link!),
      prefix: asset == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 20), child: SvgIcon(asset!)),
      style: link == null
          ? style.fonts.normal.regular.onBackground
          : style.fonts.normal.regular.primary,
    );
  }
}
