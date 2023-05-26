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
import 'package:messenger/ui/page/home/page/my_profile/controller.dart';

import '../padding.dart';
import '/api/backend/schema.dart' show Presence;
import '/domain/model/my_user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';
import '/ui/page/home/tab/menu/status/view.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Widget] which returns [MyUser.name] editable field.
class ProfileName extends StatelessWidget {
  const ProfileName(this.name, this.login, {super.key});

  /// [MyUser.name] field state.
  final TextFieldState name;

  /// [MyUser.login] field state.
  final TextFieldState login;

  @override
  Widget build(BuildContext context) {
    return BasicPadding(
      ReactiveTextField(
        key: const Key('NameField'),
        state: name,
        label: 'label_name'.l10n,
        hint: 'label_name_hint'.l10n,
        filled: true,
        onSuffixPressed: login.text.isEmpty
            ? null
            : () {
                PlatformUtils.copy(text: name.text);
                MessagePopup.success('label_copied'.l10n);
              },
        trailing: login.text.isEmpty
            ? null
            : Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/copy.svg', height: 15),
                ),
              ),
      ),
    );
  }
}

/// [Widget] which returns [WidgetButton] displaying the [MyUser.presence].
class ProfilePresence extends StatelessWidget {
  const ProfilePresence(this.myUser, {super.key});

  /// [MyUser] that stores the currently authenticated user.
  final MyUser? myUser;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final Presence? presence = myUser?.presence;

    return BasicPadding(
      FieldButton(
        onPressed: () => StatusView.show(context, expanded: false),
        hint: 'label_presence'.l10n,
        text: presence?.localizedString(),
        trailing:
            CircleAvatar(backgroundColor: presence?.getColor(), radius: 7),
        style: TextStyle(color: style.colors.primary),
      ),
    );
  }
}

/// [Widget] which returns [MyUser.status] editable field.
class ProfileStatus extends StatelessWidget {
  const ProfileStatus(this.status, {super.key});

  /// [MyUser.status] field state.
  final TextFieldState status;

  @override
  Widget build(BuildContext context) {
    return BasicPadding(
      ReactiveTextField(
        key: const Key('StatusField'),
        state: status,
        label: 'label_status'.l10n,
        filled: true,
        maxLength: 25,
        onSuffixPressed: status.text.isEmpty
            ? null
            : () {
                PlatformUtils.copy(text: status.text);
                MessagePopup.success('label_copied'.l10n);
              },
        trailing: status.text.isEmpty
            ? null
            : Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/copy.svg', height: 15),
                ),
              ),
      ),
    );
  }
}
