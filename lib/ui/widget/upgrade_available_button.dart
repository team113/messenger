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

import 'dart:io';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/worker/upgrade.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'progress_indicator.dart';
import 'svg/svg.dart';
import 'upgrade_popup/view.dart';
import 'widget_button.dart';

/// [WidgetButton] displaying the [Release] and [ReleaseDownload] provided.
class UpgradeAvailableButton extends StatelessWidget {
  const UpgradeAvailableButton({
    super.key,
    required this.scheduled,
    this.download,
    this.onClose,
  });

  /// [Release] to display in [UpgradePopupView].
  final Release scheduled;

  /// [ReleaseDownload] currently being downloaded, if any.
  final ReleaseDownload? download;

  /// Callback, called when close button is pressed.
  final void Function()? onClose;

  @override
  Widget build(BuildContext context) {
    if (download != null) {
      return Obx(() {
        final File? file = download?.file.value;

        return _button(
          context,
          leading: file == null
              ? Padding(
                  padding: const EdgeInsets.all(3),
                  child: CustomProgressIndicator.bold(
                    value: download?.progress.value,
                  ),
                )
              : SvgIcon(SvgIcons.downloadFolder, key: Key('downloadFolder')),
          text: file == null ? 'label_downloading'.l10n : 'btn_open'.l10n,
          onPressed: file != null
              ? () async {
                  try {
                    final launched = await launchUrl(file.uri);

                    if (!launched && context.mounted) {
                      await UpgradePopupView.show(context, release: scheduled);
                    }
                  } catch (e) {
                    MessagePopup.error(e);
                  }
                }
              : null,
        );
      });
    }

    final Widget leading;
    final String text;

    if (PlatformUtils.isWeb) {
      text = 'label_update_available'.l10n;
      leading = SvgIcon(SvgIcons.downloadRefresh, key: Key('downloadRefresh'));
    } else {
      text = 'label_update_available'.l10n;
      leading = SvgIcon(SvgIcons.downloadArrow, key: Key('downloadArrow'));
    }

    return _button(
      context,
      leading: leading,
      text: text,
      onPressed: () async {
        if (PlatformUtils.isWeb) {
          return await WebUtils.refresh();
        }

        await UpgradePopupView.show(context, release: scheduled);
      },
    );
  }

  /// Builds a styled [WidgetButton] displaying the provided [leading] and
  /// [text].
  Widget _button(
    BuildContext context, {
    Widget? leading,
    String? text,
    void Function()? onPressed,
  }) {
    final style = Theme.of(context).style;

    return WidgetButton(
      onPressed: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: style.colors.primary,
          boxShadow: [
            CustomBoxShadow(
              blurRadius: 8,
              color: style.colors.onBackgroundOpacity13,
              blurStyle: BlurStyle.outer.workaround,
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: [
            if (leading != null)
              AnimatedSizeAndFade(
                fadeDuration: Duration(milliseconds: 250),
                sizeDuration: Duration(milliseconds: 250),
                child: leading,
              ),
            if (text != null)
              Expanded(
                child: AnimatedSizeAndFade(
                  fadeDuration: Duration(milliseconds: 250),
                  sizeDuration: Duration(milliseconds: 250),
                  child: Center(
                    key: Key(text),
                    child: Text(
                      text,
                      style: style.fonts.normal.regular.onPrimary,
                    ),
                  ),
                ),
              ),
            WidgetButton(
              onPressed: download?.cancel ?? onClose,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                child: SvgIcon(SvgIcons.closeSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
