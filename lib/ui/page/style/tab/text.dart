// ignore_for_file: public_member_api_docs, sort_constructors_first
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

import '../widget/caption.dart';

/// Fonts tab view of the [Routes.style] page.
class FontStyleTabView extends StatelessWidget {
  const FontStyleTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
        maxLines: 1,
        child: ListView(
          controller: ScrollController(),
          padding: const EdgeInsets.all(8),
          children: [
            _FontWidget('Заголовок 3', 'Messenger',
                context.theme.textTheme.displaySmall!),
            _FontWidget('Заголовок 4', 'Universal Messenger',
                context.theme.textTheme.headlineMedium!),
            _FontWidget('Заголовок 5', 'by Gapopa',
                context.theme.textTheme.headlineSmall!),
            _FontWidget(
              'Кнопка',
              'Start chatting',
              context.theme.outlinedButtonTheme.style!.textStyle!
                  .resolve({MaterialState.disabled})!,
            ),
            _FontWidget(
              'Подпись к кнопке',
              'no registration',
              context.theme.outlinedButtonTheme.style!.textStyle!
                  .resolve({MaterialState.disabled})!.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 60),
          ],
        ),
      );
}

class _FontWidget extends StatelessWidget {
  final String desc;
  final String sample;
  final TextStyle style;
  const _FontWidget(
    this.desc,
    this.sample,
    this.style, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Caption(
            '$desc - шрифт: ${style.fontSize} пт, цвет: ${style.color?.toHex()}'),
        Text(sample, style: style),
      ],
    );
  }
}
