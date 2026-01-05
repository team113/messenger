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

import '/domain/model/my_user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/util/message_popup.dart';
import 'animated_button.dart';
import 'animated_switcher.dart';
import 'svg/svg.dart';

/// Styled [ContactTile] representing the provided [RxUser] or [MyUser] as a
/// member of some [Chat] or [OngoingCall].
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    this.user,
    this.myUser,
    this.inCall,
    this.onTap,
    this.onKick,
    this.onCall,
  });

  /// [RxUser] this [MemberTile] is about.
  final RxUser? user;

  /// [MyUser] this [MemberTile] is about.
  final MyUser? myUser;

  /// Indicator whether a call button should be active or not.
  ///
  /// No call button is displayed, if `null` is specified.
  final bool? inCall;

  /// Callback, called when the [ContactTile] is tapped.
  final void Function()? onTap;

  /// Callback, called when the call button is pressed.
  final void Function()? onCall;

  /// Callback, called when the kick button is pressed.
  final Future<void> Function()? onKick;

  /// Indicates whether this [MemberTile] represents a [MyUser], meaning
  /// displaying appropriate labels.
  bool get _me => myUser != null;

  /// Returns text representing the status of this [myUser] or [user].
  String get _status => _me
      ? 'label_online'.l10n
      : user?.user.value.getStatus(user?.user.value.lastSeenAt) ?? '';

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ContactTile(
      user: user,
      myUser: myUser,
      dense: true,
      onTap: _me ? null : onTap,
      padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
      trailing: [
        if (inCall != null)
          SafeAnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Material(
              key: inCall == true
                  ? const Key('InCall')
                  : const Key('NotInCall'),
              color: inCall == true
                  ? onCall == null
                        ? style.colors.dangerHighlightLightest
                        : style.colors.danger
                  : onCall == null
                  ? style.colors.primaryHighlightLightest
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
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 50),
          child: Align(
            alignment: Alignment.centerRight,
            child: AnimatedButton(
              decorator: (child) =>
                  Padding(padding: const EdgeInsets.all(12), child: child),
              onPressed: _me
                  ? null
                  : () async {
                      final bool? result = await MessagePopup.alert(
                        'label_remove_member'.l10n,
                        description: [
                          TextSpan(text: 'alert_user_will_be_removed1'.l10n),
                          TextSpan(
                            text: user?.title(),
                            style: style.fonts.normal.regular.onBackground,
                          ),
                          TextSpan(text: 'alert_user_will_be_removed2'.l10n),
                        ],
                        button: (context) {
                          return MessagePopup.deleteButton(
                            context,
                            label: 'btn_delete'.l10n,
                            icon: SvgIcons.removeMemberWhite,
                          );
                        },
                      );

                      if (result == true) {
                        await onKick?.call();
                      }
                    },
              child: SvgIcon(
                _me ? SvgIcons.leaveGroup : SvgIcons.removeMember,
                key: _me
                    ? const Key('DeleteMeButton')
                    : Key('DeleteMemberButton'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
      ],
      subtitle: [
        if (_status.isNotEmpty)
          Text(_status.capitalized, style: style.fonts.small.regular.secondary),
      ],
    );
  }
}
