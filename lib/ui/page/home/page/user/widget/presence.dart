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
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/page/my_profile/controller.dart';
import '/ui/page/home/widget/padding.dart';
import '/ui/widget/text_field.dart';

/// [Widget] which returns a [User.presence] text.
class PresenceWidget extends StatelessWidget {
  const PresenceWidget({super.key, this.user});

  /// Reactive [User] itself.
  final RxUser? user;

  @override
  Widget build(BuildContext context) {
    final Presence? presence = user?.user.value.presence;
    if (presence == null) {
      return Container();
    }

    final subtitle = user?.user.value.getStatus();

    return BasicPadding(
      ReactiveTextField(
        key: const Key('Presence'),
        state: TextFieldState(text: subtitle),
        label: 'label_presence'.l10n,
        enabled: false,
        trailing: CircleAvatar(
          key: Key(presence.name.capitalizeFirst!),
          backgroundColor: presence.getColor(),
          radius: 7,
        ),
      ),
    );
  }
}
