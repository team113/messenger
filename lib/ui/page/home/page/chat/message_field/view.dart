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

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart' hide CloseButton;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_gallery.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/init_callback.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/page/player/controller.dart';
import '/ui/page/player/view.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/future_or_builder.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/chat_button.dart';
import 'widget/close_button.dart';

/// View for writing and editing a [ChatMessage] or a [ChatForward].
class MessageFieldView extends StatelessWidget {
  const MessageFieldView({
    super.key,
    this.controller,
    this.onChanged,
    this.onItemPressed,
    this.onAttachmentError,
    this.fieldKey,
    this.sendKey,
    this.canForward = false,
    this.canAttach = true,
    this.constraints,
    this.applySafeArea = false,
    this.rounded = false,
  });

  /// Optionally provided external [MessageFieldController].
  final MessageFieldController? controller;

  /// [Key] of a [ReactiveTextField] this [MessageFieldView] has.
  final Key? fieldKey;

  /// [Key] of a send button this [MessageFieldView] has.
  final Key? sendKey;

  /// Indicator whether forwarding is possible within this [MessageFieldView].
  final bool canForward;

  /// Indicator whether [Attachment]s can be attached to this
  /// [MessageFieldView].
  final bool canAttach;

  /// Callback, called when a [ChatItem] being a reply or edited is pressed.
  final Future<void> Function(ChatItem item)? onItemPressed;

  /// Callback, called on the [ReactiveTextField] changes.
  final void Function()? onChanged;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function(ChatItem)? onAttachmentError;

  /// [BoxConstraints] replies, attachments and quotes are allowed to occupy.
  final BoxConstraints? constraints;

  /// Indicator whether [SafeArea] should be applied to the field.
  final bool applySafeArea;

  /// Indicator whether the field should be rounded.
  final bool rounded;

  /// Border radius value when [rounded] is `true`.
  static const Radius _borderRadius = Radius.circular(15);

  /// Returns a [ThemeData] to decorate a [ReactiveTextField] with.
  static ThemeData theme(BuildContext context) {
    final style = Theme.of(context).style;

    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide.none,
    );

