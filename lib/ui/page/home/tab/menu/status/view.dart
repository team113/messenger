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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';

import 'controller.dart';

/// Used to change [MyUser.status] and [MyUser.presenceIndex].
class StatusView extends StatelessWidget {
  const StatusView({super.key, this.presenceOnly = false});

  /// Indicator whether only [MyUser.presenceIndex] can be changed.
  final bool presenceOnly;

  /// Displays an [StatusView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {bool presenceOnly = false}) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: StatusView(presenceOnly: presenceOnly),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: StatusViewController(Get.find()),
      builder: (StatusViewController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(
              header: Center(
                child: Text(
                  presenceOnly ? 'label_presence'.l10n : 'label_status'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: ModalPopup.padding(context),
                shrinkWrap: true,
                children: [
                  if (!presenceOnly) ...[
                    _padding(
                      ReactiveTextField(
                        key: const Key('StatusField'),
                        state: c.status,
                        label: 'Status'.l10n,
                        filled: true,
                        onSuffixPressed: c.status.text.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(
                                  ClipboardData(text: c.status.text),
                                );

                                MessagePopup.success(
                                  'label_copied_to_clipboard'.l10n,
                                );
                              },
                        trailing: c.status.text.isEmpty
                            ? null
                            : Transform.translate(
                                offset: const Offset(0, -1),
                                child: Transform.scale(
                                  scale: 1.15,
                                  child: SvgLoader.asset(
                                    'assets/icons/copy.svg',
                                    height: 15,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                          child: Text(
                            'label_presence'.l10n,
                            style: style.systemMessageStyle
                                .copyWith(color: Colors.black, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                  ...[Presence.present, Presence.away].map((e) {
                    return Obx(() {
                      String? title;
                      Color? color;

                      switch (e) {
                        case Presence.present:
                          title = 'btn_online'.l10n;
                          color = Colors.green;
                          break;

                        case Presence.away:
                          title = 'btn_away'.l10n;
                          color = Colors.orange;
                          break;

                        case Presence.hidden:
                          title = 'btn_invisible'.l10n;
                          color = Colors.grey;
                          break;

                        case Presence.artemisUnknown:
                          // No-op.
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WidgetButton(
                          onPressed: () => c.presence.value = e,
                          child: IgnorePointer(
                            child: ReactiveTextField(
                              fillColor: c.presence.value == e
                                  ? style.cardSelectedColor
                                  : Colors.white,
                              state:
                                  TextFieldState(text: title, editable: false),
                              trailing: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircleAvatar(
                                  backgroundColor: color,
                                  radius: 12,
                                  child: AnimatedSwitcher(
                                    duration: 200.milliseconds,
                                    child: c.presence.value == e
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          )
                                        : const SizedBox(key: Key('None')),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  }),
                ],
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
