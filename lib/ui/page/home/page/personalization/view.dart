// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/widget/outlined_rounded_button.dart';
import 'controller.dart';

/// View of the [Routes.personalization] page.
class PersonalizationView extends StatelessWidget {
  const PersonalizationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: PersonalizationController(Get.find()),
      builder: (PersonalizationController c) {
        return Scaffold(
          appBar: AppBar(title: Text('label_personalization'.l10n)),
          body: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => SizedBox(
                  width: 100,
                  height: 60,
                  child: c.background.value == null
                      ? Container(color: Colors.grey)
                      : Image.memory(
                          c.background.value!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedRoundedButton(
                  title: Text('btn_change_background'.l10n),
                  onPressed: c.pickBackground,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedRoundedButton(
                  title: Text('btn_remove_background'.l10n),
                  onPressed: c.removeBackground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
