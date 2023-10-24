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

import '/themes.dart';
import '/ui/page/auth/widget/animated_logo.dart';
import '/ui/page/home/tab/chats/widget/unread_counter.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import 'widget/playable_asset.dart';
import 'widget/subtitle_container.dart';

/// View of the [StyleTab.multimedia] page.
class MultimediaView extends StatelessWidget {
  const MultimediaView({
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this view should be compact, meaning minimal [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final List<(String, String, bool)> sounds = [
      ('incoming_call', 'Incoming call', false),
      ('incoming_web_call', 'Web incoming call', false),
      ('ringing', 'Outgoing call', false),
      ('reconnect', 'Call reconnection', false),
      ('message_sent', 'Sended message', true),
      ('notification', 'Notification sound', true),
      ('pop', 'Pop sound', true),
    ];

    return ScrollableColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Header('Multimedia'),
        const SubHeader('Images'),
        _images(context),
        const SubHeader('Animations'),
        _animations(context),
        const SubHeader('Sounds'),
        BuilderWrap(
          sounds,
          (e) => PlayableAsset(e.$1, subtitle: e.$2, once: e.$3),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds the images [Column].
  Widget _images(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubtitleContainer(
            inverted: inverted,
            width: 900,
            child: SvgImage.asset(
              'assets/images/background_${inverted ? 'dark' : 'light'}.svg',
              fit: BoxFit.fitWidth,
            ),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: inverted,
            height: 300,
            width: 200,
            child: const SvgImage.asset('assets/images/logo/logo0000.svg'),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: inverted,
            height: 150,
            width: 150,
            child: const SvgImage.asset('assets/images/logo/head_0.svg'),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: inverted,
            subtitle: 'UnreadCounter',
            width: 190,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(24, (i) => UnreadCounter(i + 1)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _animations(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubtitleContainer(
            inverted: inverted,
            width: 210,
            height: 300,
            subtitle: 'AnimatedLogo',
            child: const AnimatedLogo(),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: inverted,
            subtitle: 'SpinKitDoubleBounce',
            width: 128,
            height: 128,
            child: SpinKitDoubleBounce(
              color: style.colors.secondaryHighlightDark,
              size: 100 / 1.5,
              duration: const Duration(milliseconds: 4500),
            ),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: inverted,
            subtitle: 'AnimatedTyping',
            width: 86,
            height: 86,
            child: const Center(child: AnimatedTyping()),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: inverted,
            subtitle: 'CustomProgressIndicator',
            child: const CustomProgressIndicator(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
