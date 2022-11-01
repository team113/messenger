// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'dart:io';
import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/call/widget/round_button.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/forward/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/chat/widget/init_callback.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class ChatForwardView extends StatelessWidget {
  const ChatForwardView({
    Key? key,
    required this.from,
    required this.quotes,
    this.text,
    this.attachments,
  }) : super(key: key);

  /// ID of the [Chat] the [quotes] are forwarded from.
  final ChatId from;

  /// [ChatItemQuote]s to be forwarded.
  final List<ChatItemQuote> quotes;

  /// Initial send field value.
  final String? text;

  /// Initial attachments.
  final RxList<Attachment>? attachments;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    ChatId from,
    List<ChatItemQuote> quotes, {
    String? text,
    RxList<Attachment>? attachments,
  }) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      mobilePadding: const EdgeInsets.all(0),
      desktopPadding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: ChatForwardView(
        key: const Key('ChatForwardView'),
        from: from,
        quotes: quotes,
        attachments: attachments,
        text: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ChatForwardController(
        Get.find(),
        Get.find(),
        from: from,
        quotes: quotes,
        text: text,
        attachments: attachments,
      ),
      builder: (ChatForwardController c) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: SearchView(
                    key: const Key('SearchView'),
                    categories: const [
                      SearchCategory.chats,
                      SearchCategory.contacts,
                      SearchCategory.users,
                    ],
                    title: 'label_forward_message'.l10n,
                    onChanged: (SearchViewResults result) {
                      c.searchResults.value = result;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    shadowColor: const Color(0x55000000),
                    iconTheme: const IconThemeData(color: Colors.blue),
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      focusColor: Colors.white,
                      fillColor: Colors.white,
                      hoverColor: Colors.transparent,
                      filled: true,
                      isDense: true,
                      contentPadding: EdgeInsets.fromLTRB(
                        15,
                        PlatformUtils.isDesktop ? 30 : 23,
                        15,
                        0,
                      ),
                    ),
                  ),
                  child: _sendField(context, c),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a visual representation of a [ChatController.repliedMessages].
  Widget _forwardedMessage(
    BuildContext context,
    ChatForwardController c,
    ChatItem item,
  ) {
    Style style = Theme.of(context).extension<Style>()!;
    bool fromMe = item.authorId == c.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
      }

      if (item.attachments.isNotEmpty) {
        additional = item.attachments.map((a) {
          ImageAttachment? image;

          if (a is ImageAttachment) {
            image = a;
          }

          return Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: fromMe
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(4),
              image: image == null
                  ? null
                  : DecorationImage(image: NetworkImage(image.original.url)),
            ),
            width: 30,
            height: 30,
            child: image == null
                ? Icon(
                    Icons.file_copy,
                    color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                    size: 16,
                  )
                : null,
          );
        }).toList();
      }

      if (desc.isNotEmpty) {
        content = Text(
          desc.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.boldBody,
        );
      }
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
      bool fromMe = c.me == item.authorId;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed = item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;
        time = item.conversationStartedAt!.val
            .difference(item.finishedAt!.val)
            .localizedString();
      } else {
        title = item.authorId == c.me
            ? 'label_outgoing_call'.l10n
            : 'label_incoming_call'.l10n;
      }

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: item.withVideo
                ? SvgLoader.asset(
                    'assets/icons/call_video${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 13,
                  )
                : SvgLoader.asset(
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
                style: style.boldBody
                    .copyWith(color: const Color(0xFF888888), fontSize: 13),
              ),
            ),
          ],
        ],
      );
    } else if (item is ChatForward) {
      // TODO: Implement `ChatForward`.
      content = Text('label_forwarded_message'.l10n, style: style.boldBody);
    } else if (item is ChatMemberInfo) {
      // TODO: Implement `ChatMemberInfo`.
      content = Text(item.action.toString(), style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    return MouseRegion(
      opaque: false,
      onEnter: (d) => c.hoveredReply.value = item,
      onExit: (d) => c.hoveredReply.value = null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<RxUser?>(
                  future: c.getUser(item.authorId),
                  builder: (context, snapshot) {
                    Color color = snapshot.data?.user.value.id == c.me
                        ? const Color(0xFF63B4FF)
                        : AvatarWidget.colors[
                            (snapshot.data?.user.value.num.val.sum() ?? 3) %
                                AvatarWidget.colors.length];

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 2,
                            color: color,
                          ),
                        ),
                      ),
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<RxUser?>(
                            future: c.getUser(item.authorId),
                            builder: (context, snapshot) {
                              String? name;
                              if (snapshot.hasData) {
                                name = snapshot.data?.user.value.name?.val;
                                if (snapshot.data?.user.value != null) {
                                  return Obx(() {
                                    Color color =
                                        snapshot.data?.user.value.id == c.me
                                            ? const Color(0xFF63B4FF)
                                            : AvatarWidget.colors[snapshot
                                                    .data!.user.value.num.val
                                                    .sum() %
                                                AvatarWidget.colors.length];

                                    return Text(
                                        snapshot.data!.user.value.name?.val ??
                                            snapshot.data!.user.value.num.val,
                                        style: style.boldBody
                                            .copyWith(color: color));
                                  });
                                }
                              }

                              return Text(
                                name ?? '...',
                                style: style.boldBody
                                    .copyWith(color: const Color(0xFF63B4FF)),
                              );
                            },
                          ),
                          if (content != null) ...[
                            const SizedBox(height: 2),
                            DefaultTextStyle.merge(
                              maxLines: 1,
                              child: content,
                            ),
                          ],
                          if (additional.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: additional),
                          ],
                        ],
                      ),
                    );
                  }),
            ),
            AnimatedSwitcher(
              duration: 200.milliseconds,
              child: c.hoveredReply.value == item || PlatformUtils.isMobile
                  ? WidgetButton(
                      key: const Key('CancelReplyButton'),
                      onPressed: () {
                        c.quotes.removeWhere((e) => e.item == item);
                        if (c.quotes.isEmpty) {
                          Navigator.of(context).pop();
                        }
                      },
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
                          child: Center(
                            child: SvgLoader.asset(
                              'assets/icons/close_primary.svg',
                              width: 7,
                              height: 7,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a visual representation of the provided [Attachment].
  Widget _buildAttachment(ChatForwardController c, Attachment e) {
    bool isImage =
        (e is ImageAttachment || (e is LocalAttachment && e.file.isImage));

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFD8D8D8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: e is LocalAttachment
                  ? e.file.bytes == null
                      ? e.file.path == null
                          ? const Center(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : e.file.isSvg
                              ? SvgLoader.file(
                                  File(e.file.path!),
                                  width: 80,
                                  height: 80,
                                )
                              : Image.file(
                                  File(e.file.path!),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                )
                      : e.file.isSvg
                          ? SvgLoader.bytes(
                              e.file.bytes!,
                              width: 80,
                              height: 80,
                            )
                          : Image.memory(
                              e.file.bytes!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            )
                  : Image.network(
                      e.original.url,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 80,
                        height: 80,
                        child:
                            Center(child: Icon(Icons.error, color: Colors.red)),
                      ),
                    ),
            )
          else
            SizedBox(
              width: 80,
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insert_drive_file_sharp),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      e.filename,
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Center(
            child: SizedBox(
              height: 30,
              width: 30,
              child: ElasticAnimatedSwitcher(
                child: e is LocalAttachment
                    ? e.status.value == SendingStatus.error
                        ? Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          )
                        : const SizedBox()
                    : const SizedBox(),
              ),
            ),
          ),
          if (!c.send.status.value.isLoading)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 2, top: 3),
                child: InkWell(
                  key: const Key('RemovePickedFile'),
                  onTap: () => c.attachments.remove(e),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0x99FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.black, size: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Returns a [ReactiveTextField] for constructing a [ChatMessage] to attach
  /// to the [quotes] to be forwarded.
  Widget _sendField(BuildContext context, ChatForwardController c) {
    Style style = Theme.of(context).extension<Style>()!;
    const double iconSize = 22;
    return Container(
      key: const Key('ChatForwardView'),
      decoration: BoxDecoration(
        borderRadius: style.cardRadius,
        boxShadow: const [
          CustomBoxShadow(blurRadius: 8, color: Color(0x22000000)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            bool grab =
                (125 + 2) * c.attachments.length > constraints.maxWidth - 16;
            return Stack(
              children: [
                Obx(() {
                  return ConditionalBackdropFilter(
                    condition: style.cardBlur > 0,
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    borderRadius: BorderRadius.only(
                      topLeft: style.cardRadius.topLeft,
                      topRight: style.cardRadius.topRight,
                    ),
                    child: AnimatedSizeAndFade(
                      fadeDuration: 400.milliseconds,
                      sizeDuration: 400.milliseconds,
                      fadeInCurve: Curves.ease,
                      fadeOutCurve: Curves.ease,
                      sizeCurve: Curves.ease,
                      child: Container(
                        key: const Key('Attachments'),
                        width: double.infinity,
                        color: const Color(0xFFFBFBFB),
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height / 3,
                              ),
                              child: ReorderableListView(
                                shrinkWrap: true,
                                buildDefaultDragHandles: PlatformUtils.isMobile,
                                onReorder: (int old, int to) {
                                  if (old < to) {
                                    --to;
                                  }

                                  final ChatItemQuote item =
                                      c.quotes.removeAt(old);
                                  c.quotes.insert(to, item);

                                  HapticFeedback.lightImpact();
                                },
                                proxyDecorator: (child, i, animation) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (
                                      BuildContext context,
                                      Widget? child,
                                    ) {
                                      final double t = Curves.easeInOut
                                          .transform(animation.value);
                                      final double elevation =
                                          lerpDouble(0, 6, t)!;
                                      final Color color = Color.lerp(
                                        const Color(0x00000000),
                                        const Color(0x33000000),
                                        t,
                                      )!;

                                      return InitCallback(
                                        callback: HapticFeedback.selectionClick,
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
                                padding: const EdgeInsets.fromLTRB(1, 0, 1, 0),
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: _forwardedMessage(
                                          context,
                                          c,
                                          e.item,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: c.attachments
                                          .map(
                                            (e) => _buildAttachment(
                                              c,
                                              e,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
          ConditionalBackdropFilter(
            condition: style.cardBlur > 0,
            filter: ImageFilter.blur(
              sigmaX: style.cardBlur,
              sigmaY: style.cardBlur,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.zero,
              topRight: Radius.zero,
              bottomLeft: style.cardRadius.bottomLeft,
              bottomRight: style.cardRadius.bottomLeft,
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(color: style.cardColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!PlatformUtils.isMobile || PlatformUtils.isWeb)
                    WidgetButton(
                      onPressed: c.pickFile,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: SvgLoader.asset(
                              'assets/icons/attach.svg',
                              height: iconSize,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    WidgetButton(
                      onPressed: () {
                        ModalPopup.show(
                          context: context,
                          mobileConstraints: const BoxConstraints(),
                          mobilePadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          desktopConstraints:
                              const BoxConstraints(maxWidth: 400),
                          child: _attachmentSelection(c),
                        );
                      },
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: SvgLoader.asset(
                              'assets/icons/attach.svg',
                              height: iconSize,
                            ),
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
                          key: const Key('ForwardField'),
                          state: c.send,
                          hint: 'label_send_message_hint'.l10n,
                          minLines: 1,
                          maxLines: 7,
                          filled: false,
                          dense: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          style: style.boldBody.copyWith(fontSize: 17),
                          type: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 0),
                  Obx(() {
                    return WidgetButton(
                      onPressed: c.searchResults.value == null
                          ? null
                          : () {
                              c.forward();
                              Navigator.of(context).pop(true);
                            },
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: SizedBox(
                              key: const Key('SendForward'),
                              width: 25.18,
                              height: 22.85,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: SvgLoader.asset(
                                  'assets/icons/send.svg',
                                  height: 22.85,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentSelection(ChatForwardController c) {
    return Builder(builder: (context) {
      Widget button({
        required String text,
        IconData? icon,
        Widget? child,
        void Function()? onPressed,
      }) {
        return RoundFloatingButton(
          text: text,
          withBlur: false,
          onPressed: () {
            onPressed?.call();
            Navigator.of(context).pop();
          },
          textStyle: const TextStyle(
            fontSize: 15,
            color: Colors.black,
          ),
          color: const Color(0xFF63B4FF),
          child: SizedBox(
            width: 60,
            height: 60,
            child: child ?? Icon(icon, color: Colors.white, size: 30),
          ),
        );
      }

      bool isAndroid = PlatformUtils.isAndroid;

      List<Widget> children = [
        button(
          text: isAndroid ? 'label_photo'.l10n : 'label_media_camera'.l10n,
          onPressed: c.pickImageFromCamera,
          child: SvgLoader.asset(
            'assets/icons/make_photo.svg',
            width: 60,
            height: 60,
          ),
        ),
        if (isAndroid)
          button(
            text: 'label_video'.l10n,
            onPressed: c.pickVideoFromCamera,
            child: SvgLoader.asset(
              'assets/icons/video_on.svg',
              width: 60,
              height: 60,
            ),
          ),
        button(
          text: 'label_gallery'.l10n,
          onPressed: c.pickMedia,
          child: SvgLoader.asset(
            'assets/icons/gallery.svg',
            width: 60,
            height: 60,
          ),
        ),
        button(
          text: 'label_file'.l10n,
          onPressed: c.pickFile,
          child: SvgLoader.asset(
            'assets/icons/file.svg',
            width: 60,
            height: 60,
          ),
        ),
      ];

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
          const SizedBox(height: 40),
          OutlinedRoundedButton(
            key: const Key('CloseButton'),
            title: Text('btn_close'.l10n),
            onPressed: Navigator.of(context).pop,
            color: const Color(0xFFEEEEEE),
          ),
          const SizedBox(height: 10),
        ],
      );
    });
  }
}

/// Custom scroll behavior.
class CustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}
