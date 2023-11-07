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

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart';
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/file.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/page/call/controller.dart';
import '/ui/page/call/widget/animated_participant.dart';
import '/ui/page/call/widget/call_button.dart';
import '/ui/page/call/widget/call_title.dart';
import '/ui/page/call/widget/chat_info_card.dart';
import '/ui/page/call/widget/dock.dart';
import '/ui/page/call/widget/dock_decorator.dart';
import '/ui/page/call/widget/double_bounce_indicator.dart';
import '/ui/page/call/widget/drop_box.dart';
import '/ui/page/call/widget/launchpad.dart';
import '/ui/page/call/widget/raised_hand.dart';
import '/ui/page/call/widget/reorderable_fit.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/chat/widget/chat_forward.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/chat/widget/time_label.dart';
import '/ui/page/home/page/chat/widget/unread_label.dart';
import '/ui/page/home/page/my_profile/widget/background_preview.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/page/my_profile/widget/login.dart';
import '/ui/page/home/page/my_profile/widget/name.dart';
import '/ui/page/home/page/my_profile/widget/status.dart';
import '/ui/page/home/page/my_profile/widget/switch_field.dart';
import '/ui/page/home/page/user/widget/blocklist_record.dart';
import '/ui/page/home/page/user/widget/presence.dart';
import '/ui/page/home/page/user/widget/status.dart';
import '/ui/page/home/tab/chats/widget/recent_chat.dart';
import '/ui/page/home/tab/chats/widget/unread_counter.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/page/home/widget/gallery_button.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/page/home/widget/shadowed_rounded_button.dart';
import '/ui/page/home/widget/sharable.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/page/login/widget/primary_button.dart';
import '/ui/page/login/widget/sign_button.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/work/widget/interactive_logo.dart';
import '/ui/page/work/widget/vacancy_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/menu_button.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/obs/rxlist.dart';
import '/util/obs/rxmap.dart';
import '/util/platform_utils.dart';
import 'widget/cat.dart';
import 'widget/playable_asset.dart';

