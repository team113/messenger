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

import 'package:flutter/material.dart' hide CloseButton;
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/chat/message_field/widget/chat_button.dart';
import '/ui/page/home/page/chat/message_field/widget/close_button.dart';
import '/ui/page/home/page/chat/widget/chat_gallery.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/player/controller.dart';
import '/ui/page/player/view.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for writing and editing a [WelcomeMessage].
class WelcomeFieldView extends StatefulWidget {
  const WelcomeFieldView({
    super.key,
    this.controller,
    this.onChanged,
    this.onAttachmentError,
    this.fieldKey,
    this.sendKey,
  });

  /// Optionally provided external [WelcomeFieldController].
  final WelcomeFieldController? controller;

  /// [Key] of a [ReactiveTextField] this [WelcomeFieldView] has.
  final Key? fieldKey;

  /// [Key] of a send button this [WelcomeFieldView] has.
  final Key? sendKey;

  /// Callback, called on the [ReactiveTextField] changes.
  final void Function()? onChanged;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function(ChatItem)? onAttachmentError;

  @override
  State<WelcomeFieldView> createState() => _WelcomeFieldViewState();
}

/// State of a [WelcomeFieldView] to preserve a [WelcomeFieldController].
class _WelcomeFieldViewState extends State<WelcomeFieldView> {
  /// [WelcomeFieldController] controlling this [WelcomeFieldView].
  late final WelcomeFieldController c;

  @override
  void initState() {
    c = widget.controller ?? WelcomeFieldController(Get.find());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Theme(
      data: MessageFieldView.theme(context),
      child: Container(
        key: const Key('SendField'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: style.cardRadius.topLeft,
            topRight: style.cardRadius.topRight,
          ),
          boxShadow: [
            CustomBoxShadow(
              blurRadius: 8,
              color: style.colors.onBackgroundOpacity13,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(c, context), _buildField(c, context)],
        ),
      ),
    );
  }

