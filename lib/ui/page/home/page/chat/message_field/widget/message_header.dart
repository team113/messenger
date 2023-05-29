import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/init_callback.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'message_attachment.dart';

/// [Widget] which returns a visual representation of the message attachments,
/// replies, quotes and edited message.
class MessageHeader extends StatelessWidget {
  const MessageHeader({
    super.key,
    required this.attachments,
    required this.hoveredAttachment,
    required this.field,
    required this.edited,
    required this.scrollController,
    required this.quotes,
    required this.replied,
    required this.boxConstraints,
    required this.me,
    required this.hoveredReply,
    required this.getUser,
    required this.onItemPressed,
  });

  /// Unique ID of an [User].
  final UserId? me;

  /// [Attachment]s of this [ChatMessage].
  final RxList<MapEntry<GlobalKey<State<StatefulWidget>>, Attachment>>
      attachments;

  /// [Attachment] being hovered.
  final Rx<Attachment?> hoveredAttachment;

  /// [TextFieldState] for a [ChatMessageText].
  final TextFieldState field;

  /// [ChatItem] being edited.
  final Rx<ChatItem?> edited;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController;

  /// [ChatItemQuoteInput]s to be forwarded.
  final RxList<ChatItemQuoteInput> quotes;

  /// [ChatItem] being quoted to reply onto.
  final RxList<ChatItem> replied;

  /// [BoxConstraints] replies, attachments and quotes are allowed to occupy.
  final BoxConstraints? boxConstraints;

  /// Replied [ChatItem] being hovered.
  final Rx<ChatItem?> hoveredReply;

  /// Returns an [User] from [UserService] by the provided [id].
  final Future<RxUser?> Function(UserId id) getUser;

