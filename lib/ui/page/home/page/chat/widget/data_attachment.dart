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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/audio_player/view.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/ui/worker/audio.dart' show AudioId, AudioItem;
import '/ui/worker/cache.dart';
import '/util/audio_utils.dart' show AudioSource;

/// Visual representation of a file [Attachment].
class DataAttachment extends StatefulWidget {
  const DataAttachment(
    this.attachment, {
    super.key,
    this.itemId,
    this.onPressed,
    this.onForbidden,
  });

  /// [Attachment] to display.
  final Attachment attachment;

  /// [ChatItemId] this [DataAttachment] belongs to, if any.
  ///
  /// Intended to be used in order to construct unique [AudioId].
  final ChatItemId? itemId;

  /// Callback, called when this [DataAttachment] is pressed.
  final void Function()? onPressed;

  /// Callback, called when [attachment] fetching fails with `403` status code.
  final Future<void> Function()? onForbidden;

  @override
  State<DataAttachment> createState() => _DataAttachmentState();
}

/// State of a [DataAttachment] for initializing the attachment.
class _DataAttachmentState extends State<DataAttachment> {
  /// [AudioItem] representing the [Attachment] this [DataAttachment] holds, if
  /// any.
  AudioItem? _audio;

  @override
  void initState() {
    if (widget.attachment is FileAttachment) {
      (widget.attachment as FileAttachment).init();
    }

    final Attachment e = widget.attachment;

    if (e.isAudio) {
      final ChatItemId? id = widget.itemId;
      final AudioId audioId = id == null
          ? AudioId('${e.id}')
          : AudioId.fromMessage(id, e.id);

      if (e is LocalAttachment && e.file.path != null) {
        _audio = AudioItem(
          id: audioId,
          source: AudioSource.file(e.file.path!),
          title: e.filename,
        );
      } else if (e is FileAttachment) {
        _audio = AudioItem(
          id: audioId,
          source: AudioSource.url(e.original.url),
          title: e.filename,
        );
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Attachment e = widget.attachment;

    return Obx(() {
      Widget leading = Container();

      if (e is FileAttachment) {
        leading = switch (e.downloadStatus) {
          DownloadStatus.notStarted => SvgIcon(
            key: const Key('Download'),
            SvgIcons.downloadFile,
          ),
          DownloadStatus.inProgress => InkWell(
            key: const Key('CancelDownloading'),
            onTap: e.cancelDownload,
            child: _Progress(
              key: const Key('Downloading'),
              progress: e.downloading?.progress.value ?? 0,
            ),
          ),
          DownloadStatus.isFinished => SvgIcon(
            key: const Key('Downloaded'),
            SvgIcons.downloadFileOpen,
          ),
        };
      } else if (e is LocalAttachment) {
        leading = switch (e.status.value) {
          SendingStatus.sending => WidgetButton(
            key: const Key('CancelUploading'),
            onPressed: e.cancelUpload,
            child: _Progress(
              key: const Key('Sending'),
              progress: e.progress.value,
            ),
          ),
          SendingStatus.sent => SvgIcon(
            key: const Key('Sent'),
            SvgIcons.downloadFileSuccess,
          ),
          SendingStatus.error => SvgIcon(
            key: const Key('Error'),
            SvgIcons.downloadFileError,
          ),
        };
      }

      if (_audio != null) {
        Widget? progress;

        if (e is LocalAttachment && e.file.path != null) {
          progress = WidgetButton(onPressed: e.cancelUpload, child: leading);
        }

        return AudioPlayer(
          item: _audio!,
          leading: progress,
          onForbidden: e is FileAttachment
              ? () async {
                  await widget.onForbidden?.call();
                  return AudioSource.url(e.original.url);
                }
              : null,
        );
      }

      return Container(
        key: Key('File_${e.id}'),
        constraints: const BoxConstraints(minWidth: 112),
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
        child: WidgetButton(
          onPressed: widget.onPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Text(
                p.basename(e.filename),
                style: style.fonts.medium.regular.onBackground,
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Text(
                    e.original.size.asBytes(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style.fonts.small.regular.secondary,
                  ),

                  SafeAnimatedSwitcher(
                    key: Key('AttachmentStatus_${e.id}'),
                    duration: 250.milliseconds,
                    child: Center(child: leading),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// [CircularProgressIndicator] with close icon in the center.
class _Progress extends StatelessWidget {
  const _Progress({super.key, required this.progress});

  /// Progress value.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SvgIcon(SvgIcons.downloadFileCancelProgress),
        SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(value: progress, strokeWidth: 2),
        ),
      ],
    );
  }
}