  /// Returns a visual representation of the message attachments, replies,
  /// quotes and edited message.
  Widget _buildHeader(WelcomeFieldController c, BuildContext context) {
    final style = Theme.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final bool grab = c.attachments.isNotEmpty
              ? (125 + 2) * c.attachments.length > constraints.maxWidth - 16
              : false;

          return Container(
            decoration: BoxDecoration(
              color: style.colors.onPrimaryOpacity50,
              borderRadius: BorderRadius.only(
                topLeft: style.cardRadius.topLeft,
                topRight: style.cardRadius.topRight,
              ),
            ),
            child: AnimatedSize(
              duration: 400.milliseconds,
              alignment: Alignment.bottomCenter,
              curve: Curves.ease,
              child: Container(
                width: double.infinity,
                padding: c.attachments.isNotEmpty || c.edited.value != null
                    ? const EdgeInsets.fromLTRB(4, 6, 4, 6)
                    : EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.edited.value != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _buildPreview(
                          context,
                          c,
                          onClose: () => c.edited.value = null,
                        ),
                      ),
                    if (c.attachments.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: MouseRegion(
                          cursor: grab
                              ? CustomMouseCursors.grab
                              : MouseCursor.defer,
                          opaque: false,
                          child: ScrollConfiguration(
                            behavior: CustomScrollBehavior(),
                            child: SingleChildScrollView(
                              clipBehavior: Clip.none,
                              physics: grab
                                  ? null
                                  : const NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: c.attachments
                                    .map((e) => _buildAttachment(context, e, c))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Builds a visual representation of the send field itself along with its
  /// buttons.
  Widget _buildField(WelcomeFieldController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      key: c.fieldKey,
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(color: style.cardColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedButton(
            onPressed: c.toggleMore,
            child: SizedBox(
              width: 50,
              height: 56,
              child: Center(
                child: Obx(() {
                  return AnimatedScale(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.bounceInOut,
                    scale: c.moreOpened.value ? 1.1 : 1,
                    child: const SvgIcon(SvgIcons.chatMore),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 5 + (PlatformUtils.isMobile ? 0 : 8),
                bottom: 13,
              ),
              child: Transform.translate(
                offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
                child: ReactiveTextField(
                  onChanged: widget.onChanged,
                  key: widget.fieldKey ?? const Key('MessageField'),
                  state: c.field,
                  hint: 'label_send_message_hint'.l10n,
                  minLines: 1,
                  maxLines: 7,
                  filled: false,
                  dense: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  style: style.fonts.medium.regular.onBackground,
                  type: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ChatButtonWidget.send(
            key: widget.sendKey ?? const Key('Send'),
            onPressed: c.field.submit,
          ),
          const SizedBox(width: 3),
        ],
      ),
    );
  }

  /// Returns a visual representation of the provided [Attachment].
  Widget _buildAttachment(
    BuildContext context,
    MapEntry<GlobalKey, Attachment> entry,
    WelcomeFieldController c,
  ) {
    final Attachment e = entry.value;
    final GlobalKey key = entry.key;

    final bool isImage =
        (e is ImageAttachment || (e is LocalAttachment && e.file.isImage));
    final bool isVideo =
        (e is FileAttachment && e.isVideo) ||
        (e is LocalAttachment && e.file.isVideo);

    const double size = 125;

    // Builds the visual representation of the provided [Attachment] itself.
    Widget content() {
      final style = Theme.of(context).style;

      if (isImage || isVideo) {
        // TODO: Backend should support single attachment updating.
        final Widget child = MediaAttachment(
          attachment: e,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );

        final List<Attachment> attachments = c.attachments
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
                  final int index = c.attachments.indexWhere(
                    (m) => m.value == e,
                  );

                  if (index != -1) {
                    PlayerView.show(
                      context,
                      gallery: RegularGallery(
                        items: attachments
                            .map((e) => MediaItem([e], null))
                            .toList(),
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
                      style: style.fonts.small.regular.onBackground,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    p.extension(e.filename),
                    style: style.fonts.small.regular.onBackground,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                e.original.size.asBytes(),
                style: style.fonts.small.regular.secondary,
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
      final style = Theme.of(context).style;

      return MouseRegion(
        key: Key('Attachment_${e.id}'),
        opaque: false,
        onEnter: (_) => c.hoveredAttachment.value = e,
        onExit: (_) => c.hoveredAttachment.value = null,
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
                                      color: style.colors.danger,
                                    ),
                                  ),
                                )
                              : const SizedBox()
                        : const SizedBox(),
                  ),
                ),
              ),
              if (!c.field.status.value.isLoading)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Obx(() {
                      return AnimatedOpacity(
                        duration: 200.milliseconds,
                        opacity:
                            c.hoveredAttachment.value == e ||
                                PlatformUtils.isMobile
                            ? 1
                            : 0,
                        child: CloseButton(
                          key: const Key('RemovePickedFile'),
                          onPressed: () {
                            if (e is LocalAttachment) {
                              e.cancelUpload();
                            }

                            c.attachments.removeWhere((a) => a.value == e);
                          },
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ObxValue((p) {
      return Opacity(
        opacity: 1 - p.value,
        child: Dismissible(
          key: Key(e.id.val),
          direction: DismissDirection.up,
          onDismissed: (_) => c.attachments.removeWhere((a) => a.value == e),
          onUpdate: (d) => p.value = d.progress,
          child: attachment(),
        ),
      );
    }, RxDouble(0));
  }

  /// Builds the editing mode preview.
  Widget _buildPreview(
    BuildContext context,
    WelcomeFieldController c, {
    void Function()? onClose,
  }) {
    final style = Theme.of(context).style;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'label_editing'.l10n,
              style: style.fonts.medium.regular.primary,
            ),
          ),
          AnimatedButton(
            key: const Key('CancelEditButton'),
            onPressed: onClose,
            child: Text(
              'btn_cancel'.l10n,
              style: style.fonts.small.regular.primary,
            ),
          ),
        ],
      ),
    );
  }
}
