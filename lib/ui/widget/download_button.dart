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
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/login/widget/prefix_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

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
  const DownloadButton.windows({super.key, this.link = 'messenger-windows.zip'})
      : asset = SvgIcons.windows,
        title = 'Windows';

  /// Constructs a [DownloadButton] for downloading the macOS application.
  const DownloadButton.macos({super.key, this.link = 'messenger-macos.zip'})
      : asset = SvgIcons.apple,
        title = 'macOS';

  /// Constructs a [DownloadButton] for downloading the Linux application.
  const DownloadButton.linux({super.key, this.link = 'messenger-linux.zip'})
      : asset = SvgIcons.linux,
        title = 'Linux';

  /// Constructs a [DownloadButton] for downloading the iOS application.
  const DownloadButton.appStore({super.key, this.link = 'messenger-ios.zip'})
      : asset = SvgIcons.appStore,
        title = 'App Store';

  /// Constructs a [DownloadButton] for downloading the Android application from
  /// Google Play.
  const DownloadButton.googlePlay({
    super.key,
    this.link = 'messenger-android.apk',
  })  : asset = SvgIcons.googlePlay,
        title = 'Google Play';

  /// Constructs a [DownloadButton] for downloading the Android application.
  const DownloadButton.android({super.key, this.link = 'messenger-android.apk'})
      : asset = SvgIcons.android,
        title = 'Android';

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
          : () async {
              String url = link!;

              if (!url.startsWith('http')) {
                url = '${Config.origin}/artifacts/$url';
              }

              final file = await PlatformUtils.saveTo(url);
              if (file != null) {
                MessagePopup.success('label_file_downloaded'.l10n);
              }
            },
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
