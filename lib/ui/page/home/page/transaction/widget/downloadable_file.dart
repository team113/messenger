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
  const DownloadableFile(this.attachment, {super.key});

  final FileAttachment attachment;

  @override
  State<DownloadableFile> createState() => _DownloadableFileState();
}

class _DownloadableFileState extends State<DownloadableFile> {
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgLoader.asset(
                  'assets/icons/download_cancel.svg',
                  key: const Key('CancelDownloading'),
                  width: 40,
                  height: 40,
                ),
                SizedBox.square(
                  dimension: 37,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    key: const Key('Downloading'),
                    value: e.progress.value == 0 ? null : e.progress.value,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
          break;

        case DownloadStatus.isFinished:
          leading = const SizedBox(
            key: Key('Downloaded'),
            height: 40,
            width: 40,
            child: Center(
              child: Icon(
                Icons.file_copy,
                color: Color(0xFF63B4FF),
                size: 38,
              ),
            ),
          );
          break;

        case DownloadStatus.notStarted:
          leading = SvgLoader.asset(
            'assets/icons/download.svg',
            key: const Key('Download'),
            width: 40,
            height: 40,
          );
          break;
      }

      leading = KeyedSubtree(key: const Key('Sent'), child: leading);

      leading = AnimatedSwitcher(
        key: Key('AttachmentStatus_${e.id}'),
        duration: 250.milliseconds,
        child: leading,
      );

      final Style style = Theme.of(context).extension<Style>()!;

      return Padding(
        key: Key('File_${e.id}'),
        // padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: WidgetButton(
          onPressed: () async {
            if (await e.open() == false) {
              print('${Config.url}/assets/assets/${e.original.relativeRef}');
              await e.download(
                '${Config.url}/assets/assets/${e.original.relativeRef}',
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withOpacity(0.03),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: leading,
                ),
                const SizedBox(width: 11),
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
                              style: style.boldBody, //.copyWith(fontSize: 15),
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
                      const SizedBox(height: 5),
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
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      );
    });
  }
}
