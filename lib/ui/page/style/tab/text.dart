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

import '../widget/caption.dart';

/// Fonts tab view of the [Routes.style] page.
class FontStyleTabView extends StatelessWidget {
  const FontStyleTabView({Key? key}) : super(key: key);

  Widget _font(String desc, String sample, TextStyle? style) => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Caption(
              '$desc - шрифт: ${style!.fontSize} пт, цвет: ${style.color?.toHex()}'),
          Text(sample, style: style),
        ],
      );

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
        maxLines: 1,
        child: ListView(
          controller: ScrollController(),
          padding: const EdgeInsets.all(8),
          children: [
            _font('Заголовок 3', 'Messenger',
                context.theme.textTheme.displaySmall!),
            _font('Заголовок 4', 'by Gapopa',
                context.theme.textTheme.headlineSmall!),
            _font(
              'Кнопка "Начать"',
              'btn_start'.l10n,
              context.textTheme.displaySmall,
            ),
            _font(
              'Кнопка "Войти"',
              'btn_login'.l10n,
              context.textTheme.displaySmall,
            ),
            _font(
              'Опциональная кнопка "Скачать"',
              'btn_download'.l10n,
              context.textTheme.displaySmall,
            ),
            _font(
              'Всплывающее окно выбора языка.',
              'label_language_entry'.l10nfmt({
                'code': L10n.chosen.value!.locale.countryCode,
                'name': L10n.chosen.value!.name,
              }),
              context.textTheme.bodySmall!
                  .copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 60),
          ],
        ),
      );
}
