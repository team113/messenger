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
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/call/widget/call_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
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
          _animations(context),
          // _avatars(context),
          // _fields(context),
          _buttons(context),
          _switches(context),
          _containment(context),
          _system(context),
          _navigation(context),
          _chat(context),
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

  Widget _headline({String? title, required Widget child, Widget? subtitle}) {
    return Block(
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
          child: OutlinedRoundedButton(
            title: const Text('Title'),
            color: Colors.black.withOpacity(0.04),
            onPressed: () {},
          ),
        ),
        _headline(
          title: 'OutlinedRoundedButton(subtitle)',
          child: OutlinedRoundedButton(
            subtitle: const Text('Subtitle'),
            color: Colors.black.withOpacity(0.04),
            onPressed: () {},
          ),
        ),
        _headline(
          title: 'PrimaryButton',
          child: PrimaryButton(onPressed: () {}, title: 'PrimaryButton'),
        ),
        _headline(
          child: WidgetButton(onPressed: () {}, child: const Text('Label')),
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
          child: StyledCupertinoButton(onPressed: () {}, label: 'Label'),
        ),
        _headline(
          title: 'StyledCupertinoButton.primary',
          child: StyledCupertinoButton(
            onPressed: () {},
            label: 'Label',
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
          child: AnimatedButton(
            onPressed: () {},
            child: const SvgImage.asset(
              'assets/icons/chat.svg',
              width: 20.12,
              height: 21.62,
            ),
          ),
        ),
        _headline(
          child: CallButtonWidget(
            hint: 'Label\nabove button',
            asset: 'add_user_small',
            hinted: true,
            onPressed: () {},
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
            onPressed: () {},
            child: const Icon(Icons.arrow_upward),
          ),
        ),
        _headline(
          title: 'FloatingActionButton(arrow_downward)',
          child: FloatingActionButton.small(
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
