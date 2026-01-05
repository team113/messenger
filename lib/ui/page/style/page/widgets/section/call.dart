// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import '/ui/page/call/widget/dock_decorator.dart';
import '/ui/page/call/widget/dock.dart';
import '/ui/page/call/widget/drop_box.dart';
import '/ui/page/call/widget/launchpad.dart';
import '/ui/page/call/widget/raised_hand.dart';
import '/ui/page/call/widget/reorderable_fit.dart';
import '/ui/widget/svg/svg.dart';
import '/util/global_key.dart';

/// [Routes.style] call section.
class CallSection {
  /// Returns the [Widget]s of this [CallSection].
  static List<Widget> build(BuildContext context) {
    final style = Theme.of(context).style;

    return [
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
                  itemWidth: CallController.buttonSize,
                  delayed: false,
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
        background: style.colors.backgroundAuxiliaryLight,
        child: const CallTitle(title: 'Title', state: 'State'),
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
        child: SizedBox(width: 200, height: 200, child: DropBox()),
      ),
      Builder(
        builder: (context) {
          final GlobalKey key = GlobalKey();

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
        },
      ),
    ];
  }
}
