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

import '/domain/model/my_user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/text_field.dart';

/// [Widget] which returns a [Switch] toggling [MyUser.muted].
class SwitchMute extends StatelessWidget {
  const SwitchMute(this.myUser, this.isMuting, this.toggleMute, {super.key});

  /// `User` of an application being currently signed-in.
  final MyUser? myUser;

  /// Indicator whether there's an ongoing [toggleMute] happening.
  final bool isMuting;

  /// Toggles [MyUser.muted] status.
  final void Function(bool enabled) toggleMute;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        IgnorePointer(
          child: ReactiveTextField(
            state: TextFieldState(
              text: (myUser?.muted == null ? 'label_enabled' : 'label_disabled')
                  .l10n,
              editable: false,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Transform.scale(
              scale: 0.7,
              transformHitTests: false,
              child: Theme(
                data: ThemeData(
                  platform: TargetPlatform.macOS,
                ),
                child: Switch.adaptive(
                  key: const Key('MuteMyUserSwitch'),
                  activeColor: style.colors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: myUser?.muted == null,
                  onChanged: isMuting ? null : toggleMute,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
