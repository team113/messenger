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

// ignore_for_file: must_be_immutable

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/domain/model/attachment.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

class MessageAttachment extends StatelessWidget {
  MessageAttachment({
    super.key,
    required this.entry,
    required this.field,
    required this.rxAttachments,
    required this.hoveredAttachment,
    required this.onExit,
  });

  /// TODO: docs
  final MapEntry<GlobalKey, Attachment> entry;

  /// TODO: docs
  final TextFieldState field;

  /// TODO: docs
  final List<MapEntry<GlobalKey<State<StatefulWidget>>, Attachment>>
      rxAttachments;

  /// TODO: docs
  Attachment? hoveredAttachment;

  /// TODO: docs
  final void Function(PointerExitEvent)? onExit;

  @override
  Widget build(BuildContext context) {
    final Attachment e = entry.value;
    final GlobalKey key = entry.key;

    final bool isImage =
        (e is ImageAttachment || (e is LocalAttachment && e.file.isImage));
    final bool isVideo = (e is FileAttachment && e.isVideo) ||
        (e is LocalAttachment && e.file.isVideo);

    const double size = 125;

    // Builds the visual representation of the provided [Attachment] itself.
    Widget content() {
      final Style style = Theme.of(context).extension<Style>()!;

      if (isImage || isVideo) {
        final Widget child = MediaAttachment(
          attachment: e,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );

        final List<Attachment> attachments = rxAttachments
            .where((e) {
              final Attachment a = e.value;
              return a is ImageAttachment ||
                  (a is FileAttachment && a.isVideo) ||
                  (a is LocalAttachment && (a.file.isImage || a.file.isVideo));
            })
            .map((e) => e.value)
            .toList();

        return WidgetButton(
          key: key,
          onPressed: e is LocalAttachment
              ? null
              : () {
                  final int index =
                      rxAttachments.indexWhere((m) => m.value == e);
                  if (index != -1) {
                    GalleryPopup.show(
                      context: context,
                      gallery: GalleryPopup(
                        initial: index,
                        initialKey: key,
                        onTrashPressed: (int i) {
                          rxAttachments
                              .removeWhere((o) => o.value == attachments[i]);
                        },
                        children: attachments.map((o) {
                          if (o is ImageAttachment ||
                              (o is LocalAttachment && o.file.isImage)) {
                            return GalleryItem.image(
                              o.original.url,
                              o.filename,
                              size: o.original.size,
                              checksum: o.original.checksum,
                            );
                          }
                          return GalleryItem.video(
                            o.original.url,
                            o.filename,
                            size: o.original.size,
                            checksum: o.original.checksum,
                          );
                        }).toList(),
                      ),
                    );
                  }
                },
          child: isVideo
              ? IgnorePointer(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      child,
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: style.colors.onBackgroundOpacity50,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: style.colors.onPrimary,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                )
              : child,
        );
      }

      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      p.basenameWithoutExtension(e.filename),
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    p.extension(e.filename),
                    style: const TextStyle(fontSize: 13),
                  )
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                'label_kb'.l10nfmt({
                  'amount': e.original.size == null
                      ? 'dot'.l10n * 3
                      : e.original.size! ~/ 1024
                }),
                style: TextStyle(fontSize: 13, color: style.colors.secondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Builds the [content] along with manipulation buttons and statuses.
    Widget attachment() {
      final Style style = Theme.of(context).extension<Style>()!;

      return MouseRegion(
        key: Key('Attachment_${e.id}'),
        opaque: false,
        onExit: onExit,
        onEnter: (_) => hoveredAttachment = e,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: style.colors.secondaryHighlight,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: content(),
              ),
              Center(
                child: SizedBox.square(
                  dimension: 30,
                  child: ElasticAnimatedSwitcher(
                    child: e is LocalAttachment
                        ? e.status.value == SendingStatus.error
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: style.colors.onPrimary,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.error,
                                    color: style.colors.dangerColor,
                                  ),
                                ),
                              )
                            : const SizedBox()
                        : const SizedBox(),
                  ),
                ),
              ),
              if (!field.status.value.isLoading)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: AnimatedSwitcher(
                      duration: 200.milliseconds,
                      child: removeAttachmentWidget(context, e),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Dismissible(
      key: Key(e.id.val),
      direction: DismissDirection.up,
      onDismissed: (_) => rxAttachments.removeWhere((a) => a.value == e),
      child: attachment(),
    );
  }

  /// TODO: docs
  Widget removeAttachmentWidget(
    BuildContext context,
    Attachment e,
  ) {
    final Style style = Theme.of(context).extension<Style>()!;

    if (hoveredAttachment == e || PlatformUtils.isMobile) {
      return InkWell(
        key: const Key('RemovePickedFile'),
        onTap: () => rxAttachments.removeWhere((a) => a.value == e),
        child: Container(
          width: 15,
          height: 15,
          margin: const EdgeInsets.only(left: 8, bottom: 8),
          child: Container(
            key: const Key('Close'),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.cardColor,
            ),
            alignment: Alignment.center,
            child: SvgImage.asset(
              'assets/icons/close_primary.svg',
              width: 7,
              height: 7,
            ),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