  /// Callback, called when a [ChatItem] being a reply or edited is pressed.
  final Future<void> Function(ChatItemId)? onItemPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    /// Returns a visual representation of the provided [item] as a preview.
    Widget buildPreview(
      BuildContext context,
      ChatItem item, {
      void Function()? onClose,
    }) {
      final Style style = Theme.of(context).extension<Style>()!;
      final bool fromMe = item.authorId == me;

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
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(4),
                ),
                width: 30,
                height: 30,
                child: image == null
                    ? Icon(
                        Icons.file_copy,
                        color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                        size: 16,
                      )
                    : RetryImage(
                        image.small.url,
                        checksum: image.small.checksum,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(4),
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
            style: style.boldBody,
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
          isMissed = item.finishReason == ChatCallFinishReason.dropped ||
              item.finishReason == ChatCallFinishReason.unanswered;

          if (item.finishedAt != null && item.conversationStartedAt != null) {
            time = item.conversationStartedAt!.val
                .difference(item.finishedAt!.val)
                .localizedString();
          }
        } else {
          title = item.authorId == me
              ? 'label_outgoing_call'.l10n
              : 'label_incoming_call'.l10n;
        }

        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
              child: item.withVideo
                  ? SvgImage.asset(
                      'assets/icons/call_video${isMissed && !fromMe ? '_red' : ''}.svg',
                      height: 13,
                    )
                  : SvgImage.asset(
                      'assets/icons/call_audio${isMissed && !fromMe ? '_red' : ''}.svg',
                      height: 15,
                    ),
            ),
            Flexible(child: Text(title, style: style.boldBody)),
            if (time != null) ...[
              const SizedBox(width: 9),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.boldBody.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        );
      } else if (item is ChatForward) {
        // TODO: Implement `ChatForward`.
        content = Text('label_forwarded_message'.l10n, style: style.boldBody);
      } else if (item is ChatInfo) {
        // TODO: Implement `ChatInfo`.
        content = Text(item.action.toString(), style: style.boldBody);
      } else {
        content = Text('err_unknown'.l10n, style: style.boldBody);
      }

      final Widget expanded;

      if (edited.value != null) {
        expanded = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            SvgImage.asset('assets/icons/edit.svg', width: 17, height: 17),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 2,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'label_edit'.l10n,
                      style: style.boldBody.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
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
              ),
            ),
          ],
        );
      } else {
        expanded = FutureBuilder<RxUser?>(
          future: getUser(item.authorId),
          builder: (context, snapshot) {
            final Color color = snapshot.data?.user.value.id == me
                ? style.colors.primary
                : style.colors.userColors[
                    (snapshot.data?.user.value.num.val.sum() ?? 3) %
                        style.colors.userColors.length];

            return Container(
              key: Key('Reply_${replied.indexOf(item)}'),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(width: 2, color: color)),
              ),
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  snapshot.data != null
                      ? Obx(() {
                          return Text(
                            snapshot.data!.user.value.name?.val ??
                                snapshot.data!.user.value.num.val,
                            style: style.boldBody.copyWith(color: color),
                          );
                        })
                      : Text(
                          'dot'.l10n * 3,
                          style: style.boldBody.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
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
      }

      return MouseRegion(
        opaque: false,
        onEnter: (d) => hoveredReply.value = item,
        onExit: (d) => hoveredReply.value = null,
        child: Container(
          margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: expanded),
              Obx(() {
                final Widget child;

                if (hoveredReply.value == item || PlatformUtils.isMobile) {
                  child = WidgetButton(
                    key: const Key('CancelReplyButton'),
                    onPressed: onClose,
                    child: Container(
                      width: 15,
                      height: 15,
                      margin: const EdgeInsets.only(right: 4, top: 4),
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
                  child = const SizedBox();
                }

                return AnimatedSwitcher(
                    duration: 200.milliseconds, child: child);
              }),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Obx(() {
        final bool grab = attachments.isNotEmpty
            ? (125 + 2) * attachments.length > constraints.maxWidth - 16
            : false;

        Widget? previews;

        if (edited.value != null) {
          previews = SingleChildScrollView(
            controller: scrollController,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Dismissible(
                key: Key('${edited.value?.id}'),
                direction: DismissDirection.horizontal,
                onDismissed: (_) => edited.value = null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: WidgetButton(
                    onPressed: () => onItemPressed?.call(edited.value!.id),
                    child: buildPreview(
                      context,
                      edited.value!,
                      onClose: () => edited.value = null,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (quotes.isNotEmpty) {
          previews = ReorderableListView(
            scrollController: scrollController,
            shrinkWrap: true,
            buildDefaultDragHandles: PlatformUtils.isMobile,
            onReorder: (int old, int to) {
              if (old < to) {
                --to;
              }

              quotes.insert(to, quotes.removeAt(old));

              HapticFeedback.lightImpact();
            },
            proxyDecorator: (child, _, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (_, child) {
                  final double t = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(0, 6, t)!;
                  final Color color = Color.lerp(
                    style.colors.transparent,
                    style.colors.onBackgroundOpacity20,
                    t,
                  )!;

                  return InitCallback(
                    callback: HapticFeedback.selectionClick,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          CustomBoxShadow(color: color, blurRadius: elevation),
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
            children: quotes.map((e) {
              return ReorderableDragStartListener(
                key: Key('Handle_${e.item.id}'),
                enabled: !PlatformUtils.isMobile,
                index: quotes.indexOf(e),
                child: Dismissible(
                  key: Key('${e.item.id}'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) {
                    quotes.remove(e);
                    if (quotes.isEmpty) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                    ),
                    child: buildPreview(
                      context,
                      e.item,
                      onClose: () {
                        quotes.remove(e);
                        if (quotes.isEmpty) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        } else if (replied.isNotEmpty) {
          previews = ReorderableListView(
            scrollController: scrollController,
            shrinkWrap: true,
            buildDefaultDragHandles: PlatformUtils.isMobile,
            onReorder: (int old, int to) {
              if (old < to) {
                --to;
              }

              replied.insert(to, replied.removeAt(old));

              HapticFeedback.lightImpact();
            },
            proxyDecorator: (child, _, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (_, child) {
                  final double t = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(0, 6, t)!;
                  final Color color = Color.lerp(
                    style.colors.transparent,
                    style.colors.onBackgroundOpacity20,
                    t,
                  )!;

                  return InitCallback(
                    callback: HapticFeedback.selectionClick,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          CustomBoxShadow(color: color, blurRadius: elevation),
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
            children: replied.map((e) {
              return ReorderableDragStartListener(
                key: Key('Handle_${e.id}'),
                enabled: !PlatformUtils.isMobile,
                index: replied.indexOf(e),
                child: Dismissible(
                  key: Key('${e.id}'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) => replied.remove(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: WidgetButton(
                      onPressed: () => onItemPressed?.call(e.id),
                      child: buildPreview(
                        context,
                        e,
                        onClose: () => replied.remove(e),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }

        return ConditionalBackdropFilter(
          condition: style.cardBlur > 0,
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          borderRadius: BorderRadius.only(
            topLeft: style.cardRadius.topLeft,
            topRight: style.cardRadius.topRight,
          ),
          child: Container(
            color: style.colors.onPrimaryOpacity50,
            child: AnimatedSize(
              duration: 400.milliseconds,
              curve: Curves.ease,
              child: Container(
                width: double.infinity,
                padding: replied.isNotEmpty || attachments.isNotEmpty
                    ? const EdgeInsets.fromLTRB(4, 6, 4, 6)
                    : EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (previews != null)
                      ConstrainedBox(
                        constraints: boxConstraints ??
                            BoxConstraints(
                              maxHeight: max(
                                100,
                                MediaQuery.of(context).size.height / 3.4,
                              ),
                            ),
                        child: Scrollbar(
                          controller: scrollController,
                          child: previews,
                        ),
                      ),
                    if (attachments.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: MouseRegion(
                          cursor: grab
                              ? SystemMouseCursors.grab
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
                                children: attachments
                                    .map((e) => MessageAttachment(
                                          entry: e,
                                          field: field,
                                          rxAttachments: attachments,
                                          hoveredAttachment: hoveredAttachment,
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      });
    });
  }
}
