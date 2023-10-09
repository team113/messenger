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

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/avatar.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/chat_info.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/domain/model/file.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/model/user_call_cover.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/call/controller.dart';
import 'package:messenger/ui/page/call/widget/animated_participant.dart';
import 'package:messenger/ui/page/call/widget/call_button.dart';
import 'package:messenger/ui/page/call/widget/call_title.dart';
import 'package:messenger/ui/page/call/widget/chat_info_card.dart';
import 'package:messenger/ui/page/call/widget/dock.dart';
import 'package:messenger/ui/page/call/widget/dock_decorator.dart';
import 'package:messenger/ui/page/call/widget/drop_box.dart';
import 'package:messenger/ui/page/call/widget/launchpad.dart';
import 'package:messenger/ui/page/call/widget/raised_hand.dart';
import 'package:messenger/ui/page/call/widget/reorderable_fit.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/controller.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_forward.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/page/chat/widget/paid_notification.dart';
import 'package:messenger/ui/page/home/page/chat/widget/time_label.dart';
import 'package:messenger/ui/page/home/page/chat/widget/unread_label.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/background_preview.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/download_button.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/login.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/name.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/status.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/switch_field.dart';
import 'package:messenger/ui/page/home/page/user/widget/blocklist_record.dart';
import 'package:messenger/ui/page/home/page/user/widget/presence.dart';
import 'package:messenger/ui/page/home/page/user/widget/status.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/recent_chat.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/unread_counter.dart';
import 'package:messenger/ui/page/home/widget/animated_typing.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/big_avatar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/chat_tile.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/page/home/widget/direct_link.dart';
import 'package:messenger/ui/page/home/widget/navigation_bar.dart';
import 'package:messenger/ui/page/home/widget/rectangle_button.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
import 'package:messenger/ui/page/home/widget/shadowed_rounded_button.dart';
import 'package:messenger/ui/page/home/widget/sharable.dart';
import 'package:messenger/ui/page/home/widget/unblock_button.dart';
import 'package:messenger/ui/page/home/widget/wallet.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/page/login/widget/sign_button.dart';
import 'package:messenger/ui/page/style/widget/builder_wrap.dart';
import 'package:messenger/ui/page/work/widget/interactive_logo.dart';
import 'package:messenger/ui/page/work/widget/vacancy_button.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/phone_field.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/selected_dot.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/obs/rxlist.dart';
import 'package:messenger/util/obs/rxmap.dart';
import 'package:messenger/util/platform_utils.dart';

import 'widget/cat.dart';
import 'widget/expandable_block.dart';
import 'widget/playable_asset.dart';

