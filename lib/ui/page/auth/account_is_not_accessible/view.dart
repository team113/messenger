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
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';

/// View displaying information that provided [MyUser] cannot be logged in.
class AccountIsNotAccessibleView extends StatelessWidget {
  const AccountIsNotAccessibleView({super.key, required this.myUser});

  /// [MyUser] to display information about.
  final MyUser? myUser;

  /// Displays a [AccountIsNotAccessibleView] wrapped in a [ModalPopup].
  static Future<bool?> show<T>(BuildContext context, MyUser? myUser) {
    return ModalPopup.show(
      context: context,
      child: AccountIsNotAccessibleView(myUser: myUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalPopupHeader(text: 'label_information'.l10n),
        SizedBox(height: 8),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: ModalPopup.padding(context),
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'label_account_has_been_signed_out_due_to_reasons1'
                          .l10n,
                    ),
                    TextSpan(
                      text: '${myUser?.num}',
                      style: style.fonts.small.regular.onBackground,
                    ),
                    TextSpan(
                      text: 'label_account_has_been_signed_out_due_to_reasons2'
                          .l10n,
                    ),
                  ],
                ),
                style: style.fonts.small.regular.secondary,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
        Padding(
          padding: ModalPopup.padding(context),
          child: PrimaryButton(
            danger: true,
            title: 'btn_remove_account'.l10n,
            onPressed: () => Navigator.of(context).pop(true),
            leading: SvgIcon(SvgIcons.removeFromCallWhite),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }
}
