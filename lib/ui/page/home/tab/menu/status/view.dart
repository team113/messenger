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

import '/api/backend/schema.dart' show Presence;
import '/l10n/l10n.dart';
import '/ui/page/home/page/my_profile/controller.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for changing [MyUser.status] and/or [MyUser.presence].
///
/// Intended to be displayed with the [show] method.
class StatusView extends StatelessWidget {
  const StatusView({super.key, this.expanded = true});

  /// Indicator whether this [StatusView] should contain [MyUser.status] field
  /// as well as [MyUser.presence], or [MyUser.presence] only otherwise.
  final bool expanded;

  /// Displays a [StatusView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {bool expanded = true}) {
    return ModalPopup.show(
      context: context,
      child: StatusView(expanded: expanded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme theme = Theme.of(context).textTheme;

    return GetBuilder(
      init: StatusController(Get.find()),
      builder: (StatusController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(
              header: Center(
                child: Text(
                  expanded ? 'label_status'.l10n : 'label_presence'.l10n,
                  style: theme.displaySmall,
                ),
              ),
            ),
            Flexible(
              child: Scrollbar(
                controller: c.scrollController,
                child: ListView(
                  controller: c.scrollController,
                  padding: ModalPopup.padding(context),
                  shrinkWrap: true,
                  children: [
                    if (expanded) ...[
                      _padding(
                        ReactiveTextField(
                          key: const Key('StatusField'),
                          state: c.status,
                          label: 'label_status'.l10n,
                          filled: true,
                          maxLength: 25,
                          onSuffixPressed: c.status.text.isEmpty
                              ? null
                              : () {
                                  PlatformUtils.copy(text: c.status.text);
                                  MessagePopup.success('label_copied'.l10n);
                                },
                          trailing: c.status.text.isEmpty
                              ? null
                              : Transform.translate(
                                  offset: const Offset(0, -1),
                                  child: Transform.scale(
                                    scale: 1.15,
                                    child: SvgImage.asset(
                                      'assets/icons/copy.svg',
                                      height: 15,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                        child: Center(
                          child: Text(
                            'label_presence'.l10n,
                            style: theme.headlineSmall,
                          ),
                        ),
                      ),
                    ],
                    ...[Presence.present, Presence.away].map((e) {
                      return Obx(() {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RectangleButton(
                            selected: c.presence.value == e,
                            label: e.localizedString() ?? '',
                            onPressed: () => c.presence.value = e,
                            trailingColor: e.getColor(),
                          ),
                        );
                      });
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);
}
