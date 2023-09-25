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
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/chat_info.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/domain/model/file.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/call/controller.dart';
import 'package:messenger/ui/page/call/widget/call_button.dart';
import 'package:messenger/ui/page/call/widget/round_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_forward.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/page/chat/widget/unread_label.dart';
import 'package:messenger/ui/page/home/page/chat/widget/video/widget/expand_button.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/download_button.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/switch_field.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/unread_counter.dart';
import 'package:messenger/ui/page/home/widget/animated_typing.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/rectangle_button.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
import 'package:messenger/ui/page/home/widget/shadowed_rounded_button.dart';
import 'package:messenger/ui/page/home/widget/unblock_button.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/page/login/widget/sign_button.dart';
import 'package:messenger/ui/page/style/widget/builder_wrap.dart';
import 'package:messenger/ui/page/work/widget/interactive_logo.dart';
import 'package:messenger/ui/page/work/widget/vacancy_button.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';

import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/expandable_block.dart';
import 'widget/playable_asset.dart';

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
          _chat(context),
          _animations(context),
          // _avatars(context),
          // _fields(context),
          _buttons(context),
          _switches(context),
          _containment(context),
          _system(context),
          _navigation(context),

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
      ),
    );
  }

  List<Widget> _element(
    BuildContext context, {
    String? title,
    List<Widget> children = const [],
  }) {
    final style = Theme.of(context).style;

    return [
      if (title != null) ...[
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Container(
                height: 0.5,
                width: double.infinity,
                color: Colors.black.withOpacity(0.15),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: style.fonts.labelSmallSecondary.copyWith(
                color: Colors.black.withOpacity(0.15),
              ),
              // style: style.fonts.headlineMedium,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 0.5,
                width: double.infinity,
                color: Colors.black.withOpacity(0.15),
              ),
            ),
          ],
        ),
        // Align(
        //   alignment: Alignment.centerLeft,
        //   child: Text(
        //     title,
        //     textAlign: TextAlign.center,
        //     style: style.fonts.labelSmallSecondary,
        //     // style: style.fonts.headlineMedium,
        //   ),
        // ),
        const SizedBox(height: 8),
      ],
      ...children.map((e) => SelectionContainer.disabled(child: e)),
      const SizedBox(height: 48),
    ];
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
  }) {
    return Block(
      color: color,
      headline: title ?? child.runtimeType.toString(),
      children: [
        const SizedBox(height: 16),
        SelectionContainer.disabled(child: child),
        const SizedBox(height: 8),
        if (subtitle != null) SelectionContainer.disabled(child: subtitle),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Builds the images [Column].
  Widget _images(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        _headline(
          child: const InteractiveLogo(),
          subtitle: _downloadButton('head0000.svg', prefix: 'logo'),
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
      ],
    );

    return Block(
      title: 'Images',
      children: [
        ..._element(
          context,
          title: 'InteractiveLogo',
          children: [
            const InteractiveLogo(),
            const SizedBox(height: 8),
            SelectionContainer.disabled(
              child: WidgetButton(
                onPressed: () async {
                  const String asset = 'head0000.svg';
                  final file = await PlatformUtils.saveTo(
                    '${Config.origin}/assets/assets/images/logo/$asset',
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
            ),
          ],
        ),
        ..._element(
          context,
          title: 'background_light.svg',
          children: [
            const SvgImage.asset(
              'assets/images/background_light.svg',
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 8),
            SelectionContainer.disabled(
              child: WidgetButton(
                onPressed: () async {
                  const String asset = 'background_light.svg';
                  final file = await PlatformUtils.saveTo(
                    '${Config.origin}/assets/assets/images/$asset',
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
            ),
          ],
        ),
        ..._element(
          context,
          title: 'background_dark.svg',
          children: [
            const SvgImage.asset(
              'assets/images/background_dark.svg',
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 8),
            SelectionContainer.disabled(
              child: WidgetButton(
                onPressed: () async {
                  const String asset = 'background_dark.svg';
                  final file = await PlatformUtils.saveTo(
                    '${Config.origin}/assets/assets/images/$asset',
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
        _headline(
          title: 'CustomProgressIndicator',
          child: const SizedBox(
            child: Center(child: CustomProgressIndicator()),
          ),
        ),
        _headline(
          title: 'CustomProgressIndicator.big',
          child: const SizedBox(
            child: Center(child: CustomProgressIndicator.big()),
          ),
        ),
        _headline(
          title: 'CustomProgressIndicator.primary',
          child: SizedBox(
            child: Center(child: CustomProgressIndicator.primary()),
          ),
        ),
      ],
    );

    return Block(
      title: 'Animations',
      children: [
        ..._element(
          context,
          title: 'SpinKitDoubleBounce',
          children: [
            SizedBox(
              child: SpinKitDoubleBounce(
                color: style.colors.secondaryHighlightDark,
                size: 100 / 1.5,
                duration: const Duration(milliseconds: 4500),
              ),
            ),
          ],
        ),
        ..._element(
          context,
          title: 'AnimatedTyping',
          children: const [
            SizedBox(
              height: 32,
              child: Center(child: AnimatedTyping()),
            )
          ],
        ),
        ..._element(
          context,
          title: 'CustomProgressIndicator',
          children: [
            const SizedBox(child: Center(child: CustomProgressIndicator())),
          ],
        ),
        ..._element(
          context,
          title: 'CustomProgressIndicator.big',
          children: [
            const SizedBox(child: Center(child: CustomProgressIndicator.big())),
          ],
        ),
        ..._element(
          context,
          title: 'CustomProgressIndicator.primary',
          children: [
            SizedBox(child: Center(child: CustomProgressIndicator.primary()))
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
        _headline(
          child: MenuButton(
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
        _headline(
          title: 'MenuButton(inverted: true)',
          child: MenuButton(
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
        _headline(
          title: 'OutlinedRoundedButton(title)',
          color: Colors.black.withOpacity(0.04),
          child: OutlinedRoundedButton(
            title: const Text('Title'),
            onPressed: () {},
          ),
        ),
        _headline(
          title: 'OutlinedRoundedButton(subtitle)',
          color: Colors.black.withOpacity(0.04),
          child: OutlinedRoundedButton(
            subtitle: const Text('Subtitle'),
            onPressed: () {},
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
        _headline(
          child: SignButton(onPressed: () {}, text: 'Label'),
        ),
        _headline(
          title: 'SignButton(asset)',
          child: SignButton(
            text: 'E-mail',
            asset: 'email',
            assetWidth: 21.93,
            assetHeight: 22.5,
            onPressed: () {},
          ),
        ),
        _headline(
          child: StyledCupertinoButton(
            onPressed: () {},
            label: 'Clickable text',
          ),
        ),
        _headline(
          title: 'StyledCupertinoButton.primary',
          child: StyledCupertinoButton(
            onPressed: () {},
            label: 'Clickable text',
            style: style.fonts.labelLargePrimary,
          ),
        ),
        _headline(
          child: RectangleButton(onPressed: () {}, label: 'Label'),
        ),
        _headline(
          title: 'RectangleButton(selected: true)',
          child: RectangleButton(
            onPressed: () {},
            label: 'Label',
            selected: true,
          ),
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
          color: Colors.black.withOpacity(0.04),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: RoundFloatingButton(
                  color: style.colors.onSecondaryOpacity50,
                  onPressed: () {},
                  withBlur: true,
                  assetWidth: 22,
                  asset: 'fullscreen_enter_white',
                ),
              ),
              const SizedBox(width: 32),
              SizedBox.square(
                dimension: CallController.buttonSize,
                child: CallButtonWidget(
                  hint: 'btn_call_screen_on'.l10n,
                  asset: 'screen_share_on'.l10n,
                  hinted: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        _headline(
          title: 'DownloadButton.windows',
          child: const DownloadButton(
            asset: 'windows5',
            width: 23.93,
            height: 24,
            title: 'Windows',
            link: '',
          ),
        ),
        _headline(
          title: 'DownloadButton.macos',
          child: const DownloadButton(
            asset: 'apple7',
            width: 21.07,
            height: 27,
            title: 'macOS',
            link: '',
          ),
        ),
        _headline(
          title: 'DownloadButton.linux',
          child: const DownloadButton(
            asset: 'linux4',
            width: 20.57,
            height: 24,
            title: 'Linux',
            link: '',
          ),
        ),
        _headline(
          title: 'DownloadButton.appStore',
          child: const DownloadButton(
            asset: 'app_store',
            width: 23,
            height: 23,
            title: 'App Store',
            link: '',
          ),
        ),
        _headline(
          title: 'DownloadButton.googlePlay',
          child: const DownloadButton(
            asset: 'google',
            width: 20.33,
            height: 22.02,
            title: 'Google Play',
            left: 3,
            link: '',
          ),
        ),
        _headline(
          title: 'DownloadButton.android',
          child: const DownloadButton(
            asset: 'android3',
            width: 20.99,
            height: 25,
            title: 'Android',
            link: '',
          ),
        ),
        _headline(
          child: StyledBackButton(canPop: true, onPressed: () {}),
        ),
        _headline(
          title: 'FloatingActionButton(arrow_upward)',
          child: FloatingActionButton.small(
            heroTag: '1',
            onPressed: () {},
            child: const Icon(Icons.arrow_upward),
          ),
        ),
        _headline(
          title: 'FloatingActionButton(arrow_downward)',
          child: FloatingActionButton.small(
            heroTag: '2',
            onPressed: () {},
            child: const Icon(Icons.arrow_downward),
          ),
        ),
        _headline(child: UnblockButton(() {})),
        _headline(
          child: ShadowedRoundedButton(
            onPressed: () {},
            child: const Text('Label'),
          ),
        ),
        ...WorkTab.values
            .map(
              (e) => [
                _headline(
                  title: 'VacancyWorkButton(${e.name})',
                  child: VacancyWorkButton(e),
                ),
              ],
            )
            .flattened,
      ],
    );

    return Column(
      children: [
        Block(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._element(
              context,
              title: 'MenuButton',
              children: [
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
              ],
            ),
            ..._element(
              context,
              title: 'MenuButton(inverted: true)',
              children: [
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
            ..._element(
              context,
              title: 'OutlinedRoundedButton(title: \'\')',
              children: [
                OutlinedRoundedButton(
                  title: const Text('Title'),
                  color: Colors.black.withOpacity(0.04),
                  onPressed: () {},
                ),
              ],
            ),
            ..._element(
              context,
              title: 'OutlinedRoundedButton(subtitle: \'\')',
              children: [
                OutlinedRoundedButton(
                  subtitle: const Text('Subtitle'),
                  color: Colors.black.withOpacity(0.04),
                  onPressed: () {},
                ),
              ],
            ),
            ..._element(
              context,
              title: 'PrimaryButton',
              children: [
                PrimaryButton(
                  onPressed: () {},
                  title: 'PrimaryButton',
                ),
              ],
            ),
            // ..._element(
            //   context,
            //   title: 'WidgetButton',
            //   children: [
            //     WidgetButton(onPressed: () {}, child: const Text('Label')),
            //   ],
            // ),
            ..._element(
              context,
              title: 'SignButton',
              children: [
                SignButton(onPressed: () {}, text: 'Label'),
              ],
            ),
            ..._element(
              context,
              title: 'SignButton(asset: \'\')',
              children: [
                SignButton(
                  text: 'E-mail',
                  asset: 'email',
                  assetWidth: 21.93,
                  assetHeight: 22.5,
                  onPressed: () {},
                ),
              ],
            ),
            ..._element(
              context,
              title: 'StyledCupertinoButton',
              children: [
                StyledCupertinoButton(onPressed: () {}, label: 'Label'),
              ],
            ),
            ..._element(
              context,
              title: 'StyledCupertinoButton.primary',
              children: [
                StyledCupertinoButton(
                  onPressed: () {},
                  label: 'Label',
                  style: style.fonts.labelLargePrimary,
                ),
              ],
            ),
            ..._element(
              context,
              title: 'RectangleButton',
              children: [
                RectangleButton(onPressed: () {}, label: 'Label'),
              ],
            ),
            ..._element(
              context,
              title: 'RectangleButton(selected: true)',
              children: [
                RectangleButton(
                  onPressed: () {},
                  label: 'Label',
                  selected: true,
                ),
              ],
            ),
            // ..._element(
            //   context,
            //   title: 'AnimatedButton',
            //   children: [
            //     AnimatedButton(
            //       onPressed: () {},
            //       child: const SvgImage.asset(
            //         'assets/icons/chat.svg',
            //         width: 20.12,
            //         height: 21.62,
            //       ),
            //     ),
            //   ],
            // ),
            ..._element(
              context,
              title: 'CallButtonWidget',
              children: [
                CallButtonWidget(
                  hint: 'Label\nabove button',
                  asset: 'add_user_small',
                  hinted: true,
                  onPressed: () {},
                )
              ],
            ),
            ..._element(
              context,
              title: 'DownloadButton.windows',
              children: const [
                DownloadButton(
                  asset: 'windows5',
                  width: 23.93,
                  height: 24,
                  title: 'Windows',
                  link: '',
                )
              ],
            ),
            ..._element(
              context,
              title: 'DownloadButton.macos',
              children: const [
                DownloadButton(
                  asset: 'apple7',
                  width: 21.07,
                  height: 27,
                  title: 'macOS',
                  link: '',
                )
              ],
            ),
            ..._element(
              context,
              title: 'DownloadButton.linux',
              children: const [
                DownloadButton(
                  asset: 'linux4',
                  width: 20.57,
                  height: 24,
                  title: 'Linux',
                  link: '',
                )
              ],
            ),
            ..._element(
              context,
              title: 'DownloadButton.appStore',
              children: const [
                DownloadButton(
                  asset: 'app_store',
                  width: 23,
                  height: 23,
                  title: 'App Store',
                  link: '',
                )
              ],
            ),
            ..._element(
              context,
              title: 'DownloadButton.googlePlay',
              children: const [
                DownloadButton(
                  asset: 'google',
                  width: 20.33,
                  height: 22.02,
                  title: 'Google Play',
                  left: 3,
                  link: '',
                )
              ],
            ),
            ..._element(
              context,
              title: 'DownloadButton.android',
              children: const [
                DownloadButton(
                  asset: 'android3',
                  width: 20.99,
                  height: 25,
                  title: 'Android',
                  link: '',
                ),
              ],
            ),
            ..._element(
              context,
              title: 'StyledBackButton',
              children: [StyledBackButton(canPop: true, onPressed: () {})],
            ),
            ..._element(
              context,
              title: 'FloatingActionButton',
              children: [
                FloatingActionButton.small(
                  onPressed: () {},
                  child: const Icon(Icons.arrow_upward),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: () {},
                  child: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
            ...WorkTab.values
                .map(
                  (e) => [
                    ..._element(
                      context,
                      title: 'VacancyWorkButton(${e.name})',
                      children: [VacancyWorkButton(e)],
                    ),
                  ],
                )
                .flattened,
            ..._element(
              context,
              title: 'UnblockButton',
              children: [UnblockButton(() {})],
            ),
            ..._element(
              context,
              title: 'ShadowedRoundedButton',
              children: [
                ShadowedRoundedButton(
                  onPressed: () {},
                  child: const Text('Label'),
                )
              ],
            ),
          ],
        ),
        Block(
          headline: 'ShadowedRoundedButton',
          children: [
            const SizedBox(height: 16),
            ShadowedRoundedButton(
              onPressed: () {},
              child: const Text('Label'),
            ),
            const SizedBox(height: 16),
          ],
        ),
        _headline(
          child: WidgetButton(onPressed: () {}, child: const Text('Label')),
        ),
        _headline(
          child: AnimatedButton(
            onPressed: () {},
            child: const SvgImage.asset(
              'assets/icons/chat.svg',
              width: 20.12,
              height: 21.62,
            ),
          ),
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
                bytes: base64Decode(
                  '/9j/4AAQSkZJRgABAQEAYABgAAD//gA+Q1JFQVRPUjogZ2QtanBlZyB2MS4wICh1c2luZyBJSkcgSlBFRyB2NjIpLCBkZWZhdWx0IHF1YWxpdHkK/9sAQwAIBgYHBgUIBwcHCQkICgwUDQwLCwwZEhMPFB0aHx4dGhwcICQuJyAiLCMcHCg3KSwwMTQ0NB8nOT04MjwuMzQy/9sAQwEJCQkMCwwYDQ0YMiEcITIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIy/8AAEQgCWAMgAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/aAAwDAQACEQMRAD8A9OWCArES3DdW81Rk4zt29V54yeO9RyRwKXBZ1YfdUbZB0/vAj+VdF9ktv+feL/vgUfZLb/n3i/74FZXNLGG1taecwSYsoZlCl1UtjGDu6AYJ+u33wNLSAFtpQBgCUgfMG7DuOtWvslt/z7xf98CpEjSJdsaKgznCjFDZI6iiipKCiiigAooooAKKKKACiiigAooooAKKKM0AFFGaTNAC0UlFAC0UlFAC0UlFAC5pKKKAClzSUUAFFFFABRnNFFABRRRSAKKSigBaKSigYtJmiigBc0UlFAC0UlFAC0ZpKKAFzSZoooAXNJRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAlFLSUAFFGaKACiiigAopKXpQAUUUUAFFGaTNAC0ZpKKAFzSUUUAFFFFAC5pKKKACiikoAWikzRQAtFJRQAUUUnegBetFJS0CCikzS5oAKM0maKAFopKM0ATUUlFMBaKSigApaSigBaM0lFABRRSUALmikooAWikopALRSUUALRmkooAKKKKAClpKKACiiigApaSigYtJmiigBaSiigAooooAKKKKACiiigAozRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFIAooooAKKKKACiiigAooooAKSiigAoopM0ALRSUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUlAC5opKKACiiigAooooAKKKKACiikzQAtFFFABRiiigBMUUtJigAopcUmKACiiigRLRRRVAJS0UUAFFGKKACkzS0YoASiiikAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKQBRRRTAKKKKQBRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUlLRQAlFLRQAlJTqSgBKKWigYlFFFAgooooAKKKKACiiigAooooAKSlooAMUlLRQAlFLSUAFFFFABRRRQAUUUUAFFFFABRRRQAUUlFABRRRQAUUUUCJaKKMVQBRRS4oASilxRQAlFLikxQAUUUUAFFFFACYopcUYpAJRS4oxQAlFLSY5oAKKWigBKMUtFACUUtFABikxS0UAJRS0UAFJ0paMc0DCiiigAooooAKKKKACiiigBKKWigBKKXHNFACUUuKKAEopcUlAC0UUlABRRilxQAlFLSUAFFLRQAlFLRQAlFLiikAlFGKXFACUUuKMUAJRRRQAUUUUAFJilooASilooASilooASkxTsUlACYopaKAEopaQCgAopcUYoASiiigAooooAKSlooATFFLRQAUUUUAJiilopgJRS4pMUAFFFFAgooooASjFLRQBLRRRTAKKKKACiiigAooooAKSlpKACiijFABRRijFIAooxS0AJRS4oxQAlFApaAEoxS0UAJRS0UAJRQDmloASilooASilpMUAFFLRQMSiiloASijFFABRRR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',
                ),
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

    return Column(
      children: [
        const Block(headline: 'UnreadLabel', children: [UnreadLabel(123)]),
        ExpandableBlock(
          // color: style.colors.background,
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
          // color: style.colors.background,
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
      ],
    );

    // return Column(
    //   children: [
    //     const Block(headline: 'UnreadLabel', children: [UnreadLabel(123)]),
    //     Block(
    //       color: style.colors.background,
    //       headline: 'ChatItemWidget',
    //       children: [
    //         const SizedBox(height: 32),
    //         // Monolog.
    //         chatItem(
    //           message(),
    //           kind: ChatKind.monolog,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(),
    //           kind: ChatKind.monolog,
    //           read: true,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(
    //             attachments: [
    //               LocalAttachment(
    //                 NativeFile(
    //                   name: 'Image',
    //                   size: 2,
    //                   bytes: base64Decode(
    //                     'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    //                   ),
    //                 ),
    //                 status: SendingStatus.sent,
    //               )
    //             ],
    //           ),
    //           kind: ChatKind.monolog,
    //           read: true,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(
    //             repliesTo: [
    //               ChatMessageQuote(
    //                 author: const UserId('me'),
    //                 at: PreciseDateTime.now(),
    //                 text: const ChatMessageText('Replies!'),
    //               )
    //             ],
    //           ),
    //           kind: ChatKind.monolog,
    //           read: true,
    //         ),
    //         const SizedBox(height: 32),

    //         // Dialog.
    //         chatItem(
    //           message(
    //             status: SendingStatus.sending,
    //             text: 'Received message',
    //             fromMe: false,
    //           ),
    //           kind: ChatKind.dialog,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.sending, text: 'Sending...'),
    //           kind: ChatKind.dialog,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.error, text: 'Error ocurred'),
    //           kind: ChatKind.dialog,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.sent, text: 'Sent message'),
    //           kind: ChatKind.dialog,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.sent, text: 'Delivered message'),
    //           kind: ChatKind.dialog,
    //           delivered: true,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.sent, text: 'Read message'),
    //           kind: ChatKind.dialog,
    //           read: true,
    //         ),

    //         const SizedBox(height: 32),

    //         // Group.
    //         chatItem(
    //           message(
    //             status: SendingStatus.sending,
    //             text: 'Received message',
    //             fromMe: false,
    //           ),
    //           kind: ChatKind.group,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.sending),
    //           kind: ChatKind.group,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.error),
    //           kind: ChatKind.group,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.sent),
    //           kind: ChatKind.group,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.sent),
    //           kind: ChatKind.group,
    //           delivered: true,
    //         ),
    //         const SizedBox(height: 8),
    //         chatItem(
    //           message(status: SendingStatus.sent),
    //           kind: ChatKind.group,
    //           read: true,
    //         ),

    //         const SizedBox(height: 32),
    //       ],
    //     ),
    //   ],
    // );
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