    return Theme.of(context).copyWith(
      shadowColor: style.colors.onBackgroundOpacity27,
      iconTheme: IconThemeData(color: style.colors.primaryHighlight),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        border: border,
        errorBorder: border,
        enabledBorder: border,
        focusedBorder: border,
        disabledBorder: border,
        focusedErrorBorder: border,
        focusColor: style.colors.onPrimary,
        fillColor: style.colors.onPrimary,
        hoverColor: style.colors.transparent,
        filled: true,
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(
          15,
          PlatformUtils.isDesktop ? 30 : 23,
          15,
          0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init:
          controller ??
          MessageFieldController(Get.find(), Get.find(), Get.find()),
      global: false,
      builder: (MessageFieldController c) {
        return CallbackShortcuts(
          bindings: {
            if (!PlatformUtils.isWeb)
              SingleActivator(LogicalKeyboardKey.keyV, control: true):
                  c.handlePaste,
            if (!PlatformUtils.isWeb)
              SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                  c.handlePaste,
          },
          child: Theme(
            data: theme(context),
            child: Container(
              key: const Key('SendField'),
              decoration: BoxDecoration(
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
          ),
        );
      },
    );
  }

  /// Returns a visual representation of the message attachments, replies,
  /// quotes and edited message.
  Widget _buildHeader(MessageFieldController c, BuildContext context) {
    final style = Theme.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final bool grab = c.attachments.isNotEmpty
              ? (125 + 2) * c.attachments.length > constraints.maxWidth - 16
              : false;

          Widget? previews;

          if (c.quotes.isNotEmpty) {
            previews = ReorderableListView(
              scrollController: c.scrollController,
              shrinkWrap: true,
              buildDefaultDragHandles: PlatformUtils.isMobile,
              onReorder: (int old, int to) {
                if (old < to) {
                  --to;
                }

                c.quotes.insert(to, c.quotes.removeAt(old));

                PlatformUtils.haptic(kind: HapticKind.light);
              },
              proxyDecorator: (child, _, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) {
                    final double t = Curves.easeInOut.transform(
                      animation.value,
                    );
                    final double elevation = lerpDouble(0, 6, t)!;
                    final Color color = Color.lerp(
                      style.colors.transparent,
                      style.colors.onBackgroundOpacity20,
                      t,
                    )!;

                    return InitCallback(
                      callback: PlatformUtils.haptic,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            CustomBoxShadow(
                              color: color,
                              blurRadius: elevation,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 1),
              children: c.quotes.map((e) {
                return ReorderableDragStartListener(
                  key: Key('Handle_${e.item.id}'),
                  enabled: !PlatformUtils.isMobile,
                  index: c.quotes.indexOf(e),
                  child: Dismissible(
                    key: Key('${e.item.id}'),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) {
                      c.quotes.remove(e);
                      if (c.quotes.isEmpty) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _buildPreview(
                        context,
                        e.item,
                        c,
                        onClose: () {
                          c.quotes.remove(e);
                          if (c.quotes.isEmpty) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          } else if (c.replied.isNotEmpty) {
            previews = ReorderableListView(
              scrollController: c.scrollController,
              shrinkWrap: true,
              buildDefaultDragHandles: PlatformUtils.isMobile,
              onReorder: (int old, int to) {
                if (old < to) {
                  --to;
                }

                c.replied.insert(to, c.replied.removeAt(old));

                PlatformUtils.haptic(kind: HapticKind.light);
              },
              proxyDecorator: (child, _, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) {
                    final double t = Curves.easeInOut.transform(
                      animation.value,
                    );
                    final double elevation = lerpDouble(0, 6, t)!;
                    final Color color = Color.lerp(
                      style.colors.transparent,
                      style.colors.onBackgroundOpacity20,
                      t,
                    )!;

                    return InitCallback(
                      callback: PlatformUtils.haptic,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            CustomBoxShadow(
                              color: color,
                              blurRadius: elevation,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 1),
              children: c.replied.map((e) {
                return Obx(key: Key('Handle_${e.value.id}'), () {
                  return ReorderableDragStartListener(
                    enabled: !PlatformUtils.isMobile,
                    index: c.replied.indexOf(e),
                    child: Dismissible(
                      key: Key('${e.value.id}'),
                      direction: DismissDirection.horizontal,
                      onDismissed: (_) => c.replied.remove(e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: WidgetButton(
                          onPressed: () => onItemPressed?.call(e.value),
                          child: _buildPreview(
                            context,
                            e.value,
                            c,
                            onClose: () => c.replied.remove(e),
                          ),
                        ),
                      ),
                    ),
                  );
                });
              }).toList(),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: style.colors.background,
              borderRadius: BorderRadius.vertical(
                top: rounded ? _borderRadius : Radius.zero,
              ),
            ),
            child: AnimatedSize(
              duration: 400.milliseconds,
              alignment: Alignment.bottomCenter,
              curve: Curves.ease,
              child: Container(
                width: double.infinity,
                padding:
                    c.replied.isNotEmpty ||
                        c.attachments.isNotEmpty ||
                        c.edited.value != null
                    ? const EdgeInsets.fromLTRB(4, 6, 4, 6)
                    : EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.edited.value != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: WidgetButton(
                          onPressed: () => onItemPressed?.call(c.edited.value!),
                          child: _buildPreview(
                            context,
                            c.edited.value!,
                            c,
                            onClose: () => c.edited.value = null,
                            edited: true,
                          ),
                        ),
                      ),
                    if (previews != null)
                      ConstrainedBox(
                        constraints:
                            this.constraints ??
                            BoxConstraints(
                              maxHeight: max(
                                100,
                                MediaQuery.of(context).size.height / 3.4,
                              ),
                            ),
                        child: Scrollbar(
                          controller: c.scrollController,
                          child: previews,
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
  Widget _buildField(MessageFieldController c, BuildContext context) {
    final style = Theme.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) => Obx(() {
        return _FieldContainer(
          key: c.fieldKey,
          borderRadius: rounded ? _borderRadius : Radius.zero,
          previewOpen:
              c.attachments.isNotEmpty ||
              c.quotes.isNotEmpty ||
              c.replied.isNotEmpty,
          applySafeArea: applySafeArea,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedButton(
                onPressed: canAttach ? c.toggleMore : null,
                child: SizedBox(
                  width: 46,
                  height: 56,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2.0),
                      child: Obx(() {
                        return AnimatedScale(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.bounceInOut,
                          scale: c.moreOpened.value ? 1.1 : 1,
                          child: const SvgIcon(
                            SvgIcons.chatMore,
                            width: 22,
                            height: 22,
                          ),
                        );
                      }),
                    ),
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
                      onChanged: onChanged,
                      key: fieldKey ?? const Key('MessageField'),
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
              Obx(() {
                int take = max(((constraints.maxWidth - 160) / 50).round(), 0);

                SchedulerBinding.instance.addPostFrameCallback((_) {
                  c.hasSpaceForPins.value = c.buttons.length < take;
                });

                final bool sendable =
                    !c.field.isEmpty.value ||
                    c.attachments.isNotEmpty ||
                    c.replied.isNotEmpty;

                final List<Widget> children;

                if (sendable || c.buttons.isEmpty) {
                  children = [
                    ChatButtonWidget.send(
                      key: sendKey ?? Key('Send'),
                      onPressed: c.field.submittable.isTrue
                          ? c.field.submit
                          : null,
                    ),
                  ];
                } else {
                  children = c.buttons
                      .take(take)
                      .toList()
                      .reversed
                      .map((e) => ChatButtonWidget(e))
                      .toList();
                }

                return Wrap(children: children);
              }),
              const SizedBox(width: 3),
            ],
          ),
        );
      }),
    );
  }

  /// Returns a visual representation of the provided [Attachment].
  Widget _buildAttachment(
    BuildContext context,
    MapEntry<GlobalKey, Attachment> entry,
    MessageFieldController c,
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
          autoplay: true,
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
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    child,
                    IgnorePointer(
                      child: Container(
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
                    ),
                  ],
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

  /// Returns a visual representation of the provided [item] as a preview.
  Widget _buildPreview(
    BuildContext context,
    ChatItem item,
    MessageFieldController c, {
    void Function()? onClose,
    bool edited = false,
  }) {
    final style = Theme.of(context).style;

    final bool fromMe = item.author.id == c.me;

    if (edited) {
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgIcon(SvgIcons.editSmall),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'label_editing'.l10n,
                style: style.fonts.small.regular.primary,
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

    Widget? content;
    final List<Widget> additional = [];

    if (item is ChatMessage) {
      if (item.attachments.isNotEmpty) {
        additional.addAll(
          item.attachments.map((a) {
            final ImageAttachment? image = a is ImageAttachment ? a : null;

            return Container(
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: fromMe
                    ? style.colors.onPrimaryOpacity25
                    : style.colors.onBackgroundOpacity2,
                borderRadius: BorderRadius.circular(4),
              ),
              width: 30,
              height: 30,
              child: image == null
                  ? Icon(
                      Icons.file_copy,
                      color: fromMe
                          ? style.colors.onPrimary
                          : style.colors.secondaryHighlightDarkest,
                      size: 16,
                    )
                  : RetryImage(
                      image.small.url,
                      checksum: image.small.checksum,
                      thumbhash: image.small.thumbhash,
                      fit: BoxFit.cover,
                      height: 30,
                      width: 30,
                      borderRadius: BorderRadius.circular(4),
                      onForbidden: () async =>
                          await onAttachmentError?.call(item),
                    ),
            );
          }).toList(),
        );
      }

      if (item.text != null && item.text!.val.isNotEmpty) {
        content = Text(
          item.text!.val,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.fonts.medium.regular.onBackground,
        );
      }
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed =
            item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;

        if (item.finishedAt != null && item.conversationStartedAt != null) {
          time = item.conversationStartedAt!.val
              .difference(item.finishedAt!.val)
              .localizedString();
        }
      } else {
        title = item.author.id == c.me
            ? 'label_outgoing_call'.l10n
            : 'label_incoming_call'.l10n;
      }

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: SvgIcon(
              item.withVideo
                  ? isMissed && !fromMe
                        ? SvgIcons.callVideoMissed
                        : SvgIcons.callVideo
                  : isMissed && !fromMe
                  ? SvgIcons.callAudioMissed
                  : SvgIcons.callAudio,
            ),
          ),
          Flexible(
            child: Text(title, style: style.fonts.medium.regular.onBackground),
          ),
          if (time != null) ...[
            const SizedBox(width: 9),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.fonts.small.regular.secondary,
              ),
            ),
          ],
        ],
      );
    } else if (item is ChatForward) {
      // TODO: Implement `ChatForward`.
      content = Text(
        'label_forwarded_message'.l10n,
        style: style.fonts.medium.regular.onBackground,
      );
    } else if (item is ChatInfo) {
      // TODO: Implement `ChatInfo`.
      content = Text(
        item.action.toString(),
        style: style.fonts.medium.regular.onBackground,
      );
    } else {
      content = Text(
        'err_unknown'.l10n,
        style: style.fonts.medium.regular.onBackground,
      );
    }

    final Widget expanded = FutureOrBuilder<RxUser?>(
      key: Key('${item.id}_2_${item.author.id}'),
      futureOr: () => c.getUser(item.author.id),
      builder: (context, user) {
        final Color color = user?.user.value.id == c.me
            ? style.colors.primary
            : style.colors.userColors[(user?.user.value.num.val.sum() ?? 3) %
                  style.colors.userColors.length];

        return Container(
          key: Key('Reply_${c.replied.indexOf(item)}'),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(width: 2, color: color)),
          ),
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              user != null
                  ? Obx(() {
                      return Text(
                        user.title(),
                        style: style.fonts.medium.regular.onBackground.copyWith(
                          color: color,
                        ),
                      );
                    })
                  : Text(
                      'dot'.l10n * 3,
                      style: style.fonts.medium.regular.primary,
                    ),
              if (content != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle.merge(maxLines: 1, child: content),
              ],
              if (additional.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: additional),
              ],
            ],
          ),
        );
      },
    );

    return MouseRegion(
      opaque: false,
      onEnter: (d) => c.hoveredReply.value = item,
      onExit: (d) => c.hoveredReply.value = null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        decoration: BoxDecoration(
          color: style.colors.secondaryHighlight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: expanded),
            Obx(() {
              return AnimatedOpacity(
                duration: 200.milliseconds,
                opacity: c.hoveredReply.value == item || PlatformUtils.isMobile
                    ? 1
                    : 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 3, 3, 0),
                  child: CloseButton(
                    key: const Key('CancelReplyButton'),
                    onPressed: onClose,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Container for the [MessageFieldView] with a rounded border.
class _FieldContainer extends StatelessWidget {
  const _FieldContainer({
    super.key,
    required this.child,
    required this.applySafeArea,
    required this.borderRadius,
    required this.previewOpen,
  });

  /// Indicator whether the preview is open.
  final bool previewOpen;

  /// Indicator whether [SafeArea] should be applied to the field.
  final bool applySafeArea;

  /// Border radius of the container.
  final Radius borderRadius;

  /// Text field content
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: style.colors.onPrimary,
        borderRadius: BorderRadius.vertical(
          bottom: borderRadius,
          top: previewOpen ? Radius.zero : borderRadius,
        ),
      ),
      padding: applySafeArea
          ? EdgeInsets.only(bottom: max(CustomNavigationBar.height - 56, 0))
          : EdgeInsets.zero,
      child: child,
    );
  }
}
