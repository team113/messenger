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

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';

class CallMemberTile extends StatelessWidget {
  const CallMemberTile({
    super.key,
    required this.user,
    required this.me,
    required this.inCall,
    required this.color,
    required this.onTap,
    required this.onPressed,
    required this.onTapContactTile,
    required this.isCallAndMe,
    required this.width,
    required this.height,
  });

  ///
  final double? width;

  ///
  final double? height;

  ///
  final RxUser user;

  ///
  final UserId? me;

  ///
  final bool inCall;

  ///
  final bool isCallAndMe;

  ///
  final Color color;

  final void Function()? onTapContactTile;

  ///
  final void Function()? onTap;

  ///
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return ContactTile(
      user: user,
      dense: true,
      onTap: onTapContactTile,
      darken: 0.05,
      trailing: [
        if (isCallAndMe)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Material(
                key: Key(inCall ? 'inCall' : 'NotInCall'),
                color: color,
                type: MaterialType.circle,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(60),
                  child: SizedBox(
                    width: 30,
                    height: 30,
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
              user.id == me
                  ? 'label_leave_group'.l10n
                  : 'label_remove_member'.l10n,
              description: [
                if (me == user.id)
                  TextSpan(text: 'alert_you_will_leave_group'.l10n)
                else ...[
                  TextSpan(text: 'alert_user_will_be_removed1'.l10n),
                  TextSpan(
                    text: user.user.value.name?.val ?? user.user.value.num.val,
                    style: TextStyle(color: style.colors.onBackground),
                  ),
                  TextSpan(text: 'alert_user_will_be_removed2'.l10n),
                ],
              ],
            );

            if (result == true) {
              await onPressed?.call();
            }
          },
          child: user.id == me
              ? Text(
                  'btn_leave'.l10n,
                  style: TextStyle(color: style.colors.primary, fontSize: 15),
                )
              : SvgImage.asset('assets/icons/delete.svg', height: 14 * 1.5),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
