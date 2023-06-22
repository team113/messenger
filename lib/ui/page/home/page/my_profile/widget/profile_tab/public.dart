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
import '/ui/page/home/tab/menu/status/view.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Widget] which returns [MyUser.name] editable field.
class ProfileName extends StatelessWidget {
  const ProfileName(this.name, {super.key, this.isLoginEmpty = false});

  /// [MyUser.name] field state.
  final TextFieldState name;

  ///
  final bool isLoginEmpty;

  @override
  Widget build(BuildContext context) {
    return Paddings.basic(
      ReactiveTextField(
        key: const Key('NameField'),
        state: name,
        label: 'label_name'.l10n,
        hint: 'label_name_hint'.l10n,
        filled: true,
        onSuffixPressed: isLoginEmpty
            ? null
            : () {
                PlatformUtils.copy(text: name.text);
                MessagePopup.success('label_copied'.l10n);
              },
        trailing: isLoginEmpty
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
  const ProfilePresence({super.key, this.text, this.backgroundColor});

  ///
  final String? text;

  ///
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Paddings.basic(
      FieldButton(
        onPressed: () => StatusView.show(context, expanded: false),
        hint: 'label_presence'.l10n,
        text: text,
        trailing: CircleAvatar(
          backgroundColor: backgroundColor,
          radius: 7,
        ),
        style: fonts.titleMedium!.copyWith(color: style.colors.primary),
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
    final fonts = Theme.of(context).fonts;

    return Paddings.basic(
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
        style: fonts.titleMedium,
      ),
    );
  }
}
