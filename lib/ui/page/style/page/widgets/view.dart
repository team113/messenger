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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/animated_logo.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/page/chat/widget/unread_label.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/switch_field.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/unread_counter.dart';
import 'package:messenger/ui/page/home/widget/animated_typing.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/page/login/widget/sign_button.dart';
import 'package:messenger/ui/page/style/widget/builder_wrap.dart';
import 'package:messenger/ui/page/work/widget/interactive_logo.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:rive/rive.dart';

import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/playable_asset.dart';
import 'widget/subtitle_container.dart';

/// Widgets view of the [Routes.style] page.
class WidgetsView extends StatefulWidget {
  const WidgetsView({
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this view should be compact, meaning minimal [Padding]s.
  final bool dense;

  @override
  State<WidgetsView> createState() => _WidgetsViewState();
}

class _WidgetsViewState extends State<WidgetsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final List<(String, String, bool)> sounds = [
      ('chinese', 'Incoming call', false),
      ('chinese-web', 'Web incoming call', false),
      ('ringing', 'Outgoing call', false),
      ('reconnect', 'Call reconnection', false),
      ('message_sent', 'Sended message', true),
      ('notification', 'Notification sound', true),
      ('pop', 'Pop sound', true),
    ];

    return SafeScrollbar(
      controller: _scrollController,
      margin: const EdgeInsets.only(top: CustomAppBar.height - 10),
      child: ScrollableColumn(
        controller: _scrollController,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16 + 5),
          // const Header('Widgets'),
          // const SubHeader('Images'),
          _images(context),
          _animations(context),
          Block(
            title: 'Sounds',
            children: [
              BuilderWrap(
                sounds,
                (e) => PlayableAsset(e.$1, subtitle: e.$2, once: e.$3),
                dense: true,
              ),
            ],
          ),
          _avatars(context),
          _fields(context),
          _buttons(context),
          _switches(context),
          _containment(context),
          _system(context),
          _navigation(context),
          _chat(context),
        ],
      ),
    );
  }

  /// Builds the images [Column].
  Widget _images(BuildContext context) {
    return Column(
      children: [
        const Block(title: 'InteractiveLogo', children: [InteractiveLogo()]),
        Block(
          title: 'background_light.svg',
          padding: const EdgeInsets.only(top: 16),
          children: [
            SubtitleContainer(
              inverted: widget.inverted,
              width: 400,
              height: 300,
              child: const SvgImage.asset(
                'assets/images/background_light.svg',
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the animation [Column].
  Widget _animations(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        Block(
          title: 'logo.riv',
          children: [
            SubtitleContainer(
              width: 210,
              height: 300,
              inverted: widget.inverted,
              child: RiveAnimation.asset(
                'assets/images/logo/logo.riv',
                onInit: (a) => a.addController(
                  StateMachineController.fromArtboard(
                      a, a.stateMachines.first.name)!,
                ),
              ),
            ),
          ],
        ),
        Block(
          title: 'SpinKitDoubleBounce',
          children: [
            SizedBox(
              child: SpinKitDoubleBounce(
                color: style.colors.secondaryHighlightDark,
                size: 100 / 1.5,
                duration: const Duration(milliseconds: 4500),
              ),
            )
          ],
        ),
        const Block(
          title: 'AnimatedTyping',
          children: [
            SizedBox(
              height: 32,
              child: Center(child: AnimatedTyping()),
            )
          ],
        ),
        const Block(
          title: 'CustomProgressIndicator',
          children: [
            SizedBox(
              child: Center(child: CustomProgressIndicator()),
            )
          ],
        ),
      ],
    );
  }

  /// Builds the animation [Column].
  Widget _avatars(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Block(
        title: 'Avatars',
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _fields(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Block(
        title: 'Fields',
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _buttons(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        Block(
          title: 'MenuButton',
          children: [
            MenuButton(
              icon: Icons.person,
              title: 'Title',
              subtitle: 'Subtitle',
              onPressed: () {},
            ),
            const SizedBox(height: 8),
            MenuButton(
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
            const SizedBox(height: 8),
            MenuButton(
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
          ],
        ),
        Block(
          title: 'OutlinedRoundedButton',
          children: [
            OutlinedRoundedButton(
              title: const Text('Title'),
              color: Colors.black.withOpacity(0.04),
              onPressed: () {},
            ),
            const SizedBox(height: 8),
            OutlinedRoundedButton(
              subtitle: const Text('Subtitle'),
              color: Colors.black.withOpacity(0.04),
              onPressed: () {},
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              onPressed: () {},
              title: 'PrimaryButton',
            ),
          ],
        ),
        Block(
          title: 'WidgetButton',
          children: [
            WidgetButton(onPressed: () {}, child: const Text('Label')),
          ],
        ),
        Block(
          title: 'SignButton',
          children: [
            SignButton(onPressed: () {}, text: 'Label'),
            const SizedBox(height: 8),
            SignButton(
              text: 'E-mail',
              asset: 'email',
              assetWidth: 21.93,
              assetHeight: 22.5,
              onPressed: () {},
            ),
          ],
        ),
        Block(
          title: 'StyledCupertinoButton',
          children: [
            StyledCupertinoButton(onPressed: () {}, label: 'Label'),
            const SizedBox(height: 8),
            StyledCupertinoButton(
              onPressed: () {},
              label: 'Label',
              style: style.fonts.labelMediumPrimary,
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the animation [Column].
  Widget _switches(BuildContext context) {
    // final style = Theme.of(context).style;

    return Column(
      children: [
        Block(
          title: 'SwitchField',
          children: [
            ObxValue(
              (value) {
                return SwitchField(
                  text: 'Label',
                  value: value.value,
                  onChanged: (b) => value.value = b,
                );
              },
              false.obs,
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the animation [Column].
  Widget _containment(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Block(
        title: 'Containment',
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _system(BuildContext context) {
    // final style = Theme.of(context).style;

    return Column(
      children: [
        Block(
          title: 'UnreadCounter',
          children: [
            SizedBox(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ...List.generate(10, (i) => UnreadCounter(i + 1)),
                  ...List.generate(10, (i) => UnreadCounter((i + 1) * 10)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the animation [Column].
  Widget _chat(BuildContext context) {
    // final style = Theme.of(context).style;

    ChatItem message({
      bool fromMe = true,
      SendingStatus status = SendingStatus.sent,
      String text = 'Lorem ipsum',
    }) {
      return ChatMessage(
        ChatItemId.local(),
        ChatId.local(const UserId('me')),
        User(UserId(fromMe ? 'me' : '0'), UserNum('1234123412341234')),
        PreciseDateTime.now(),
        text: ChatMessageText(text),
        status: status,
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

    return Column(
      children: [
        const Block(title: 'UnreadLabel', children: [UnreadLabel(123)]),
        Block(
          title: 'ChatItemWidget',
          children: [
            // Monolog.
            chatItem(
              message(),
              kind: ChatKind.monolog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(),
              kind: ChatKind.monolog,
              read: true,
            ),
            const SizedBox(height: 32),

            // Dialog.
            chatItem(
              message(status: SendingStatus.sending, text: 'Sending...'),
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.error, text: 'Error ocurred'),
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

            const SizedBox(height: 32),

            // Group.
            chatItem(
              message(status: SendingStatus.sending),
              kind: ChatKind.group,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.error),
              kind: ChatKind.group,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.sent),
              kind: ChatKind.group,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.sent),
              kind: ChatKind.group,
              delivered: true,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.sent),
              kind: ChatKind.group,
              read: true,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ],
    );
  }

  /// Builds the animation [Column].
  Widget _navigation(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Block(
        title: 'Navigation',
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }
}
