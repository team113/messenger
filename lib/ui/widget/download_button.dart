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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'progress_indicator.dart';

/// [FieldButton] stylized with the provided [asset] and [title] downloading a
/// file by the specified [link] when pressed.
class DownloadButton extends StatefulWidget {
  /// Constructs a [DownloadButton] for downloading the Windows application.
  const DownloadButton.windows({
    super.key,
    this.link = 'messenger-windows.zip',
    this.onPressed,
  }) : asset = SvgIcons.windows11,
       title = 'Windows',
       download = true;

  /// Constructs a [DownloadButton] for downloading the macOS application.
  const DownloadButton.macos({
    super.key,
    this.link = 'messenger-macos.zip',
    this.onPressed,
  }) : asset = SvgIcons.apple,
       title = 'macOS',
       download = true;

  /// Constructs a [DownloadButton] for downloading the Linux application.
  const DownloadButton.linux({
    super.key,
    this.link = 'messenger-linux.zip',
    this.onPressed,
  }) : asset = SvgIcons.linux,
       title = 'Linux',
       download = true;

  /// Constructs a [DownloadButton] for downloading the iOS application.
  const DownloadButton.ios({
    super.key,
    this.link = 'messenger-ios.ipa',
    this.onPressed,
  }) : asset = SvgIcons.appleBlack,
       title = 'btn_install_ios',
       download = true;

  /// Constructs a [DownloadButton] for downloading the iOS application from App
  /// Store.
  DownloadButton.appStore({super.key, this.onPressed})
    : asset = SvgIcons.appStore,
      title = 'App Store',
      link = Config.appStoreUrl,
      download = false;

  /// Constructs a [DownloadButton] for downloading the Android application.
  const DownloadButton.android({
    super.key,
    this.link = 'messenger-android.apk',
    this.onPressed,
  }) : asset = SvgIcons.android,
       title = 'btn_install_android',
       download = true;

  /// Constructs a [DownloadButton] for downloading the Android application from
  /// Google Play.
  DownloadButton.googlePlay({super.key, this.onPressed})
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

  /// Callback, called when this [DownloadButton] is pressed.
  final void Function()? onPressed;

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

    return FieldButton(
      text: switch (widget.title) {
        'btn_install_ios' => 'btn_install_ios'.l10n,
        'btn_install_android' => 'btn_install_android'.l10n,
        (_) => widget.title,
      },
      onPressed: widget.link == null || _progress != null
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
              } on DioException catch (e) {
                if (mounted) {
                  setState(() => _progress = null);
                }

                // Try to open the link, if a connection error happens.
                switch (e.type) {
                  case DioExceptionType.connectionTimeout:
                  case DioExceptionType.sendTimeout:
                  case DioExceptionType.receiveTimeout:
                  case DioExceptionType.badCertificate:
                  case DioExceptionType.badResponse:
                  case DioExceptionType.connectionError:
                    await launchUrlString(widget.link!);
                    break;

                  case DioExceptionType.cancel:
                    // No-op.
                    break;

                  case DioExceptionType.unknown:
                    rethrow;
                }
              } finally {
                if (mounted) {
                  setState(() => _progress = null);
                }
              }
            }
          : () => launchUrlString(widget.link!),
      trailing: widget.asset == null
          ? null
          : _progress == null
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SvgIcon(widget.asset!),
            )
          : Padding(
              key: const Key('Loading'),
              padding: const EdgeInsets.only(left: 2),
              child: CustomProgressIndicator.small(value: _progress),
            ),
      style: style.fonts.normal.regular.onBackground,
    );
  }
}
