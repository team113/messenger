// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/login/widget/prefix_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'progress_indicator.dart';

/// [PrefixButton] stylized with the provided [asset] and [title] downloading a
/// file by the specified [link] when pressed.
class DownloadButton extends StatefulWidget {
  /// Constructs a [DownloadButton] for downloading the Windows application.
  const DownloadButton.windows({super.key, this.link = 'messenger-windows.zip'})
    : asset = SvgIcons.windows11,
      title = 'Windows',
      download = true;

  /// Constructs a [DownloadButton] for downloading the macOS application.
  const DownloadButton.macos({super.key, this.link = 'messenger-macos.zip'})
    : asset = SvgIcons.apple,
      title = 'macOS',
      download = true;

  /// Constructs a [DownloadButton] for downloading the Linux application.
  const DownloadButton.linux({super.key, this.link = 'messenger-linux.zip'})
    : asset = SvgIcons.linux,
      title = 'Linux',
      download = true;

  /// Constructs a [DownloadButton] for downloading the iOS application.
  const DownloadButton.ios({super.key, this.link = 'messenger-ios.ipa'})
    : asset = SvgIcons.appleBlack,
      title = 'iOS',
      download = true;

  /// Constructs a [DownloadButton] for downloading the iOS application from App
  /// Store.
  DownloadButton.appStore({super.key})
    : asset = SvgIcons.appStore,
      title = 'App Store',
      link = Config.appStoreUrl,
      download = false;

  /// Constructs a [DownloadButton] for downloading the Android application.
  const DownloadButton.android({super.key, this.link = 'messenger-android.apk'})
    : asset = SvgIcons.android,
      title = 'Android',
      download = true;

  /// Constructs a [DownloadButton] for downloading the Android application from
  /// Google Play.
  DownloadButton.googlePlay({super.key})
    : asset = SvgIcons.googlePlay,
      title = 'Google Play',
      link = Config.googlePlayUrl,
      download = false;

  /// Asset to display as a prefix to this [DownloadButton].
  final SvgData? asset;

  /// Title of this [DownloadButton].
  final String title;

  /// Relative link to the downloadable asset.
  final String? link;

  /// Indicator whether whatever hosted at [link] should be downloaded, or
  /// simply launched otherwise.
  final bool download;

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

/// [State] of a [DownloadButton] to display progress of
/// [PlatformUtilsImpl.saveTo].
class _DownloadButtonState extends State<DownloadButton> {
  /// [PlatformUtilsImpl.saveTo] current progress, if any.
  double? _progress;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return PrefixButton(
      title: widget.title,
      onPressed:
          widget.link == null || _progress != null
              ? null
              : widget.download
              ? () async {
                String url = widget.link!;

                if (!url.startsWith('http')) {
                  url = '${Config.origin}/artifacts/$url';
                }

                if (mounted) {
                  setState(() => _progress = 0);
                }

                try {
                  final file = await PlatformUtils.saveTo(
                    url,
                    onReceiveProgress: (a, b) {
                      if (b != 0) {
                        _progress = a / b;
                        setState(() {});
                      }
                    },
                  );

                  if (file != null) {
                    MessagePopup.success('label_file_downloaded'.l10n);
                  }
                } finally {
                  if (mounted) {
                    setState(() => _progress = null);
                  }
                }
              }
              : () => launchUrlString(widget.link!),
      prefix:
          widget.asset == null
              ? null
              : _progress == null
              ? Padding(
                padding: const EdgeInsets.only(left: 20),
                child: SvgIcon(widget.asset!),
              )
              : Padding(
                key: const Key('Loading'),
                padding: const EdgeInsets.only(left: 14),
                child: CustomProgressIndicator.small(value: _progress),
              ),
      style:
          widget.link == null
              ? style.fonts.normal.regular.onBackground
              : style.fonts.normal.regular.primary,
    );
  }
}
