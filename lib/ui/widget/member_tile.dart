// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/ui/page/home/tab/chats/widget/recent_chat.dart';
import 'package:messenger/ui/page/home/widget/chat_tile.dart';

import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/util/message_popup.dart';
import 'animated_button.dart';
import 'animated_switcher.dart';
import 'svg/svg.dart';

/// Styled [ContactTile] representing the provided [RxUser] as a member of some
/// [Chat] or [OngoingCall].
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.user,
    this.inCall,
    this.onTap,
    this.canLeave = false,
    this.onKick,
    this.onCall,
  });

  /// [RxUser] this [MemberTile] is about.
  final RxUser user;

  /// Indicator whether a call button should be active or not.
  ///
  /// No call button is displayed, if `null` is specified.
  final bool? inCall;

  /// Callback, called when the [ContactTile] is tapped.
  final void Function()? onTap;

  /// Callback, called when the call button is pressed.
  final void Function()? onCall;

  /// Indicator whether the kick button should be a leave button.
  final bool canLeave;

  /// Callback, called when the kick or leave button is pressed.
  final Future<void> Function()? onKick;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final trailing = [
      const SizedBox(width: 12),
      if (inCall != null) ...[
        // const SizedBox(width: 8),
        SafeAnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Material(
            key: Key(inCall == true ? 'InCall' : 'NotInCall'),
            color: inCall == true
                ? onCall == null
                    ? style.colors.primaryHighlightLightest
                    : style.colors.danger
                : style.colors.primary,
            type: MaterialType.circle,
            child: InkWell(
              onTap: onCall,
              borderRadius: BorderRadius.circular(60),
              child: SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: inCall == true
                      ? const SvgIcon(SvgIcons.callEndSmall)
                      : const SvgIcon(SvgIcons.callStartSmall),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: canLeave ? 12 : 16),
      ],
      AnimatedButton(
        enabled: !canLeave,
        onPressed: canLeave
            ? null
            : () async {
                final bool? result = await MessagePopup.alert(
                  canLeave
                      ? 'label_leave_group'.l10n
                      : 'label_remove_member'.l10n,
                  description: [
                    if (canLeave)
                      TextSpan(text: 'alert_you_will_leave_group'.l10n)
                    else ...[
                      TextSpan(text: 'alert_user_will_be_removed1'.l10n),
                      TextSpan(
                        text: user.user.value.name?.val ??
                            user.user.value.num.toString(),
                        style: style.fonts.normal.regular.onBackground,
                      ),
                      TextSpan(text: 'alert_user_will_be_removed2'.l10n),
                    ],
                  ],
                );

                if (result == true) {
                  await onKick?.call();
                }
              },
        child: canLeave
            ? Text(
                'label_you'.l10n,
                style: style.fonts.normal.regular.secondary,
              )
            : const SvgIcon(SvgIcons.delete, key: Key('DeleteMemberButton')),
      ),
      const SizedBox(width: 6),
    ];

    if (user.dialog.value != null && !canLeave) {
      return Obx(() {
        final muted = user.dialog.value?.chat.value.muted != null;
        final bool paid = !canLeave &&
            (user.user.value.name?.val.toLowerCase().contains('alex2') ==
                    true ||
                user.user.value.name?.val.toLowerCase().contains('kirey') ==
                    true);

        return ChatTile(
          chat: user.dialog.value,
          onTap: onTap,
          trailing: trailing,
          monolog: false,
          height: 58,
          avatarBuilder: (a) =>
              Padding(padding: const EdgeInsets.all(4), child: a),
          status: [
            if (paid) ...[
              const SizedBox(width: 8),
              // const SvgIcon(SvgIcons.premium),
              // const SvgIcon(SvgIcons.emerald),
              // const SvgIcon(SvgIcons.sun),
              const SvgIcon(SvgIcons.faceSmile),
            ],
            if (muted) ...[
              const SizedBox(width: 10),
              const SvgIcon(SvgIcons.muted),
            ],
          ],
        );
      });

      // return RecentChatTile(
      //   user.dialog.value!,
      //   onTap: onTap,
      //   trailing: trailing,
      //   appendTrailing: true,
      //   monolog: false,
      // );
    }

    return ContactTile(
      user: user,
      onTap: canLeave ? null : onTap,
      height: 58,
      avatarBuilder: (a) => Padding(padding: const EdgeInsets.all(4), child: a),
      // subtitle: [
      //   const SizedBox(height: 8),
      //   Text(
      //     'label_no_messages'.l10n,
      //     maxLines: 1,
      //     style: style.fonts.normal.regular.secondary,
      //   ),
      // ],
      trailing: trailing,
      // trailing: [
      //   Column(
      //     children: [
      //       const SizedBox(height: 13),
      //       ...trailing,
      //       const Spacer(),
      //     ],
      //   ),
      // ],
    );
  }
}
