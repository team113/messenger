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
import 'package:messenger/l10n/l10n.dart';

import '../dense.dart';
import '../field_button.dart';
import '/domain/model/application_settings.dart';
import '/ui/page/home/page/my_profile/call_window_switch/controller.dart';

/// [Widget] which returns the contents of a [ProfileTab.calls] section.
class ProfileCall extends StatelessWidget {
  const ProfileCall(this.settings, {super.key});

  /// Reactive [ApplicationSettings] that returns the current settings.
  final Rx<ApplicationSettings?> settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dense(
          Obx(() {
            return FieldButton(
              text: (settings.value?.enablePopups ?? true)
                  ? 'label_open_calls_in_window'.l10n
                  : 'label_open_calls_in_app'.l10n,
              maxLines: null,
              onPressed: () => CallWindowSwitchView.show(context),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            );
          }),
        ),
      ],
    );
  }
}