// TODO:
// - ReactiveLoginField
// - ReactiveLinkField
// - BigAvatarWidget
// - etc...

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
    final List<(String, bool)> sounds = [
      ('incoming_call', false),
      ('incoming_web_call', false),
      ('outgoing_call', false),
      ('reconnect', false),
      ('message_sent', true),
      ('notification', true),
      ('pop', true),
    ];

    return ListView(
      controller: _scrollController,
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const SizedBox(height: CustomAppBar.height),
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
        Block(
          headline: 'Sounds',
          children: [
            BuilderWrap(
              sounds,
              (e) => PlayableAsset(e.$1, once: e.$2),
              dense: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _downloadButton(String asset, {String? prefix}) {
    final style = Theme.of(router.context!).style;

    return SelectionContainer.disabled(
      child: WidgetButton(
        onPressed: () async {
          final file = await PlatformUtils.saveTo(
            '${Config.origin}/assets/assets/images$prefix/$asset',
          );
          if (file != null) {
            MessagePopup.success('$asset downloaded');
          }
        },
        child: Text(
          'Download',
          style: style.fonts.labelSmallPrimary,
        ),
      ),
    );
  }

  Widget _headline({
    String? title,
    required Widget child,
    Widget? subtitle,
    Color? color,
    Color? headlineColor,
    bool top = true,
    bool bottom = true,
  }) {
    return Block(
      color: color,
      headline: title ?? child.runtimeType.toString(),
      headlineColor: headlineColor,
      margin: top ? null : 4,
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

  Widget _headlines({
    Color? color,
    required List<(String, Widget)> children,
  }) {
    final style = Theme.of(context).style;

    return Block(
      padding: EdgeInsets.zero,
      color: color,
      headline: '',
      children: [
        ...children.mapIndexed((i, e) {
          return [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                e.$1,
                style: style.fonts.headlineSmall.copyWith(
                  color: style.colors.secondaryHighlightDarkest,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SelectionContainer.disabled(child: e.$2),
            ),
            if (i != children.length - 1) const SizedBox(height: 32),
          ];
        }).flattened,
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds the images [Column].
  List<Widget> _images(BuildContext context) {
    // final style = Theme.of(context).style;

    return [
      _headline(
        top: false,
        subtitle: _downloadButton('head0000.svg', prefix: 'logo'),
        child: const InteractiveLogo(),
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

  /// Builds the animation [Column].
  List<Widget> _animations(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      _headline(
        title: 'SpinKitDoubleBounce',
        child: SizedBox(
          child: SpinKitDoubleBounce(
            color: style.colors.secondaryHighlightDark,
            size: 100 / 1.5,
            duration: const Duration(milliseconds: 4500),
          ),
        ),
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
            'CustomProgressIndicator',
            const SizedBox(child: Center(child: CustomProgressIndicator()))
          ),
          (
            'CustomProgressIndicator.big',
            const SizedBox(
              child: Center(child: CustomProgressIndicator.big()),
            )
          ),
          (
            'CustomProgressIndicator.primary',
            SizedBox(child: Center(child: CustomProgressIndicator.primary()))
          ),
        ],
      ),
    ];
  }

  /// Builds the animation [Column].
  List<Widget> _avatars(BuildContext context) {
    // final style = Theme.of(context).style;

    (String, Widget) avatars(String title, double radius) {
      return (
        'AvatarWidget(radius: ${radius.toStringAsFixed(0)})',
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AvatarWidget(title: title, radius: radius),
            AvatarWidget(
              radius: radius,
              child: Image.memory(base64Decode(catImage), fit: BoxFit.cover),
            ),
          ],
        )
      );
    }

    return [
      _headlines(
        children: [
          avatars('01', 100),
          avatars('02', 32),
          avatars('03', 30),
          avatars('04', 20),
          avatars('05', 17),
          avatars('06', 16),
          avatars('07', 13),
          avatars('08', 10),
          avatars('09', 8),
        ],
      ),
    ];
  }

  /// Builds the animation [Column].
  List<Widget> _fields(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      _headlines(
        children: [
          (
            'ReactiveTextField',
            ReactiveTextField(
              state: TextFieldState(approvable: true),
              hint: 'Hint',
              label: 'Label',
            ),
          ),
          (
            'ReactiveTextField(error)',
            ReactiveTextField(
              state: TextFieldState(text: 'Text', error: 'Error text'),
              hint: 'Hint',
              label: 'Label',
            ),
          ),
          (
            'ReactiveTextField(subtitle)',
            ReactiveTextField(
              key: const Key('LoginField'),
              state: TextFieldState(text: 'Text'),
              onSuffixPressed: () {},
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: const SvgImage.asset(
                    'assets/icons/copy.svg',
                    height: 15,
                  ),
                ),
              ),
              label: 'Label',
              hint: 'Hint',
              subtitle: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Subtitle with: '.l10n,
                      style: style.fonts.labelMediumSecondary,
                    ),
                    TextSpan(
                      text: 'clickable.',
                      style: style.fonts.labelMediumPrimary,
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            )
          ),
          (
            'ReactiveTextField(obscure)',
            ObxValue(
              (b) {
                return ReactiveTextField(
                  state: TextFieldState(text: 'Text'),
                  label: 'Obscured text'.l10n,
                  obscure: b.value,
                  onSuffixPressed: b.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/visible_${b.value ? 'off' : 'on'}.svg',
                    width: 17.07,
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
        child: ReactivePhoneField(state: PhoneFieldState(), label: 'Label'),
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
                    style: style.fonts.bodyLarge,
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
          style: style.fonts.titleMedium,
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

  /// Builds the animation [Column].
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
            'MenuButton',
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
          ),
          (
            'MenuButton(inverted: true)',
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
            'OutlinedRoundedButton(title)',
            OutlinedRoundedButton(
              title: const Text('Title'),
              onPressed: () {},
            ),
          ),
          (
            'OutlinedRoundedButton(subtitle)',
            OutlinedRoundedButton(
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
          ('SignButton', SignButton(onPressed: () {}, text: 'Label')),
          (
            'SignButton(asset)',
            SignButton(
              text: 'E-mail',
              asset: 'email',
              assetWidth: 21.93,
              assetHeight: 22.5,
              onPressed: () {},
            ),
          ),
        ],
      ),
      _headlines(
        children: [
          (
            'StyledCupertinoButton',
            StyledCupertinoButton(onPressed: () {}, label: 'Clickable text')
          ),
          (
            'StyledCupertinoButton.primary',
            StyledCupertinoButton(
              onPressed: () {},
              label: 'Clickable text',
              style: style.fonts.labelLargePrimary,
            ),
          ),
        ],
      ),
      _headlines(
        children: [
          (
            'RectangleButton',
            RectangleButton(onPressed: () {}, label: 'Label'),
          ),
          (
            'RectangleButton(selected: true)',
            RectangleButton(
              onPressed: () {},
              label: 'Label',
              selected: true,
            ),
          ),
          (
            'RectangleButton.radio',
            RectangleButton(
              onPressed: () {},
              label: 'Label',
              radio: true,
            ),
          ),
          (
            'RectangleButton.radio(selected: true)',
            RectangleButton(
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
                'assets/icons/chats6.svg',
                width: 39.26,
                height: 33.5,
              ),
            ),
            const SizedBox(width: 32),
            AnimatedButton(
              onPressed: () {},
              child: const SvgImage.asset(
                'assets/icons/chat_video_call.svg',
                height: 17,
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
            SizedBox(
              width: 60,
              height: 60,
              child: CallButtonWidget(
                color: style.colors.onSecondaryOpacity50,
                onPressed: () {},
                withBlur: true,
                assetWidth: 22,
                asset: 'fullscreen_enter_white',
              ),
            ),
            const SizedBox(width: 32),
            SizedBox(
              width: 100,
              height: 82,
              child: CallButtonWidget(
                onPressed: () {},
                hint: 'Hint'.l10n,
                asset: 'screen_share_on'.l10n,
                hinted: true,
                expanded: true,
              ),
            ),
            const SizedBox(width: 32),
            SizedBox.square(
              dimension: CallController.buttonSize,
              child: CallButtonWidget(
                hint: 'Hint'.l10n,
                asset: 'screen_share_on'.l10n,
                hinted: true,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
      _headlines(
        children: [
          (
            'DownloadButton.windows',
            const DownloadButton(
              asset: 'google',
              width: 20.33,
              height: 22.02,
              title: 'Google Play',
              left: 3,
              link: '',
            ),
          ),
          (
            'DownloadButton.macos',
            const DownloadButton(
              asset: 'apple',
              width: 21.07,
              height: 27,
              title: 'macOS',
              link: '',
            ),
          ),
          (
            'DownloadButton.linux',
            const DownloadButton(
              asset: 'linux',
              width: 20.57,
              height: 24,
              title: 'Linux',
              link: '',
            ),
          ),
          (
            'DownloadButton.appStore',
            const DownloadButton(
              asset: 'app_store',
              width: 23,
              height: 23,
              title: 'App Store',
              link: '',
            ),
          ),
          (
            'DownloadButton.googlePlay',
            const DownloadButton(
              asset: 'google',
              width: 20.33,
              height: 22.02,
              title: 'Google Play',
              left: 3,
              link: '',
            ),
          ),
          (
            'DownloadButton.android',
            const DownloadButton(
              asset: 'android',
              width: 20.99,
              height: 25,
              title: 'Android',
              link: '',
            ),
          ),
        ],
      ),
      _headline(child: StyledBackButton(onPressed: () {})),
      _headlines(
        children: [
          (
            'FloatingActionButton(arrow_upward)',
            FloatingActionButton.small(
              heroTag: '1',
              onPressed: () {},
              child: const Icon(Icons.arrow_upward),
            ),
          ),
          (
            'FloatingActionButton(arrow_downward)',
            FloatingActionButton.small(
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
                'VacancyWorkButton(${e.name})',
                VacancyWorkButton(e, onPressed: (_) {}),
              ),
            )
            .toList(),
      ),
    ];
  }

  /// Builds the animation [Column].
  List<Widget> _switches(BuildContext context) {
    // final style = Theme.of(context).style;

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

  /// Builds the animation [Column].
  List<Widget> _tiles(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      _headlines(
        children: [
          (
            'ContextMenu(desktop)',
            const ContextMenu(
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
            'ContextMenu(mobile)',
            const ContextMenu(
              enlarge: true,
              actions: [
                ContextMenuButton(label: 'Action 1', enlarge: true),
                ContextMenuButton(label: 'Action 2', enlarge: true),
                ContextMenuButton(label: 'Action 3', enlarge: true),
                ContextMenuButton(label: 'Action 4', enlarge: true),
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
            'RecentChatTile',
            RecentChatTile(DummyRxChat(), onTap: () {}),
          ),
          (
            'RecentChatTile(selected)',
            RecentChatTile(
              DummyRxChat(),
              onTap: () {},
              selected: true,
            ),
          ),
          (
            'RecentChatTile(trailing)',
            RecentChatTile(
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
            'ChatTile',
            ChatTile(chat: DummyRxChat(), onTap: () {}),
          ),
          (
            'ChatTile(selected)',
            ChatTile(
              chat: DummyRxChat(),
              onTap: () {},
              selected: true,
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
            'ContactTile',
            ContactTile(
              myUser: MyUser(
                id: const UserId('123'),
                num: UserNum('1234123412341234'),
                emails: MyUserEmails(confirmed: []),
                phones: MyUserPhones(confirmed: []),
                presenceIndex: 0,
                online: true,
              ),
              onTap: () {},
            ),
          ),
          (
            'ContactTile(selected)',
            ContactTile(
              myUser: MyUser(
                id: const UserId('123'),
                num: UserNum('1234123412341234'),
                emails: MyUserEmails(confirmed: []),
                phones: MyUserPhones(confirmed: []),
                presenceIndex: 0,
                online: true,
              ),
              onTap: () {},
              selected: true,
            ),
          ),
          (
            'ContactTile(trailing)',
            ContactTile(
              myUser: MyUser(
                id: const UserId('123'),
                num: UserNum('1234123412341234'),
                emails: MyUserEmails(confirmed: []),
                phones: MyUserPhones(confirmed: []),
                presenceIndex: 0,
                online: true,
              ),
              onTap: () {},
              selected: false,
              trailing: const [SelectedDot(selected: false, size: 20)],
            ),
          ),
        ],
      ),
    ];
  }

  /// Builds the animation [Column].
  List<Widget> _system(BuildContext context) {
    // final style = Theme.of(context).style;

    return [
      const Block(
        headline: 'UnreadCounter',
        children: [
          SizedBox(
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
        ],
      ),
    ];
  }

  /// Builds the animation [Column].
  List<Widget> _chat(BuildContext context) {
    final style = Theme.of(context).style;

    ChatItem message({
      bool fromMe = true,
      SendingStatus status = SendingStatus.sent,
      String? text = 'Lorem ipsum',
      List<String> attachments = const [],
      List<ChatItemQuote> repliesTo = const [],
    }) {
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
              NativeFile(
                name: 'Image',
                size: 2,
                bytes: base64Decode(catImage),
              ),
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
      Block(
        color: style.colors.onBackgroundOpacity7,
        headline: 'TimeLabelWidget',
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
      Block(
        color: style.colors.onBackgroundOpacity7,
        headline: 'UnreadLabel',
        children: const [UnreadLabel(123)],
      ),
      ExpandableBlock(
        color: style.colors.onBackgroundOpacity7,
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
        headline: 'ChatItemWidget',
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
          chatItem(
            message(
              status: SendingStatus.sent,
              text: '?donate=1234',
              fromMe: true,
            ),
            read: true,
            kind: ChatKind.dialog,
          ),
          const SizedBox(height: 8),
          chatItem(
            message(
              status: SendingStatus.sent,
              text: '?donate=1234',
              fromMe: false,
            ),
            read: true,
            kind: ChatKind.dialog,
          ),
          const SizedBox(height: 8),
          chatItem(
            message(
              status: SendingStatus.sent,
              text: 'Comment?donate=1234',
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
              text: 'Comment?donate=1234',
              fromMe: false,
              attachments: ['image'],
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
      Block(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
        color: style.colors.onBackgroundOpacity7,
        headline: 'ChatForwardWidget',
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
    ];
  }

  /// Builds the animation [Column].
  List<Widget> _navigation(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      _headlines(
        children: [
          (
            'CustomAppBar',
            SizedBox(
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
            'CustomAppBar(leading, actions)',
            SizedBox(
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
                      height: 17,
                    ),
                  ),
                  const SizedBox(width: 28),
                  AnimatedButton(
                    key: const Key('AudioCall'),
                    onPressed: () {},
                    child: const SvgImage.asset(
                      'assets/icons/chat_audio_call.svg',
                      height: 19,
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
        child: DockDecorator(
          child: Dock(
            items: List.generate(5, (i) => i),
            itemWidth: 48,
            isDraggable: (_) => true,
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
                const CustomNavigationBarItem(child: WalletWidget()),
                const CustomNavigationBarItem(
                  child: SvgImage.asset(
                    'assets/icons/partner16.svg',
                    width: 36,
                    height: 28,
                  ),
                ),
                const CustomNavigationBarItem(
                  child: SvgImage.asset(
                    'assets/icons/publics13.svg',
                    width: 32,
                    height: 31,
                  ),
                ),
                CustomNavigationBarItem(
                  child: Transform.translate(
                    offset: const Offset(0, 0.5),
                    child: const SvgImage.asset(
                      'assets/icons/chats6.svg',
                      key: Key('Unmuted'),
                      width: 39.26,
                      height: 33.5,
                    ),
                  ),
                ),
                const CustomNavigationBarItem(child: AvatarWidget(radius: 16)),
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
            'AnimatedParticipant',
            SizedBox(
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
            'AnimatedParticipant',
            SizedBox(
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
            'AnimatedParticipant',
            SizedBox(
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
        child: const SizedBox(
          width: 200,
          height: 200,
          child: DropBox(),
        ),
      ),
      _headline(
        child: SizedBox(
          width: 400,
          height: 400,
          child: ReorderableFit(
            children: List.generate(5, (i) => i),
            itemBuilder: (i) => Container(
              color: Colors.primaries[i],
              child: Center(child: Text('$i')),
            ),
          ),
        ),
      ),
      _headline(child: const PaidNotification()),
      _headline(child: const BackgroundPreview(null)),

      _headline(
        child: BigAvatarWidget.myUser(
          null,
          onDelete: () {},
          onUpload: () {},
        ),
      ),

      // _headline(),
    ];
  }
}

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
}

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
}

class _HoveredBuilder extends StatefulWidget {
  const _HoveredBuilder(this.builder);

  final Widget Function(bool) builder;

  @override
  State<_HoveredBuilder> createState() => _HoveredBuilderState();
}

class _HoveredBuilderState extends State<_HoveredBuilder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(_hovered),
    );
  }
}