/// Widgets view of the [Routes.style] page.
class WidgetsView extends StatelessWidget {
  const WidgetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      cacheExtent: 3000,
      children: [
        ..._images(context),
        ..._chat(context),
        ..._animations(context),
        ..._avatars(context),
        ..._fields(context),
        ..._buttons(context),
        ..._switches(context),
        ..._tiles(context),
        ..._system(context),
        ..._navigation(context),
        ..._sounds(context),
      ],
    );
  }

  /// Returns the provided [child] wrapped by a [Block].
  Widget _headline({
    String? title,
    required Widget child,
    Widget? subtitle,
    Color? color,
    Color? headlineColor,
    EdgeInsets padding = const EdgeInsets.fromLTRB(32, 16, 32, 16),
    bool top = true,
    bool bottom = true,
  }) {
    return Block(
      color: color,
      headline: title ?? child.runtimeType.toString(),
      headlineColor: headlineColor,
      topMargin: top ? 32 : null,
      maxWidth: 450,
      padding: padding,
      children: [
        if (top) const SizedBox(height: 16),
        SelectionContainer.disabled(child: child),
        if (bottom) ...[
          const SizedBox(height: 8),
          if (subtitle != null) SelectionContainer.disabled(child: subtitle),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// Returns the provided [children] wrapped by a [Block].
  Widget _headlines({
    Color? color,
    required List<({String label, Widget widget})> children,
  }) {
    final style = Theme.of(router.context!).style;

    return Block(
      padding: EdgeInsets.zero,
      color: color,
      topMargin: 32,
      maxWidth: 450,
      children: [
        ...children.mapIndexed((i, e) {
          return [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                e.label,
                style: style.fonts.small.regular.secondaryHighlightDarkest,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SelectionContainer.disabled(child: e.widget),
            ),
            if (i != children.length - 1) const SizedBox(height: 32),
          ];
        }).flattened,
        const SizedBox(height: 16),
      ],
    );
  }

  /// Returns contents of the images section.
  List<Widget> _images(BuildContext context) {
    return [
      _headline(
        child: const InteractiveLogo(),
        subtitle: _downloadButton('head_0.svg', prefix: 'logo'),
        top: false,
      ),
      _headline(
        title: 'background_light.svg',
        child: const SvgImage.asset(
          'assets/images/background_light.svg',
          height: 300,
          fit: BoxFit.cover,
        ),
        subtitle: _downloadButton('background_light'),
      ),
      _headline(
        title: 'background_dark.svg',
        child: const SvgImage.asset(
          'assets/images/background_dark.svg',
          height: 300,
          fit: BoxFit.cover,
        ),
        subtitle: _downloadButton('background_dark'),
      ),
    ];
  }

  /// Returns the button downloading the provided [asset].
  Widget _downloadButton(String asset, {String? prefix}) {
    final style = Theme.of(router.context!).style;

    return SelectionContainer.disabled(
      child: WidgetButton(
        onPressed: () async {
          final file = await PlatformUtils.saveTo(
            '${Config.origin}/assets/assets/icons$prefix/$asset',
          );
          if (file != null) {
            MessagePopup.success('$asset downloaded');
          }
        },
        child: Text(
          'Download',
          style: style.fonts.smaller.regular.primary,
        ),
      ),
    );
  }

  /// Returns contents of the chat section.
  List<Widget> _chat(BuildContext context) {
    final style = Theme.of(context).style;

    ChatItem message({
      bool fromMe = true,
      SendingStatus status = SendingStatus.sent,
      String? text = 'Lorem ipsum',
      List<String> attachments = const [],
      List<ChatItemQuote> repliesTo = const [],
    }) {
      NativeFile image =
          NativeFile(name: 'Image', size: 2, bytes: CatImage.bytes)..readFile();
      image.dimensions.value = CatImage.size;

      return ChatMessage(
        ChatItemId.local(),
        ChatId.local(const UserId('me')),
        User(UserId(fromMe ? 'me' : '0'), UserNum('1234123412341234')),
        PreciseDateTime.now(),
        text: text == null ? null : ChatMessageText(text),
        attachments: attachments.map((e) {
          if (e == 'file') {
            return FileAttachment(
              id: AttachmentId.local(),
              original: PlainFile(relativeRef: '', size: 12300000),
              filename: 'Document.pdf',
            );
          } else {
            return LocalAttachment(
              image,
              status: SendingStatus.sent,
            );
          }
        }).toList(),
        status: status,
        repliesTo: repliesTo,
      );
    }

    ChatItem info({
      bool fromMe = true,
      required ChatInfoAction action,
    }) {
      return ChatInfo(
        ChatItemId.local(),
        ChatId.local(const UserId('me')),
        User(UserId(fromMe ? 'me' : '0'), UserNum('1234123412341234')),
        PreciseDateTime.now(),
        action: action,
      );
    }

    ChatItem call({
      bool fromMe = true,
      bool withVideo = false,
      bool started = false,
      int? finishReasonIndex,
    }) {
      return ChatCall(
        const ChatItemId('dwd'),
        ChatId.local(const UserId('me')),
        User(UserId(fromMe ? 'me' : '0'), UserNum('1234123412341234')),
        PreciseDateTime.now(),
        withVideo: withVideo,
        members: [],
        conversationStartedAt: started
            ? PreciseDateTime.now().subtract(const Duration(hours: 1))
            : null,
        finishReasonIndex: finishReasonIndex,
        finishedAt: finishReasonIndex == null ? null : PreciseDateTime.now(),
      );
    }

    Widget chatItem(
      ChatItem v, {
      bool delivered = false,
      bool read = false,
      ChatKind kind = ChatKind.dialog,
    }) {
      return ChatItemWidget(
        item: Rx(v),
        chat: Rx(
          Chat(
            ChatId.local(const UserId('me')),
            kindIndex: kind.index,
            lastDelivery: delivered
                ? null
                : PreciseDateTime.fromMicrosecondsSinceEpoch(0),
            lastReads: [
              if (read)
                LastChatRead(
                  const UserId('fqw'),
                  PreciseDateTime(DateTime(15000)),
                ),
            ],
          ),
        ),
        me: const UserId('me'),
        reads: [
          if (read)
            LastChatRead(
              const UserId('fqw'),
              PreciseDateTime(DateTime(15000)),
            ),
        ],
      );
    }

    Widget chatForward(
      List<ChatItem> v, {
      ChatItem? note,
      bool delivered = false,
      bool read = false,
      bool fromMe = true,
      ChatKind kind = ChatKind.dialog,
    }) {
      return ChatForwardWidget(
        forwards: RxList(
          v
              .map(
                (e) => Rx(
                  ChatForward(
                    e.id,
                    e.chatId,
                    e.author,
                    e.at,
                    quote: ChatItemQuote.from(e),
                  ),
                ),
              )
              .toList(),
        ),
        authorId: fromMe ? const UserId('me') : const UserId('0'),
        note: Rx(note == null ? null : Rx(note)),
        chat: Rx(
          Chat(
            ChatId.local(const UserId('me')),
            kindIndex: kind.index,
            lastDelivery: delivered
                ? null
                : PreciseDateTime.fromMicrosecondsSinceEpoch(0),
            lastReads: [
              if (read)
                LastChatRead(
                  const UserId('fqw'),
                  PreciseDateTime(DateTime(15000)),
                ),
            ],
          ),
        ),
        me: const UserId('me'),
        reads: [
          if (read)
            LastChatRead(
              const UserId('fqw'),
              PreciseDateTime(DateTime(15000)),
            ),
        ],
      );
    }

    return [
      _headline(
        title: 'TimeLabelWidget',
        color: style.colors.onBackgroundOpacity7,
        child: Column(
          children: [
            TimeLabelWidget(
              DateTime.now().subtract(const Duration(minutes: 10)),
            ),
            TimeLabelWidget(
              DateTime.now().subtract(const Duration(days: 1)),
            ),
            TimeLabelWidget(
              DateTime.now().subtract(const Duration(days: 7)),
            ),
            TimeLabelWidget(
              DateTime.now().subtract(const Duration(days: 64)),
            ),
            TimeLabelWidget(
              DateTime.now().subtract(const Duration(days: 365 * 4)),
            )
          ],
        ),
      ),
      _headline(
        title: 'UnreadLabel',
        color: style.colors.onBackgroundOpacity7,
        child: const Column(
          children: [UnreadLabel(123)],
        ),
      ),
      _headline(
        title: 'ChatItemWidget',
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
        color: style.colors.onBackgroundOpacity7,
        child: Column(
          children: [
            chatItem(
              message(
                status: SendingStatus.sending,
                text: 'Sending message...',
              ),
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.error, text: 'Error'),
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.sent, text: 'Sent message'),
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.sent, text: 'Delivered message'),
              kind: ChatKind.dialog,
              delivered: true,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.sent, text: 'Read message'),
              kind: ChatKind.dialog,
              read: true,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: 'Received message',
                fromMe: false,
              ),
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // Replies.
            chatItem(
              message(
                status: SendingStatus.sent,
                text: 'Sent reply',
                fromMe: true,
                repliesTo: [
                  ChatMessageQuote(
                    author: const UserId('me'),
                    at: PreciseDateTime.now(),
                    text: const ChatMessageText('Replied message'),
                  )
                ],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: 'Received reply',
                fromMe: false,
                repliesTo: [
                  ChatMessageQuote(
                    author: const UserId('me'),
                    at: PreciseDateTime.now(),
                    text: const ChatMessageText('Replied message'),
                  )
                ],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // Image attachments.
            chatItem(
              message(
                status: SendingStatus.sent,
                text: null,
                fromMe: true,
                attachments: ['image'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: null,
                fromMe: false,
                attachments: ['image'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // File attachments.
            chatItem(
              message(
                status: SendingStatus.sent,
                text: 'Message with file attachment',
                fromMe: true,
                attachments: ['file'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: null,
                fromMe: false,
                attachments: ['file'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // Images attachments.
            chatItem(
              message(
                status: SendingStatus.sent,
                fromMe: true,
                attachments: [
                  'file',
                  'file',
                  'image',
                  'image',
                  'image',
                  'image',
                  'image'
                ],
                text: 'Message with file and image attachments',
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: null,
                fromMe: false,
                attachments: ['file', 'file', 'image', 'image', 'image'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // Info.
            const SizedBox(height: 8),
            chatItem(info(action: const ChatInfoActionCreated(null))),
            const SizedBox(height: 8),
            chatItem(
              info(
                action: ChatInfoActionMemberAdded(
                  User(
                    const UserId('me'),
                    UserNum('1234123412341234'),
                    name: UserName('added'),
                  ),
                  null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            chatItem(
              info(
                fromMe: false,
                action: ChatInfoActionMemberAdded(
                  User(
                    const UserId('me'),
                    UserNum('1234123412341234'),
                    name: UserName('User'),
                  ),
                  null,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Call.
            chatItem(call(withVideo: true), read: true),
            const SizedBox(height: 8),
            chatItem(call(withVideo: true, fromMe: false), read: true),
            const SizedBox(height: 8),
            chatItem(call(started: true), read: true),
            const SizedBox(height: 8),
            chatItem(call(started: true, fromMe: false), read: true),
            const SizedBox(height: 8),
            chatItem(call(finishReasonIndex: 2, started: true), read: true),
            const SizedBox(height: 8),
            chatItem(
              call(finishReasonIndex: 2, started: true, fromMe: false),
              read: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      _headline(
        title: 'ChatForwardWidget',
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
        color: style.colors.onBackgroundOpacity7,
        child: Column(
          children: [
            const SizedBox(height: 32),
            chatForward(
              [message(text: 'Forwarded message')],
              read: true,
              note: message(text: 'Comment'),
            ),
            const SizedBox(height: 8),
            chatForward(
              [message(text: 'Forwarded message')],
              read: true,
              fromMe: false,
              note: message(text: 'Comment'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ];
  }

  /// Returns contents of the animations section.
  List<Widget> _animations(BuildContext context) {
    return [
      _headline(
        title: 'DoubleBounceLoadingIndicator',
        child: const SizedBox(child: DoubleBounceLoadingIndicator()),
      ),
      _headline(
        title: 'AnimatedTyping',
        child: const SizedBox(
          height: 32,
          child: Center(child: AnimatedTyping()),
        ),
      ),
      _headlines(
        children: [
          (
            label: 'CustomProgressIndicator',
            widget:
                const SizedBox(child: Center(child: CustomProgressIndicator()))
          ),
          (
            label: 'CustomProgressIndicator.big',
            widget: const SizedBox(
              child: Center(child: CustomProgressIndicator.big()),
            )
          ),
          (
            label: 'CustomProgressIndicator.primary',
            widget: const SizedBox(
              child: Center(child: CustomProgressIndicator.primary()),
            )
          ),
        ],
      ),
    ];
  }

  /// Returns contents of the avatars section.
  List<Widget> _avatars(BuildContext context) {
    ({String label, Widget widget}) avatars(String title, AvatarRadius radius) {
      return (
        label: 'AvatarWidget(radius: ${radius.toDouble().toStringAsFixed(0)})',
        widget: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AvatarWidget(title: title, radius: radius),
            AvatarWidget(
              radius: radius,
              child: Image.memory(CatImage.bytes, fit: BoxFit.cover),
            ),
          ],
        )
      );
    }

    return [
      _headlines(
        children: AvatarRadius.values.reversed
            .mapIndexed(
              (i, e) => avatars(i.toString().padLeft(2, '0'), e),
            )
            .toList(),
      ),
    ];
  }

  /// Returns contents of the fields section.
  List<Widget> _fields(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      _headlines(
        children: [
          (
            label: 'ReactiveTextField',
            widget: ReactiveTextField(
              state: TextFieldState(approvable: true),
              hint: 'Hint',
              label: 'Label',
            ),
          ),
          (
            label: 'ReactiveTextField(error)',
            widget: ReactiveTextField(
              state: TextFieldState(text: 'Text', error: 'Error text'),
              hint: 'Hint',
              label: 'Label',
            ),
          ),
          (
            label: 'ReactiveTextField(subtitle)',
            widget: ReactiveTextField(
              key: const Key('LoginField'),
              state: TextFieldState(text: 'Text'),
              onSuffixPressed: () {},
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: const SvgImage.asset(
                  'assets/icons/copy.svg',
                  width: 14.53,
                  height: 17,
                ),
              ),
              label: 'Label',
              hint: 'Hint',
              subtitle: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Subtitle with: '.l10n,
                      style: style.fonts.small.regular.secondary,
                    ),
                    TextSpan(
                      text: 'clickable.',
                      style: style.fonts.small.regular.primary,
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            )
          ),
          (
            label: 'ReactiveTextField(obscure)',
            widget: ObxValue(
              (b) {
                return ReactiveTextField(
                  state: TextFieldState(text: 'Text'),
                  label: 'Obscured text'.l10n,
                  obscure: b.value,
                  onSuffixPressed: b.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/${b.value ? 'visible_off' : 'visible_on'}.svg',
                    width: 17.07,
                    height: b.value ? 15.14 : 11.97,
                  ),
                );
              },
              RxBool(true),
            ),
          ),
        ],
      ),
      _headline(
        child: CopyableTextField(
          state: TextFieldState(text: 'Text to copy', editable: false),
          label: 'Label',
        ),
      ),
      _headline(
        child: SharableTextField(text: 'Text to share', label: 'Label'),
      ),
      _headline(
        child: MessageFieldView(
          controller: MessageFieldController(null, null, null),
        ),
      ),
      _headline(
        title: 'CustomAppBar(search)',
        child: SizedBox(
          height: 60,
          width: 400,
          child: CustomAppBar(
            withTop: false,
            border: Border.all(color: style.colors.primary, width: 2),
            title: Theme(
              data: MessageFieldView.theme(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Transform.translate(
                  offset: const Offset(0, 1),
                  child: ReactiveTextField(
                    state: TextFieldState(),
                    hint: 'label_search'.l10n,
                    maxLines: 1,
                    filled: false,
                    dense: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    style: style.fonts.medium.regular.onBackground,
                    onChanged: () {},
                  ),
                ),
              ),
            ),
            leading: [
              AnimatedButton(
                decorator: (child) => Container(
                  padding: const EdgeInsets.only(left: 20, right: 6),
                  height: double.infinity,
                  child: child,
                ),
                onPressed: () {},
                child: Icon(
                  key: const Key('ArrowBack'),
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: style.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
      _headline(
        title: 'ReactiveTextField(search)',
        child: ReactiveTextField(
          key: const Key('SearchTextField'),
          state: TextFieldState(),
          label: 'label_search'.l10n,
          style: style.fonts.normal.regular.onBackground,
          onChanged: () {},
        ),
      ),
      _headline(child: const UserLoginField(null)),
      _headline(child: const UserNameField(null)),
      _headline(child: const UserTextStatusField(null)),
      _headline(child: const UserPresenceField(Presence.present, 'Online')),
      _headline(
        child: const UserStatusCopyable(UserTextStatus.unchecked('Status')),
      ),
      _headline(child: const DirectLinkField(null)),
      _headline(
        child: BlocklistRecordWidget(
          BlocklistRecord(
            userId: const UserId('me'),
            at: PreciseDateTime.now(),
          ),
        ),
      ),
    ];
  }

  /// Returns contents of the buttons section.
  List<Widget> _buttons(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      _headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: [
          (
            label: 'MenuButton',
            widget: MenuButton(
              title: 'Title',
              subtitle: 'Subtitle',
              leading: const SvgImage.asset(
                'assets/icons/frontend.svg',
                width: 25.87,
                height: 32,
              ),
              inverted: false,
              onPressed: () {},
            ),
          ),
          (
            label: 'MenuButton(inverted: true)',
            widget: MenuButton(
              title: 'Title',
              subtitle: 'Subtitle',
              leading: const SvgImage.asset(
                'assets/icons/frontend_white.svg',
                width: 25.87,
                height: 32,
              ),
              inverted: true,
              onPressed: () {},
            ),
          ),
        ],
      ),
      _headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: [
          (
            label: 'OutlinedRoundedButton(title)',
            widget: OutlinedRoundedButton(
              title: const Text('Title'),
              onPressed: () {},
            ),
          ),
          (
            label: 'OutlinedRoundedButton(subtitle)',
            widget: OutlinedRoundedButton(
              subtitle: const Text('Subtitle'),
              onPressed: () {},
            ),
          ),
        ],
      ),
      _headline(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        child: ShadowedRoundedButton(
          onPressed: () {},
          child: const Text('Label'),
        ),
      ),
      _headline(
        title: 'PrimaryButton',
        child: PrimaryButton(onPressed: () {}, title: 'PrimaryButton'),
      ),
      _headline(
        child: WidgetButton(
          onPressed: () {},
          child: Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              color: style.colors.onBackgroundOpacity13,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Clickable area')),
          ),
        ),
      ),
      _headlines(
        children: [
          (
            label: 'SignButton',
            widget: SignButton(
              onPressed: () {},
              title: 'Label',
              asset: 'password',
            ),
          ),
        ],
      ),
      _headlines(
        children: [
          (
            label: 'StyledCupertinoButton',
            widget:
                StyledCupertinoButton(onPressed: () {}, label: 'Clickable text')
          ),
          (
            label: 'StyledCupertinoButton.primary',
            widget: StyledCupertinoButton(
              onPressed: () {},
              label: 'Clickable text',
              style: style.fonts.medium.regular.onBackground,
            ),
          ),
        ],
      ),
      _headlines(
        children: [
          (
            label: 'RectangleButton',
            widget: RectangleButton(onPressed: () {}, label: 'Label'),
          ),
          (
            label: 'RectangleButton(selected: true)',
            widget: RectangleButton(
              onPressed: () {},
              label: 'Label',
              selected: true,
            ),
          ),
          (
            label: 'RectangleButton.radio',
            widget: RectangleButton(
              onPressed: () {},
              label: 'Label',
              radio: true,
            ),
          ),
          (
            label: 'RectangleButton.radio(selected: true)',
            widget: RectangleButton(
              onPressed: () {},
              label: 'Label',
              selected: true,
              radio: true,
            ),
          ),
        ],
      ),
      _headline(
        title: 'AnimatedButton',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedButton(
              onPressed: () {},
              child: const SvgImage.asset(
                'assets/icons/chats.svg',
                width: 39.26,
                height: 33.5,
              ),
            ),
            const SizedBox(width: 32),
            AnimatedButton(
              onPressed: () {},
              child: const SvgImage.asset(
                'assets/icons/chat_video_call.svg',
                width: 27.71,
                height: 19,
              ),
            ),
            const SizedBox(width: 32),
            AnimatedButton(
              onPressed: () {},
              child: const SvgImage.asset(
                'assets/icons/send.svg',
                width: 25.44,
                height: 21.91,
              ),
            ),
          ],
        ),
      ),
      _headline(
        title: 'CallButtonWidget',
        color: style.colors.primaryAuxiliaryOpacity25,
        headlineColor: style.colors.onPrimary,
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CallButtonWidget(
              color: style.colors.onSecondaryOpacity50,
              onPressed: () {},
              withBlur: true,
              big: true,
              asset: 'fullscreen_enter_white',
              assetWidth: 22,
            ),
            const SizedBox(width: 32),
            CallButtonWidget(
              onPressed: () {},
              hint: 'Hint'.l10n,
              asset: 'screen_share_on'.l10n,
              hinted: true,
              expanded: true,
              big: true,
            ),
            const SizedBox(width: 32),
            CallButtonWidget(
              hint: 'Hint'.l10n,
              asset: 'screen_share_on'.l10n,
              hinted: true,
              onPressed: () {},
            ),
          ],
        ),
      ),
      _headline(
        title: 'GalleryButton',
        color: style.colors.primaryAuxiliaryOpacity25,
        headlineColor: style.colors.onPrimary,
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GalleryButton(
              onPressed: () {},
              child: Icon(
                Icons.close_rounded,
                color: style.colors.onPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 32),
            GalleryButton(
              onPressed: () {},
              assetWidth: 22,
              asset: 'fullscreen_enter_white',
            ),
            const SizedBox(width: 32),
            GalleryButton(
              onPressed: () {},
              child: Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: style.colors.onPrimary,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
      _headlines(
        children: [
          (
            label: 'DownloadButton.windows',
            widget: const DownloadButton.windows(),
          ),
          (
            label: 'DownloadButton.macos',
            widget: const DownloadButton.macos(),
          ),
          (
            label: 'DownloadButton.linux',
            widget: const DownloadButton.linux(),
          ),
          (
            label: 'DownloadButton.appStore',
            widget: const DownloadButton.appStore(),
          ),
          (
            label: 'DownloadButton.googlePlay',
            widget: const DownloadButton.googlePlay(),
          ),
          (
            label: 'DownloadButton.android',
            widget: const DownloadButton.android(),
          ),
        ],
      ),
      _headline(child: StyledBackButton(onPressed: () {})),
      _headlines(
        children: [
          (
            label: 'FloatingActionButton(arrow_upward)',
            widget: FloatingActionButton.small(
              heroTag: '1',
              onPressed: () {},
              child: const Icon(Icons.arrow_upward),
            ),
          ),
          (
            label: 'FloatingActionButton(arrow_downward)',
            widget: FloatingActionButton.small(
              heroTag: '2',
              onPressed: () {},
              child: const Icon(Icons.arrow_downward),
            ),
          ),
        ],
      ),
      _headline(child: UnblockButton(() {})),
      _headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: WorkTab.values
            .map(
              (e) => (
                label: 'VacancyWorkButton(${e.name})',
                widget: VacancyWorkButton(e, onPressed: (_) {}),
              ),
            )
            .toList(),
      ),
    ];
  }

  /// Returns contents of the switches section.
  List<Widget> _switches(BuildContext context) {
    return [
      _headline(
        title: 'SwitchField',
        child: ObxValue(
          (value) {
            return SwitchField(
              text: 'Label',
              value: value.value,
              onChanged: (b) => value.value = b,
            );
          },
          false.obs,
        ),
      ),
    ];
  }

  /// Returns contents of the tiles section.
  List<Widget> _tiles(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      _headlines(
        children: [
          (
            label: 'ContextMenu(desktop)',
            widget: const ContextMenu(
              actions: [
                ContextMenuButton(label: 'Action 1'),
                ContextMenuButton(label: 'Action 2'),
                ContextMenuButton(label: 'Action 3'),
                ContextMenuDivider(),
                ContextMenuButton(label: 'Action 4'),
              ],
            )
          ),
          (
            label: 'ContextMenu(mobile)',
            widget: const ContextMenu(
              mobile: true,
              actions: [
                ContextMenuButton(label: 'Action 1', mobile: true),
                ContextMenuButton(label: 'Action 2', mobile: true),
                ContextMenuButton(label: 'Action 3', mobile: true),
                ContextMenuButton(label: 'Action 4', mobile: true),
              ],
            ),
          ),
        ],
      ),
      _headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: [
          (
            label: 'RecentChatTile',
            widget: RecentChatTile(DummyRxChat(), onTap: () {}),
          ),
          (
            label: 'RecentChatTile(selected)',
            widget: RecentChatTile(
              DummyRxChat(),
              onTap: () {},
              selected: true,
            ),
          ),
          (
            label: 'RecentChatTile(trailing)',
            widget: RecentChatTile(
              DummyRxChat(),
              onTap: () {},
              selected: false,
              trailing: const [SelectedDot(selected: false, size: 20)],
            ),
          ),
        ],
      ),
      _headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: [
          (
            label: 'ChatTile',
            widget: ChatTile(chat: DummyRxChat(), onTap: () {}),
          ),
          (
            label: 'ChatTile(selected)',
            widget: ChatTile(
              chat: DummyRxChat(),
              onTap: () {},
              selected: true,
            ),
          ),
        ],
      ),
      Builder(builder: (context) {
        final MyUser myUser = MyUser(
          id: const UserId('123'),
          num: UserNum('1234123412341234'),
          emails: MyUserEmails(confirmed: []),
          phones: MyUserPhones(confirmed: []),
          presenceIndex: 0,
          online: true,
        );
        return _headlines(
          color: Color.alphaBlend(
            style.sidebarColor,
            style.colors.onBackgroundOpacity7,
          ),
          children: [
            (
              label: 'ContactTile',
              widget: ContactTile(
                myUser: myUser,
                onTap: () {},
              ),
            ),
            (
              label: 'ContactTile(selected)',
              widget: ContactTile(
                myUser: myUser,
                onTap: () {},
                selected: true,
              ),
            ),
            (
              label: 'ContactTile(trailing)',
              widget: ContactTile(
                myUser: myUser,
                onTap: () {},
                selected: false,
                trailing: const [SelectedDot(selected: false, size: 20)],
              ),
            ),
          ],
        );
      }),
    ];
  }

  /// Returns contents of the system section.
  List<Widget> _system(BuildContext context) {
    return [
      _headline(
        title: 'UnreadCounter',
        child: const SizedBox(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              UnreadCounter(1),
              UnreadCounter(10),
              UnreadCounter(90),
              UnreadCounter(100)
            ],
          ),
        ),
      ),
    ];
  }

  /// Returns contents of the navigation section.
  List<Widget> _navigation(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      _headlines(
        children: [
          (
            label: 'CustomAppBar',
            widget: SizedBox(
              height: 60,
              child: CustomAppBar(
                withTop: false,
                title: const Text('Title'),
                leading: [StyledBackButton(onPressed: () {})],
                actions: const [SizedBox(width: 60)],
              ),
            ),
          ),
          (
            label: 'CustomAppBar(leading, actions)',
            widget: SizedBox(
              height: 60,
              child: CustomAppBar(
                withTop: false,
                title: const Row(children: [Text('Title')]),
                padding: const EdgeInsets.only(left: 4, right: 20),
                leading: [StyledBackButton(onPressed: () {})],
                actions: [
                  AnimatedButton(
                    onPressed: () {},
                    child: const SvgImage.asset(
                      'assets/icons/chat_video_call.svg',
                      width: 27.71,
                      height: 19,
                    ),
                  ),
                  const SizedBox(width: 28),
                  AnimatedButton(
                    key: const Key('AudioCall'),
                    onPressed: () {},
                    child: const SvgImage.asset(
                      'assets/icons/chat_audio_call.svg',
                      width: 21,
                      height: 21.02,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      _headline(
        title: 'DockDecorator(Dock)',
        child: SizedBox(
          height: 85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DockDecorator(
                child: Dock(
                  items: List.generate(5, (i) => i),
                  itemWidth: 48,
                  onReorder: (buttons) {},
                  onDragStarted: (b) {},
                  onDragEnded: (_) {},
                  onLeave: (_) {},
                  onWillAccept: (d) => true,
                  itemBuilder: (i) => CallButtonWidget(
                    asset: 'more',
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      _headline(
        child: Launchpad(
          onWillAccept: (_) => true,
          children: List.generate(
            8,
            (i) => SizedBox(
              width: 100,
              height: 100,
              child: Center(
                child: CallButtonWidget(
                  asset: 'more',
                  hint: 'Hint',
                  expanded: true,
                  big: true,
                  onPressed: () {},
                ),
              ),
            ),
          ).toList(),
        ),
      ),
      _headline(
        title: 'CustomNavigationBar',
        child: ObxValue(
          (p) {
            return CustomNavigationBar(
              currentIndex: p.value,
              onTap: (i) => p.value = i,
              items: [
                const CustomNavigationBarItem(
                  child: SvgImage.asset(
                    'assets/icons/partner.svg',
                    width: 36,
                    height: 28,
                  ),
                ),
                const CustomNavigationBarItem(
                  child: SvgImage.asset(
                    'assets/icons/contacts.svg',
                    width: 32,
                    height: 32,
                  ),
                ),
                CustomNavigationBarItem(
                  child: Transform.translate(
                    offset: const Offset(0, 0.5),
                    child: const SvgImage.asset(
                      'assets/icons/chats.svg',
                      width: 39.26,
                      height: 33.5,
                    ),
                  ),
                ),
                const CustomNavigationBarItem(
                  child: AvatarWidget(radius: AvatarRadius.small),
                ),
              ],
            );
          },
          RxInt(0),
        ),
      ),
      _headline(child: const RaisedHand(true)),
      _headlines(
        children: [
          (
            label: 'AnimatedParticipant(loading)',
            widget: SizedBox(
              width: 300,
              height: 300,
              child: AnimatedParticipant(
                Participant(
                  CallMember.me(const CallMemberId(UserId('me'), null)),
                  user: DummyRxUser(),
                ),
              ),
            ),
          ),
          (
            label: 'AnimatedParticipant',
            widget: SizedBox(
              width: 300,
              height: 300,
              child: AnimatedParticipant(
                Participant(
                  CallMember.me(
                    const CallMemberId(UserId('me'), null),
                    isConnected: true,
                  ),
                  user: DummyRxUser(),
                ),
              ),
            ),
          ),
          (
            label: 'AnimatedParticipant(muted)',
            widget: SizedBox(
              width: 300,
              height: 300,
              child: AnimatedParticipant(
                Participant(
                  CallMember.me(
                    const CallMemberId(UserId('me'), null),
                    isConnected: true,
                  ),
                  user: DummyRxUser(),
                ),
                rounded: true,
                muted: true,
              ),
            ),
          ),
        ],
      ),
      _headline(
        color: style.colors.backgroundAuxiliaryLight,
        child: const CallTitle(
          UserId('me'),
          title: 'Title',
          state: 'State',
        ),
      ),
      _headline(
        child: ChatInfoCard(
          chat: DummyRxChat(),
          onTap: () {},
          duration: const Duration(seconds: 10),
          subtitle: 'Subtitle',
          trailing: 'Trailing',
        ),
      ),
      _headline(
        title: 'DropBox',
        child: const SizedBox(
          width: 200,
          height: 200,
          child: DropBox(),
        ),
      ),
      Builder(builder: (context) {
        GlobalKey key = GlobalKey();

        return _headline(
          title: 'ReorderableFit',
          child: SizedBox(
            key: key,
            width: 400,
            height: 400,
            child: ReorderableFit(
              children: List.generate(5, (i) => i),
              itemBuilder: (i) => Container(
                color: Colors.primaries[i],
                child: Center(child: Text('$i')),
              ),
              onOffset: () {
                if (key.globalPaintBounds != null) {
                  return Offset(
                    -key.globalPaintBounds!.left,
                    -key.globalPaintBounds!.top,
                  );
                }

                return Offset.zero;
              },
            ),
          ),
        );
      }),
      _headline(child: const BackgroundPreview(null)),
      _headline(
        child: BigAvatarWidget.myUser(
          null,
          onDelete: () {},
          onUpload: () {},
        ),
      ),
    ];
  }

  /// Returns contents of the sounds section.
  List<Widget> _sounds(BuildContext context) {
    final List<({String title, bool once})> sounds = [
      (title: 'incoming_call', once: false),
      (title: 'incoming_call_web', once: false),
      (title: 'outgoing_call', once: false),
      (title: 'reconnect', once: false),
      (title: 'message_sent', once: true),
      (title: 'notification', once: true),
      (title: 'pop', once: true),
    ];

    return [
      _headline(
        title: 'Sounds',
        child: BuilderWrap(
          sounds,
          (e) => PlayableAsset(e.title, once: e.once),
          dense: true,
        ),
      ),
    ];
  }
}

/// A dummy implementation of [RxUser].
///
/// Used to show [RxUser] related [Widget]s.
class DummyRxUser extends RxUser {
  @override
  Rx<RxChat?> get dialog => Rx(null);

  @override
  void listenUpdates() {}

  @override
  void stopUpdates() {}

  @override
  Rx<User> get user => Rx(
        User(
          const UserId('me'),
          UserNum('1234123412341234'),
          name: UserName('Participant'),
        ),
      );

  @override
  Rx<PreciseDateTime?> get lastSeen => Rx(PreciseDateTime.now());
}

/// A dummy implementation of [RxChat].
///
/// Used to show [RxChat] related [Widget]s.
class DummyRxChat extends RxChat {
  DummyRxChat() : chat = Rx(Chat(ChatId.local(const UserId('me'))));

  @override
  final Rx<Chat> chat;

  @override
  Future<void> addMessage(ChatMessageText text) async {}

  @override
  Future<void> around() async {}

  @override
  Rx<Avatar?> get avatar => Rx(null);

  @override
  UserCallCover? get callCover => null;

  @override
  int compareTo(RxChat other) => 0;

  @override
  Rx<ChatMessage?> get draft => Rx(null);

  @override
  Rx<ChatItem>? get firstUnread => null;

  @override
  RxBool get hasNext => RxBool(false);

  @override
  RxBool get hasPrevious => RxBool(false);

  @override
  ChatItem? get lastItem => null;

  @override
  UserId? get me => null;

  @override
  RxObsMap<UserId, RxUser> get members => RxObsMap();

  @override
  RxObsList<Rx<ChatItem>> get messages => RxObsList();

  @override
  Future<void> next() async {}

  @override
  RxBool get nextLoading => RxBool(false);

  @override
  Future<void> previous() async {}

  @override
  RxBool get previousLoading => RxBool(false);

  @override
  RxList<LastChatRead> get reads => RxList();

  @override
  Future<void> remove(ChatItemId itemId) async {}

  @override
  void setDraft({
    ChatMessageText? text,
    List<Attachment> attachments = const [],
    List<ChatItem> repliesTo = const [],
  }) {}

  @override
  Rx<RxStatus> get status => Rx(RxStatus.empty());

  @override
  RxString get title => RxString('Title');

  @override
  RxList<User> get typingUsers => RxList();

  @override
  RxInt get unreadCount => RxInt(0);

  @override
  Future<void> updateAttachments(ChatItem item) async {}

  @override
  Stream<void> get updates => const Stream.empty();
}
