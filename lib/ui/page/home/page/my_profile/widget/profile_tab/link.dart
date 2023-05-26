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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';

import '/config.dart';
import '/domain/model/my_user.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/ui/page/home/page/my_profile/link_details/view.dart';

/// [Widget] which represents a [ProfileTab.link] section for a user.
class ProfileLink extends StatelessWidget {
  const ProfileLink(this.myUser, this.link, {super.key});

  /// [MyUser] that stores the currently authenticated user.
  final MyUser? myUser;

  /// [MyUser.chatDirectLink] copyable state.
  final TextFieldState link;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReactiveTextField(
          key: const Key('LinkField'),
          state: link,
          onSuffixPressed: link.isEmpty.value
              ? null
              : () {
                  PlatformUtils.copy(
                    text:
                        '${Config.origin}${Routes.chatDirectLink}/${link.text}',
                  );

                  MessagePopup.success('label_copied'.l10n);
                },
          trailing: link.isEmpty.value
              ? null
              : Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgImage.asset('assets/icons/copy.svg', height: 15),
                  ),
                ),
          label: '${Config.origin}/',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      text: 'label_transition_count'.l10nfmt({
                            'count': myUser?.chatDirectLink?.usageCount ?? 0
                          }) +
                          'dot_space'.l10n,
                      style: TextStyle(
                        color: style.colors.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_details'.l10n,
                      style: TextStyle(
                        color: style.colors.primary,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap =
                            () async => await LinkDetailsView.show(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
