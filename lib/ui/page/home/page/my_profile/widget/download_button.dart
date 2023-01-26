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
import 'package:flutter/services.dart';

import '/config.dart';
import '/l10n/l10n.dart';
import '/ui/widget/svg/svg.dart';
import '/util/message_popup.dart';
import '/util/web/web_utils.dart';
import 'field_button.dart';

/// [FieldButton] stylized with the provided [asset] and [title] downloading a
/// file by the specified [link] when pressed.
class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    this.asset,
    this.width,
    this.height,
    required this.title,
    this.link,
  });

  /// Asset to display as a prefix to this [DownloadButton].
  final String? asset;

  /// Width of the [asset].
  final double? width;

  /// Height of the [asset].
  final double? height;

  /// Title of this [DownloadButton].
  final String title;

  /// Relative link to the downloadable asset.
  final String? link;

  @override
  Widget build(BuildContext context) {
    return FieldButton(
      text: 'space'.l10n * 4 + title,
      textAlign: TextAlign.center,
      onPressed: link == null
          ? null
          : () => WebUtils.download('${Config.origin}/artifacts/$link', link!),
      onTrailingPressed: () {
        if (link != null) {
          Clipboard.setData(
            ClipboardData(text: '${Config.origin}/artifacts/$link'),
          );
          MessagePopup.success('label_copied'.l10n);
        }
      },
      prefix: asset == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Transform.scale(
                scale: 2,
                child: SvgLoader.asset(
                  'assets/icons/$asset.svg',
                  width: width == null ? null : width! / 2,
                  height: height == null ? null : height! / 2,
                ),
              ),
            ),
      trailing: Transform.translate(
        offset: const Offset(0, -1),
        child: Transform.scale(
          scale: 1.15,
          child: SvgLoader.asset('assets/icons/copy.svg', height: 15),
        ),
      ),
      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
    );
  }
}
