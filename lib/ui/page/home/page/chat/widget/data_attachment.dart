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
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/domain/model/attachment.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/ui/worker/cache.dart';

/// Visual representation of a file [Attachment].
class DataAttachment extends StatefulWidget {
  const DataAttachment(this.attachment, {super.key, this.onPressed});

  /// [Attachment] to display.
  final Attachment attachment;

  /// Callback, called when this [DataAttachment] is pressed.
  final void Function()? onPressed;

  @override
  State<DataAttachment> createState() => _DataAttachmentState();
}

/// State of a [DataAttachment] maintaining the [_hovered] indicator.
class _DataAttachmentState extends State<DataAttachment> {
  /// Indicator whether this [DataAttachment] is hovered.
  bool _hovered = false;

  @override
  void initState() {
    if (widget.attachment is FileAttachment) {
      (widget.attachment as FileAttachment).init();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Attachment e = widget.attachment;

    return Obx(() {
      final style = Theme.of(context).style;

      Widget leading = Container();

      if (e is FileAttachment) {
        switch (e.downloadStatus) {
          case DownloadStatus.inProgress:
            leading = InkWell(
              key: const Key('CancelDownloading'),
              onTap: e.cancelDownload,
              child: Container(
                key: const Key('Downloading'),
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: style.colors.primary),
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      style.colors.primary,
                      style.colors.primary,
                      style.colors.backgroundAuxiliaryLighter,
                    ],
                    stops: [
                      0,
                      e.downloading?.progress.value ?? 0,
                      e.downloading?.progress.value ?? 0,
                    ],
                  ),
                ),
                child: const Center(
                  child: SvgImage.asset(
                    'assets/icons/cancel.svg',
                    width: 9,
                    height: 9,
                  ),
                ),
              ),
            );
            break;

          case DownloadStatus.isFinished:
            leading = Container(
              key: const Key('Downloaded'),
              height: 29,
              width: 29,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.colors.primary,
              ),
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0.3, -0.5),
                  child: const SvgIcon(SvgIcons.fileSmallWhite),
                ),
              ),
            );
            break;

          case DownloadStatus.notStarted:
            leading = AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              key: const Key('Download'),
              height: 29,
              width: 29,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hovered
                    ? style.colors.backgroundAuxiliaryLighter
                    : null,
                border: Border.all(width: 2, color: style.colors.primary),
              ),
              child: const KeyedSubtree(
                key: Key('Sent'),
                child: Center(
                  child: SvgImage.asset(
                    'assets/icons/arrow_down.svg',
                    width: 9.12,
                    height: 10.39,
                  ),
                ),
              ),
            );
            break;
        }
      } else if (e is LocalAttachment) {
        switch (e.status.value) {
          case SendingStatus.sending:
            leading = SizedBox.square(
              key: const Key('Sending'),
              dimension: 29,
              child: CircularProgressIndicator(
                value: e.progress.value,
                backgroundColor: style.colors.onPrimary,
                strokeWidth: 5,
              ),
            );
            break;

          case SendingStatus.sent:
            leading = Icon(
              Icons.check_circle,
              key: const Key('Sent'),
              size: 29,
              color: style.colors.acceptAuxiliary,
            );
            break;

          case SendingStatus.error:
            leading = Icon(
              Icons.error_outline,
              key: const Key('Error'),
              size: 29,
              color: style.colors.danger,
            );
            break;
        }
      }

      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Padding(
          key: Key('File_${e.id}'),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: WidgetButton(
            onPressed: widget.onPressed,
            child: Row(
              children: [
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SafeAnimatedSwitcher(
                    key: Key('AttachmentStatus_${e.id}'),
                    duration: 250.milliseconds,
                    child: leading,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.basenameWithoutExtension(e.filename),
                              style: style.fonts.medium.regular.onBackground,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            p.extension(e.filename),
                            style: style.fonts.medium.regular.onBackground,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.original.size.asBytes(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style.fonts.small.regular.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
