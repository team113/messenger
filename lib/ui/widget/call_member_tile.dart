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

import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';

/// Styled [ContactTile] which is a visual representation of the [RxUser] with
/// interaction buttons.
class CallMemberTile extends StatelessWidget {
  const CallMemberTile({
    super.key,
    required this.user,
    required this.isMe,
    required this.isCall,
    required this.inCall,
    this.color,
    this.onTap,
    this.onTrailingPressed,
    this.onCirclePressed,
  });

  /// [RxUser] to display.
  final RxUser user;

  /// Indicator whether the contact is the current user.
  final bool isMe;

  /// Indicator whether the call is happening.
  final bool isCall;

  /// Indicator whether the contact is in the call.
  final bool inCall;

  /// [Color] of the circle button.
  final Color? color;

  /// Callback, called when the [ContactTile] is tapped.
  final void Function()? onTap;

  /// Callback, called when the circle button is tapped.
  final void Function()? onCirclePressed;

  /// Callback, called when the trailing button is tapped.
  final Future<void> Function()? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return ContactTile(
      user: user,
      dense: true,
      onTap: onTap,
      darken: 0.05,
      trailing: [
        if (isCall)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Material(
                key: Key(inCall ? 'inCall' : 'NotInCall'),
                color: color,
                type: MaterialType.circle,
                child: InkWell(
                  onTap: onCirclePressed,
                  borderRadius: BorderRadius.circular(60),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(
                      child: inCall
                          ? SvgImage.asset('assets/icons/call_end.svg')
                          : SvgImage.asset(
                              'assets/icons/audio_call_start.svg',
                              width: 13,
                              height: 13,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        WidgetButton(
          onPressed: () async {
            final bool? result = await MessagePopup.alert(
              isMe ? 'label_leave_group'.l10n : 'label_remove_member'.l10n,
              description: [
                if (isMe)
                  TextSpan(text: 'alert_you_will_leave_group'.l10n)
                else ...[
                  TextSpan(text: 'alert_user_will_be_removed1'.l10n),
                  TextSpan(
                    text: user.user.value.name?.val ?? user.user.value.num.val,
                    style: fonts.labelLarge,
                  ),
                  TextSpan(text: 'alert_user_will_be_removed2'.l10n),
                ],
              ],
            );

            if (result == true) {
              await onTrailingPressed?.call();
            }
          },
          child: isMe
              ? Text(
                  'btn_leave'.l10n,
                  style: fonts.labelLarge!.copyWith(
                    color: style.colors.primary,
                  ),
                )
              : SvgImage.asset('assets/icons/delete.svg', height: 14 * 1.5),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
