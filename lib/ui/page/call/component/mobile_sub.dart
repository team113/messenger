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
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/themes.dart';
import '../../home/widget/avatar.dart';
import '../controller.dart';
import '../widget/animated_cliprrect.dart';
import '../widget/participant.dart';

/// Builds the [Participant] with a [AnimatedClipRRect].
class MobileBuilder extends StatelessWidget {
  const MobileBuilder(
    this.e,
    this.muted,
    this.animated,
    this.minimized, {
    super.key,
  });

  /// Separate call entity participating in a call.
  final Participant e;

  /// Mute switching.
  final bool muted;

  /// Animated switching.
  final bool animated;

  ///
  final RxBool minimized;

  @override
  Widget build(BuildContext context) {
    return AnimatedClipRRect(
      key: Key(e.member.id.toString()),
      borderRadius: animated ? BorderRadius.circular(10) : BorderRadius.zero,
      child: AnimatedContainer(
        duration: 200.milliseconds,
        decoration: BoxDecoration(
          color: animated ? const Color(0xFF132131) : const Color(0x00132131),
        ),
        width: animated ? MediaQuery.of(context).size.width - 20 : null,
        height: animated ? MediaQuery.of(context).size.height / 2 : null,
        child: StackWidget(e, muted, animated, minimized),
      ),
    );
  }
}

/// Сreating overlapping [Widget]'s of various functionality.
class StackWidget extends StatelessWidget {
  const StackWidget(
    this.e,
    this.muted,
    this.animated,
    this.minimized, {
    super.key,
  });

  /// Separate call entity participating in a call.
  final Participant e;

  /// Mute switching.
  final bool muted;

  /// Animated switching.
  final bool animated;

  ///
  final RxBool minimized;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ParticipantDecoratorWidget(),
        IgnorePointer(
          child: ParticipantWidget(
            e,
            offstageUntilDetermined: true,
          ),
        ),
        ParticipantOverlayWidget(
          e,
          muted: muted,
          hovered: animated,
          preferBackdrop: !minimized.value,
        ),
      ],
    );
  }
}

/// Displays a set of buttons in a row with a horizontal maximum width limit.
class MobileButtonsWidget extends StatelessWidget {
  const MobileButtonsWidget({
    super.key,
    required this.children,
  });

  /// [Widget]'s that should be placed in the [MobileButtonsWidget].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...children.map((e) => Expanded(child: e)).toList(),
        ],
      ),
    );
  }
}

/// Builds a tile representation of the [CallController.chat].
class MobileChatWidget extends StatelessWidget {
  const MobileChatWidget({
    super.key,
    required this.actualMembers,
    this.chat,
    required this.openAddMember,
    required this.duration,
    required this.me,
  });

  ///
  final Set<UserId> actualMembers;

  ///
  final RxChat? chat;

  ///
  final Future<void> Function(BuildContext context) openAddMember;

  ///
  final Rx<Duration> duration;

  ///
  final CallMember me;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Style style = Theme.of(context).extension<Style>()!;

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            color: Colors.transparent,
          ),
          child: Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius,
            color: const Color(0x794E5A78),
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: () => openAddMember(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                child: Row(
                  children: [
                    AvatarWidget.fromRxChat(chat, radius: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat?.title.value ?? 'dot'.l10n * 3,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                              Text(
                                duration.value.hhMmSs(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Row(
                              children: [
                                Text(
                                  chat?.members.values
                                          .firstWhereOrNull(
                                            (e) => e.id != me.id.userId,
                                          )
                                          ?.user
                                          .value
                                          .status
                                          ?.val ??
                                      'label_online'.l10n,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                                const Spacer(),
                                Text(
                                  'label_a_of_b'.l10nfmt({
                                    'a': '${actualMembers.length}',
                                    'b': '${chat?.members.length}',
                                  }),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// [Column] consisting of the [child] with the provided [description].
class Description extends StatelessWidget {
  final Widget child;
  final Widget description;
  const Description({
    Key? key,
    required this.child,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 6),
        DefaultTextStyle(
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          child: description,
        ),
      ],
    );
  }
}

/// Wraps the [child] widget passed to it and adds margins to the right and left.
class MobilePaddingWidget extends StatelessWidget {
  const MobilePaddingWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// [Widget] that should be placed in the [MobilePaddingWidget].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Center(child: child),
    );
  }
}

/// Combines all the stackable content into [Scaffold].
class MobileCallScaffoldWidget extends StatelessWidget {
  /// Stackable content.
  final List<Widget> content;

  /// List of [Widget] that make up the user interface.
  final List<Widget> ui;

  /// List of [Widget] which will be displayed on top of the main content
  /// on the screen.
  final List<Widget> overlay;

  const MobileCallScaffoldWidget(
    this.content,
    this.ui,
    this.overlay, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF444444),
      body: Stack(
        children: [
          ...content,
          const MouseRegion(
            opaque: false,
            cursor: SystemMouseCursors.basic,
          ),
          ...ui.map((e) => ClipRect(child: e)),
          ...overlay,
        ],
      ),
    );
  }
}
