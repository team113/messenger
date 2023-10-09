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
import 'package:get/get.dart';
import 'package:messenger/config.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/unread_counter.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';

/// Widgets view of the [Routes.style] page.
class IconsView extends StatefulWidget {
  const IconsView({super.key, this.inverted = false});

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  @override
  State<IconsView> createState() => _WidgetsViewState();
}

class _WidgetsViewState extends State<IconsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: IconsController(),
      builder: (IconsController c) {
        return Stack(
          children: [
            ListView(
              controller: _scrollController,
              children: [
                Block(
                  color: style.colors.primaryDark,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _downloadableIcon(
                          context,
                          c,
                          icon: 'iOS.png',
                          archive: 'iOS',
                        ),
                        _downloadableIcon(
                          context,
                          c,
                          icon: 'macOS.png',
                          archive: 'macOS',
                        ),
                        _downloadableIcon(
                          context,
                          c,
                          icon: 'windows.ico',
                          archive: 'windows',
                        ),
                        _downloadableIcon(
                          context,
                          c,
                          icon: 'android.png',
                          archive: 'android',
                        ),
                        _downloadableIcon(
                          context,
                          c,
                          icon: 'web.png',
                          archive: 'web',
                          mini: true,
                        ),
                        _downloadableIcon(
                          context,
                          c,
                          icon: 'alert.png',
                          archive: 'alert',
                          mini: true,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _appBar(
                  context,
                  [
                    AnimatedButton(
                      onPressed: () =>
                          c.icon.value = const IconDetails('chat.svg'),
                      child: Transform.translate(
                        offset: const Offset(0, 1),
                        child: const SvgImage.asset(
                          'assets/icons/chat.svg',
                          width: 20.12,
                          height: 21.62,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    AnimatedButton(
                      onPressed: () => c.icon.value =
                          const IconDetails('chat_video_call.svg'),
                      child: const SvgImage.asset(
                        'assets/icons/chat_video_call.svg',
                        height: 17,
                      ),
                    ),
                    const SizedBox(width: 24),
                    AnimatedButton(
                      onPressed: () => c.icon.value =
                          const IconDetails('chat_audio_call.svg'),
                      child: const SvgImage.asset(
                        'assets/icons/chat_audio_call.svg',
                        height: 19,
                      ),
                    ),
                  ],
                ),
                _appBar(
                  context,
                  [
                    AnimatedButton(
                      onPressed: () => c.icon.value = const IconDetails(
                        'call_end.svg',
                        invert: true,
                      ),
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: style.colors.dangerColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SvgImage.asset(
                            'assets/icons/call_end.svg',
                            width: 20.55,
                            height: 8.53,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    AnimatedButton(
                      onPressed: () => c.icon.value = const IconDetails(
                        'call_start.svg',
                        invert: true,
                      ),
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: style.colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SvgImage.asset(
                            'assets/icons/call_start.svg',
                            width: 15,
                            height: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _appBar(
                  context,
                  [
                    AnimatedButton(
                      onPressed: () =>
                          c.icon.value = const IconDetails('search.svg'),
                      child: const SvgImage.asset(
                        'assets/icons/search.svg',
                        width: 17.77,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(() {
                    if (c.icon.value == null) {
                      return const SizedBox();
                    }

                    final String? asset = c.icon.value?.asset;
                    final String? download =
                        c.icon.value?.download ?? c.icon.value?.asset;
                    final bool invert = c.icon.value?.invert == true;

                    return Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            invert ? style.colors.primaryDark : style.cardColor,
                        borderRadius: style.cardRadius,
                        boxShadow: [
                          CustomBoxShadow(
                            blurRadius: 8,
                            color: style.colors.onBackgroundOpacity13,
                            blurStyle: BlurStyle.outer,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: asset?.endsWith('.svg') == true
                                ? SvgImage.asset(
                                    'assets/icons/$asset',
                                    width: 32,
                                    height: 32,
                                  )
                                : Image.asset(
                                    'assets/icons/$asset',
                                    width: 32,
                                    height: 32,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$asset',
                                style: invert
                                    ? style.fonts.labelLargeOnPrimary
                                    : style.fonts.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              SelectionContainer.disabled(
                                child: StyledCupertinoButton(
                                  label: 'Download',
                                  onPressed: () async {
                                    final file = await PlatformUtils.saveTo(
                                      '${Config.origin}/assets/assets/icons/$download',
                                    );

                                    if (file != null) {
                                      MessagePopup.success('$asset downloaded');
                                    }
                                  },
                                  style: style.fonts.labelMediumPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _appBar(
    BuildContext context,
    List<Widget> children, {
    List<Widget> leading = const [],
  }) {
    return Block(
      children: [
        SizedBox(
          height: CustomAppBar.height,
          child: CustomAppBar(
            leading: leading,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _downloadableIcon(
    BuildContext context,
    IconsController c, {
    required String icon,
    required String archive,
    bool mini = false,
  }) {
    return AnimatedButton(
      onPressed: () => c.icon.value = IconDetails(
        'application/$icon',
        invert: true,
        download: 'application/$archive.zip',
      ),
      child: Image.asset(
        'assets/icons/application/$icon',
        width: mini ? 32 : 64,
        height: mini ? 32 : 64,
      ),
    );
  }
}
