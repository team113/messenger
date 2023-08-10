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

import '/config.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// [FieldButton] stylized with the provided [asset] and [title] downloading a
/// file by the specified [link] when pressed.
class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    this.asset,
    this.width,
    this.height,
    this.left = 0,
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

  final double left;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return FieldButton(
      text: 'space'.l10n * 4 + title,
      textAlign: TextAlign.center,
      onPressed: link == null
          ? null
          : () => WebUtils.download('${Config.origin}/artifacts/$link', link!),
      onTrailingPressed: () {
        if (link != null) {
          PlatformUtils.copy(text: '${Config.origin}/artifacts/$link');
          MessagePopup.success('label_copied'.l10n);
        }
      },
      prefix: asset == null
          ? null
          : Padding(
              padding: EdgeInsets.only(left: 4 + left),
              child: SvgImage.asset(
                'assets/icons/$asset.svg',
                width: width,
                height: height,
              ),
            ),
      // trailing: Transform.translate(
      //   offset: const Offset(-3, 0),
      //   child: Transform.scale(
      //     scale: 1.15,
      //     child: SvgImage.asset('assets/icons/copy.svg', height: 15),
      //   ),
      // ),
      style: style.fonts.titleMedium.copyWith(color: style.colors.primary),
    );
  }
}

class PrefixButton extends StatelessWidget {
  const PrefixButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.style,
    this.prefix,
  });

  final String text;
  final TextStyle? style;
  final void Function()? onPressed;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        FieldButton(
          text: text,
          maxLines: null,
          style: style,
          onPressed: onPressed,
          textAlign: TextAlign.center,
        ),
        if (prefix != null) IgnorePointer(child: prefix!),
      ],
    );
  }
}
