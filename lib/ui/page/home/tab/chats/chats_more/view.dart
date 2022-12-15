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
import 'package:messenger/config.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/message_popup.dart';

import 'controller.dart';

class ChatsMoreView extends StatelessWidget {
  const ChatsMoreView({super.key});

  /// Displays an [ChatsMoreView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const ChatsMoreView());
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
      init: ChatsMoreController(Get.find()),
      builder: (ChatsMoreController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(
              header: Center(
                child: Text(
                  'Звуковые уведомления'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: ModalPopup.padding(context),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 8),
                  _mute(context, c),
                  const SizedBox(height: 21),
                  header('Прямая ссылка на чат с Вами'),
                  const SizedBox(height: 4),
                  _link(context, c),
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

  Widget _mute(BuildContext context, ChatsMoreController c) {
    return Obx(() {
      return Stack(
        alignment: Alignment.centerRight,
        children: [
          IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: c.muted.value ? 'Отключены' : 'Включены',
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
                  data: ThemeData(
                    platform: TargetPlatform.macOS,
                  ),
                  child: Switch.adaptive(
                    activeColor: Theme.of(context).colorScheme.secondary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: !c.muted.value,
                    onChanged: (m) => c.muted.toggle(),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Returns [MyUser.chatDirectLink] editable field.
  Widget _link(BuildContext context, ChatsMoreController c) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ReactiveTextField(
            key: const Key('LinkField'),
            state: c.link,
            onSuffixPressed: c.link.isEmpty.value
                ? null
                : () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '${Config.origin}${Routes.chatDirectLink}/${c.link.text}',
                      ),
                    );

                    // Clipboard.setData(
                    //   ClipboardData(
                    //     text:
                    //         '${Config.origin}${Routes.chatDirectLink}/${c.myUser.value?.chatDirectLink?.slug.val}',
                    //   ),
                    // );

                    MessagePopup.success('label_copied_to_clipboard'.l10n);
                  },
            trailing: c.link.isEmpty.value
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
            label: '${Config.origin}/',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Row(
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                    children: [
                      TextSpan(
                        text: 'Переходов: 0.',
                        // style: TextStyle(color: Color(0xFF888888)),
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                      // TextSpan(
                      //   text: 'Подробнее.',
                      //   style: const TextStyle(color: Color(0xFF00A3FF)),
                      //   recognizer: TapGestureRecognizer()
                      //     ..onTap = () {
                      //       LinkDetailsView.show(context);
                      //     },
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
