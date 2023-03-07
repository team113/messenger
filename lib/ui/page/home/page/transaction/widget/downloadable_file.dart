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
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:path/path.dart' as p;

class DownloadableFile extends StatefulWidget {
  const DownloadableFile(
    this.attachment, {
    super.key,
    this.onFileTap,
    this.fromMe = false,
  });

  final void Function()? onFileTap;
  final FileAttachment attachment;
  final bool fromMe;

  @override
  State<DownloadableFile> createState() => _DownloadableFileState();
}

class _DownloadableFileState extends State<DownloadableFile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final FileAttachment e = widget.attachment;

    return Obx(() {
      Widget leading = Container();

      switch (e.downloadStatus.value) {
        case DownloadStatus.inProgress:
          leading = InkWell(
            key: const Key('InProgress'),
            onTap: e.cancelDownload,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.secondary,
                    const Color(0xFFD1E1F0),
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
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: const Center(
              child: Icon(
                Icons.insert_drive_file,
                color: Colors.white,
                size: 16,
              ),
            ),
          );
          break;

        case DownloadStatus.notStarted:
          leading = AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            key: const Key('Downloaded'),
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _hovered ? const Color(0xFFD1E1F0) : const Color(0x00D1E1F0),
              border: Border.all(
                width: 2,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            child: Center(
              child: SvgLoader.asset(
                'assets/icons/arrow_down.svg',
                width: 10.55,
                height: 14,
              ),
            ),
          );
          break;
      }

      leading = KeyedSubtree(key: const Key('Sent'), child: leading);

      final Style style = Theme.of(context).extension<Style>()!;

      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Padding(
          key: Key('File_${e.id}'),
          // padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: WidgetButton(
            onPressed: widget.onFileTap ??
                () async {
                  if (e.isDownloading) {
                    e.cancelDownload();
                  } else {
                    if (await e.open() == false) {
                      print(
                          '${Config.url}/assets/assets/${e.original.relativeRef}');
                      await e.download(
                        '${Config.url}/assets/assets/${e.original.relativeRef}',
                      );
                    }
                  }
                },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: widget.fromMe
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const SizedBox(width: 8),

                  // const SizedBox(width: 11),
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
                                // style: const TextStyle(fontSize: 15),
                                style:
                                    style.boldBody, //.copyWith(fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              p.extension(e.filename),
                              // style: const TextStyle(fontSize: 15),
                              style: style.boldBody, //.copyWith(fontSize: 15),
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
                            // style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 11 + 5),
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
