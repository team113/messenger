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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/animated_logo.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/unread_counter.dart';
import 'package:messenger/ui/page/home/widget/animated_typing.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
import 'package:messenger/ui/page/style/widget/builder_wrap.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
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
          const SizedBox(height: 16),
          const Header('Widgets'),
          const SubHeader('Images'),
          _images(context),
          const SubHeader('Animations'),
          _animations(context),
          const SubHeader('Sounds'),
          BuilderWrap(
            sounds,
            (e) => PlayableAsset(e.$1, subtitle: e.$2, once: e.$3),
          ),
          const SubHeader('Avatars'),
          _avatars(context),
          const Divider(),
          const SubHeader('Text fields'),
          _fields(context),
          const Divider(),
          const SubHeader('Buttons'),
          _buttons(context),
          const Divider(),
          const SubHeader('Switchers'),
          _switches(context),
          const Divider(),
          const SubHeader('Containment'),
          _containment(context),
          const Divider(),
          const SubHeader('System messages'),
          _system(context),
          const Divider(),
          const SubHeader('Navigation'),
          _navigation(context),
          const Divider(),
        ],
      ),
    );
  }

  /// Builds the images [Column].
  Widget _images(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubtitleContainer(
            inverted: widget.inverted,
            width: 900,
            child: SvgImage.asset(
              'assets/images/background_${widget.inverted ? 'dark' : 'light'}.svg',
              fit: BoxFit.fitWidth,
            ),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: widget.inverted,
            height: 300,
            width: 200,
            child: const SvgImage.asset('assets/images/logo/logo0000.svg'),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: widget.inverted,
            height: 150,
            width: 150,
            child: const SvgImage.asset('assets/images/logo/head0000.svg'),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: widget.inverted,
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
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubtitleContainer(
            inverted: widget.inverted,
            width: 210,
            height: 300,
            subtitle: 'AnimatedLogo',
            child: AnimatedLogo(
              onInit: (a) async {
                final StateMachineController machine =
                    StateMachineController(a.stateMachines.first);
                a.addController(machine);
              },
            ),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: widget.inverted,
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
            inverted: widget.inverted,
            subtitle: 'AnimatedTyping',
            width: 86,
            height: 86,
            child: const Center(child: AnimatedTyping()),
          ),
          const SizedBox(height: 16),
          SubtitleContainer(
            inverted: widget.inverted,
            subtitle: 'CustomProgressIndicator',
            child: const CustomProgressIndicator(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _avatars(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Column(
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _buttons(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _switches(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _containment(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _system(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _navigation(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: widget.dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }
}
