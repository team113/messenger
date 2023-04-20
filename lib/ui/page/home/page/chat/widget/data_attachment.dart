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
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/domain/model/attachment.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

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
  Widget build(BuildContext context) {
    final Attachment e = widget.attachment;

    return Obx(() {
      final Style style = Theme.of(context).extension<Style>()!;

      Widget leading = Container();

      if (e is FileAttachment) {
        switch (e.downloadStatus.value) {
          case DownloadStatus.inProgress:
            leading = InkWell(
              key: const Key('CancelDownloading'),
              onTap: e.cancelDownload,
              child: Container(
                key: const Key('Downloading'),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: style.colors.primary!,
                  ),
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      style.colors.primary!,
                      style.colors.primary!,
                      style.colors.backgroundAuxiliaryLighter!,
                    ],
                    stops: [
                      0,
                      e.progress.value,
                      e.progress.value,
                    ],
                  ),
                ),
                child: Center(
                  child: SvgLoader.asset(
                    'assets/icons/cancel.svg',
                    width: 11,
                    height: 11,
                  ),
                ),
              ),
            );
            break;

          case DownloadStatus.isFinished:
            leading = Container(
              key: const Key('Downloaded'),
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.colors.primary,
              ),
              child: Center(
                child: Icon(
                  Icons.insert_drive_file,
                  color: style.colors.onPrimary,
                  size: 16,
                ),
              ),
            );
            break;

          case DownloadStatus.notStarted:
            leading = AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              key: const Key('Download'),
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hovered
                    ? style.colors.backgroundAuxiliaryLighter
                    : style.colors.transparent,
                border: Border.all(
                  width: 2,
                  color: style.colors.primary!,
                ),
              ),
              child: KeyedSubtree(
                key: const Key('Sent'),
                child: Center(
                  child: SvgLoader.asset(
                    'assets/icons/arrow_down.svg',
                    width: 10.55,
                    height: 14,
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
              dimension: 18,
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
              size: 18,
              color: style.colors.acceptAuxiliaryColor,
            );
            break;

          case SendingStatus.error:
            leading = Icon(
              Icons.error_outline,
              key: const Key('Error'),
              size: 18,
              color: style.colors.dangerColor,
            );
            break;
        }
      }

      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Padding(
          key: Key('File_${e.id}'),
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: WidgetButton(
            onPressed: widget.onPressed,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: style.colors.onBackgroundOpacity2,
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const SizedBox(width: 8),
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
                                style: style.boldBody,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              p.extension(e.filename),
                              style: style.boldBody,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'label_kb'.l10nfmt({
                            'amount': e.original.size == null
                                ? 'dot'.l10n * 3
                                : e.original.size! ~/ 1024
                          }),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style.boldBody.copyWith(
                            fontSize: 13,
                            color: style.colors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AnimatedSwitcher(
                      key: Key('AttachmentStatus_${e.id}'),
                      duration: 250.milliseconds,
                      child: leading,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
