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

import '../dense.dart';
import '/domain/model/application_settings.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';

/// [Widget] which returns the contents of a [ProfileTab.storage] section.
class ProfileStorage extends StatelessWidget {
  const ProfileStorage(this.settings, this.setLoadImages, {super.key});

  /// Reactive [ApplicationSettings] that returns the current settings.
  final Rx<ApplicationSettings?> settings;

  /// Called when the user toggles the switch on or off.
  final void Function(bool enabled) setLoadImages;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Dense(
        Stack(
          alignment: Alignment.centerRight,
          children: [
            IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'label_load_images'.l10n,
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
                    data: ThemeData(platform: TargetPlatform.macOS),
                    child: Switch.adaptive(
                      activeColor: Theme.of(context).colorScheme.secondary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: settings.value?.loadImages == true,
                      onChanged: settings.value == null ? null : setLoadImages,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
