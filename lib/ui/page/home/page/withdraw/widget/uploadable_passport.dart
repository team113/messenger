// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '/domain/model/attachment.dart';
import '/domain/model/native_file.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// Clickable [NativeFile] representation widget intended to be used as an
/// uploadable passport document view.
class UploadablePassport extends StatelessWidget {
  const UploadablePassport({
    super.key,
    this.onPressed,
    this.file,
    this.blurred = false,
    this.onUnblur,
  });

  /// Callback, called when a new [NativeFile] is required to be picked.
  final void Function()? onPressed;

  /// [NativeFile] to display, if any.
  final NativeFile? file;

  /// Indicator whether the [file] should be blurred.
  final bool blurred;

  /// Callback, called when the [blurred] file is clicked.
  final void Function()? onUnblur;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    if (file == null) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: style.colors.onSecondary,
            ),
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: AspectRatio(
                aspectRatio: 192 / 133,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: style.colors.onBackgroundOpacity40,
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: SvgImage.asset(
                    'assets/images/passport.svg',
                    height: 140,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'btn_upload_photo'.l10n,
                  style: style.fonts.small.regular.primary,
                  recognizer: TapGestureRecognizer()..onTap = onPressed,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final media = MediaAttachment(
      attachment: LocalAttachment(file!),
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
    );

    return Column(
      children: [
        WidgetButton(
          onPressed: blurred ? onUnblur : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: blurred
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: media,
                  )
                : media,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'btn_replace_photo'.l10n,
                style: style.fonts.small.regular.primary,
                recognizer: TapGestureRecognizer()..onTap = onPressed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
