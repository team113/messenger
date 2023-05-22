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
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/util/platform_utils.dart';

import '/domain/model/chat.dart';
import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class InsufficientFundsView extends StatelessWidget {
  const InsufficientFundsView({super.key, required this.description});

  final String description;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required String description,
  }) {
    return ModalPopup.show(
      context: context,
      child: InsufficientFundsView(description: description),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: InsufficientFundsController(Get.find()),
      builder: (InsufficientFundsController c) {
        final TextStyle? thin = Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: Colors.black);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            ModalPopupHeader(
              header: Center(
                child: Text(
                  'label_insufficient_funds'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 13),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                shrinkWrap: true,
                children: [
                  Text(
                    description,
                    style: thin,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                children: [
                  if (context.isMobile) ...[
                    Expanded(
                      child: OutlinedRoundedButton(
                        key: const Key('Close'),
                        maxWidth: double.infinity,
                        title: Text('btn_close'.l10n),
                        onPressed: () {},
                        color: const Color(0xFFEEEEEE),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedRoundedButton(
                      key: const Key('AddFunds'),
                      maxWidth: double.infinity,
                      title: Text(
                        'btn_add_funds'.l10n,
                        style: thin?.copyWith(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        c.topUp();
                      },
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
