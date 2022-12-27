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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show Presence;
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/confirm_dialog.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';

import 'controller.dart';

class StatusView extends StatelessWidget {
  const StatusView({super.key, this.presenceOnly = false});

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

    Widget header(String text) {
      final Style style = Theme.of(context).extension<Style>()!;

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              text,
              style: style.systemMessageStyle
                  .copyWith(color: Colors.black, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return GetBuilder(
      init: MoreController(Get.find()),
      builder: (MoreController c) {
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
                    // const SizedBox(height: 8),
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
                                    ClipboardData(text: c.status.text));
                                // MessagePopup.success(
                                //   'label_copied_to_clipboard'.l10n,
                                // );
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
                    header('label_presence'.l10n),
                  ],
                  ...[Presence.present, Presence.away].map((e) {
                    return Obx(() {
                      String? subtitle;
                      String? title;
                      Color? color;

                      switch (e) {
                        case Presence.present:
                          title = 'btn_online'.l10n;
                          color = Colors.green;
                          // subtitle = 'Или информация о последнем входе';
                          break;

                        case Presence.away:
                          title = 'btn_away'.l10n;
                          color = Colors.orange;
                          // subtitle = 'Или информация о последнем входе';
                          break;

                        case Presence.hidden:
                          title = 'btn_invisible'.l10n;
                          color = Colors.grey;
                          break;

                        case Presence.artemisUnknown:
                          // No-op.
                          break;
                      }

                      final Style style = Theme.of(context).extension<Style>()!;

                      final bool selected = c.presence.value == e;

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
                                  backgroundColor:
                                      // Color(0xFF63B4FF),
                                      color,
                                  radius: 12,
                                  child: AnimatedSwitcher(
                                    duration: 200.milliseconds,
                                    child: selected
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          borderRadius: BorderRadius.circular(10),
                          color: selected
                              ? const Color(0xFFD7ECFF).withOpacity(0.8)
                              : Colors.white.darken(0.05),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => c.presence.value = e,
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              height: 52,
                              child: Row(
                                children: [
                                  // CircleAvatar(
                                  //   radius: 8,
                                  //   backgroundColor: color,
                                  // ),
                                  // const SizedBox(width: 8 + 4),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title ?? '',
                                          maxLines: 1,
                                          style: const TextStyle(fontSize: 17),
                                        ),
                                        if (subtitle != null) ...[
                                          const SizedBox(height: 4),
                                          Flexible(
                                            child: Text(
                                              subtitle,
                                              style: const TextStyle(
                                                color: Color(0xFF888888),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircleAvatar(
                                      backgroundColor:
                                          // Color(0xFF63B4FF),
                                          color,
                                      radius: 12,
                                      child: AnimatedSwitcher(
                                        duration: 200.milliseconds,
                                        child: selected
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 12,
                                              )
                                            : const SizedBox(key: Key('None')),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  }),
                  // Padding(
                  //   padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  //   child: RichText(
                  //     text: TextSpan(
                  //       style: const TextStyle(
                  //           fontSize: 11, fontWeight: FontWeight.normal),
                  //       children: [
                  //         const TextSpan(
                  //           text: 'Ваше присутствие видят: ',
                  //           style: TextStyle(color: Color(0xFF888888)),
                  //         ),
                  //         TextSpan(
                  //           text: 'все.',
                  //           style: const TextStyle(color: Color(0xFF00A3FF)),
                  //           recognizer: TapGestureRecognizer()
                  //             ..onTap = () async {
                  //               await ConfirmDialog.show(
                  //                 context,
                  //                 title: 'Присутствие'.l10n,
                  //                 // description:
                  //                 //     'Unique login is an additional unique identifier for your account. \n\nVisible to: ',
                  //                 additional: const [
                  //                   Center(
                  //                     child: Text(
                  //                       'Unique login is an additional unique identifier for your account.\n',
                  //                       style: TextStyle(
                  //                         fontSize: 15,
                  //                         color: Color(0xFF888888),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                   Align(
                  //                     alignment: Alignment.centerLeft,
                  //                     child: Text(
                  //                       'Visible to:',
                  //                       style: TextStyle(
                  //                           fontSize: 18, color: Colors.black),
                  //                     ),
                  //                   ),
                  //                 ],
                  //                 proceedLabel: 'Confirm',
                  //                 variants: [
                  //                   ConfirmDialogVariant(
                  //                     onProceed: () {},
                  //                     child: Text('Все'.l10n),
                  //                   ),
                  //                   ConfirmDialogVariant(
                  //                     onProceed: () {},
                  //                     child: Text('Мои контакты'.l10n),
                  //                   ),
                  //                   ConfirmDialogVariant(
                  //                     onProceed: () {},
                  //                     child: Text('Никто'.l10n),
                  //                   ),
                  //                 ],
                  //               );
                  //             },
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
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
