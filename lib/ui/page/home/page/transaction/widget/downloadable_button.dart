import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/field_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:path/path.dart' as p;

class DownloadableButton extends StatefulWidget {
  const DownloadableButton(this.attachment, {super.key});

  final FileAttachment attachment;

  @override
  State<DownloadableButton> createState() => _DownloadableFileState();
}

class _DownloadableFileState extends State<DownloadableButton> {
  @override
  Widget build(BuildContext context) {
    final FileAttachment e = widget.attachment;

    return Obx(() {
      Widget leading = Container();

      switch (e.downloadStatus.value) {
        case DownloadStatus.inProgress:
          leading = Stack(
            key: const Key('InProgress'),
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
                  strokeWidth: 5,
                  key: const Key('Downloading'),
                  value: e.progress.value == 0 ? null : e.progress.value,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          );
          break;

        case DownloadStatus.isFinished:
          leading = const SizedBox(
            key: Key('Downloaded'),
            height: 20,
            width: 20,
            child: Center(
              child: Icon(
                Icons.file_copy,
                color: Color(0xFF63B4FF),
                size: 20,
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

      return FieldButton(
        onPressed: () async {
          if (e.downloadStatus.value == DownloadStatus.inProgress) {
            e.cancelDownload();
          } else {
            if (await e.open() == false) {
              await e.download(
                '${Config.url}/assets/assets/${e.original.relativeRef}',
              );
            }
          }
        },
        text: 'Invoice №12353519',
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
        ),
        trailing: leading,
      );
    });
  }
}
