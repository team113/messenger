// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '/domain/model/deposit.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/tab/wallet/widget/deposit_expandable.dart';
import '/ui/page/home/widget/app_bar.dart';
import 'controller.dart';

class DepositView extends StatelessWidget {
  const DepositView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: DepositController(Get.find()),
      builder: (DepositController c) {
        return Scaffold(
          appBar: CustomAppBar(
            leading: const [SizedBox(width: 4), StyledBackButton()],
            title: Text('btn_add_funds'.l10n),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
            children: [
              ...DepositKind.values.map((e) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Obx(() {
                      final bool expanded = c.expanded.contains(e);

                      return DepositExpandable(
                        expanded: expanded,
                        onPressed: expanded
                            ? () => c.expanded.remove(e)
                            : () => c.expanded.add(e),
                        provider: e,
                        fields: c.fields.value,
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
