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

import '../common/dummy_chat.dart';
import '../common/dummy_user.dart';
import '../widget/headline.dart';
import '../widget/headlines.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/controller.dart';
import '/ui/page/call/widget/animated_participant.dart';
import '/ui/page/call/widget/call_button.dart';
import '/ui/page/call/widget/call_title.dart';
import '/ui/page/call/widget/chat_info_card.dart';
import '/ui/page/call/widget/dock.dart';
import '/ui/page/call/widget/dock_decorator.dart';
import '/ui/page/call/widget/drop_box.dart';
import '/ui/page/call/widget/launchpad.dart';
import '/ui/page/call/widget/raised_hand.dart';
import '/ui/page/call/widget/reorderable_fit.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/widget/background_preview.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';

/// [Routes.style] navigation section.
class NavigationSection {
  /// Returns the [Widget]s of this [NavigationSection].
  static List<Widget> build(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      Headlines(
        children: [
          (
            headline: 'CustomAppBar',
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
            headline: 'CustomAppBar(leading, actions)',
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
      Headline(
        headline: 'DockDecorator(Dock)',
        child: SizedBox(
          height: 85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DockDecorator(
                child: Dock(
                  items: List.generate(5, (i) => i),
                  itemWidth: 48,
                  dragDelta: 0,
                  onReorder: (buttons) {},
                  onDragStarted: (b) {},
                  onDragEnded: (_) {},
                  onLeave: (_) {},
                  onWillAccept: (d) => true,
                  itemBuilder: (i) => CallButtonWidget(
                    asset: SvgIcons.callMore,
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Headline(
        child: Launchpad(
          onWillAccept: (_) => true,
          children: List.generate(
            8,
            (i) => SizedBox(
              width: 100,
              height: 100,
              child: Center(
                child: CallButtonWidget(
                  asset: SvgIcons.callMore,
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
      Headline(
        headline: 'CustomNavigationBar',
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
      const Headline(child: RaisedHand(true)),
      Headlines(
        children: [
          (
            headline: 'AnimatedParticipant(loading)',
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
            headline: 'AnimatedParticipant',
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
            headline: 'AnimatedParticipant(muted)',
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
      Headline(
        color: style.colors.backgroundAuxiliaryLight,
        child: const CallTitle(
          UserId('me'),
          title: 'Title',
          state: 'State',
        ),
      ),
      Headline(
        child: ChatInfoCard(
          chat: DummyRxChat(),
          onTap: () {},
          duration: const Duration(seconds: 10),
          subtitle: 'Subtitle',
          trailing: 'Trailing',
        ),
      ),
      const Headline(
        headline: 'DropBox',
        child: SizedBox(
          width: 200,
          height: 200,
          child: DropBox(),
        ),
      ),
      Builder(builder: (context) {
        GlobalKey key = GlobalKey();

        return Headline(
          headline: 'ReorderableFit',
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
      const Headline(child: BackgroundPreview(null)),
      Headline(
        child: BigAvatarWidget.myUser(
          null,
          onDelete: () {},
          onUpload: () {},
        ),
      ),
    ];
  }
}
