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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../widget/caption.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';

/// Colors tab view of the [Routes.style] page.
class ColorStyleTabView extends StatefulWidget {
  const ColorStyleTabView({super.key});

  @override
  State<ColorStyleTabView> createState() => _ColorStyleTabViewState();
}

/// State of a [ColorStyleTabView] used to keep the [isDarkMode] indicator.
class _ColorStyleTabViewState extends State<ColorStyleTabView> {
  /// Indicator whether this page is in dark mode.
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget color(Color color, [String? desc]) {
      final HSLColor hsl = HSLColor.fromColor(color);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WidgetButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: color.toHex()));
              MessagePopup.success('label_copied'.l10n);
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Center(
                child: Text(
                  color.toHex(),
                  style: TextStyle(
                    color: hsl.lightness > 0.7 ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          if (desc != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                desc,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: isDarkMode ? style.colors.onBackground : style.colors.onPrimary,
        child: ListView(
          controller: ScrollController(),
          padding: const EdgeInsets.all(8),
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.light_mode, color: style.colors.warningColor),
                Switch(
                  value: isDarkMode,
                  onChanged: (b) => setState(() => isDarkMode = b),
                ),
                Icon(Icons.dark_mode, color: style.colors.secondary),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                color(
                  style.colors.onBackground,
                  'Цвет основного текста приложения.',
                ),
                color(
                    style.colors.secondaryBackground, 'Фон текста и обводки.'),
                color(
                  style.colors.secondaryBackgroundLight,
                  'Цвет заднего фона звонка.',
                ),
                color(
                  style.colors.secondaryBackgroundLightest,
                  'Цвет заднего фона аватара, кнопок звонка.',
                ),
                color(style.colors.secondary, 'Цвет текста и обводок.'),
                color(
                  style.colors.secondaryHighlightDarkest,
                  'Цвет надписей и иконок над задним фоном звонка.',
                ),
                color(
                  style.colors.secondaryHighlightDark,
                  'Цвет кнопок навигационной панели.',
                ),
                color(style.colors.secondaryHighlight, 'Цвет колеса загрузки.'),
                color(style.colors.background, 'Общий фон.'),
                color(
                  style.colors.secondaryOpacity87,
                  'Цвет поднятой руки и выключенного микрофона в звонке.',
                ),
                color(
                  style.colors.onBackgroundOpacity50,
                  'Цвет фона прикрепленного файла.',
                ),
                color(
                  style.colors.onBackgroundOpacity40,
                  'Цвет нижнего бара в чате.',
                ),
                color(
                  style.colors.onBackgroundOpacity27,
                  'Цвет тени плавающей панели.',
                ),
                color(
                  style.colors.onBackgroundOpacity20,
                  'Цвет панели с кнопками в звонке.',
                ),
                color(
                  style.colors.onBackgroundOpacity13,
                  'Цвет кнопки проигрывания видео.',
                ),
                color(
                  style.colors.onBackgroundOpacity7,
                  'Цвет разделителей в приложении.',
                ),
                color(
                  style.colors.onBackgroundOpacity2,
                  'Цвет текста "Подключение", "Звоним" и т.д. в звонке.',
                ),
                color(
                  style.colors.onPrimary,
                  'Цвет, использующийся в левой части страницы профиля.',
                ),
                color(
                  style.colors.onPrimaryOpacity95,
                  'Цвет сообщения, которое было получено.',
                ),
                color(
                  style.colors.onPrimaryOpacity50,
                  'Цвет обводки кнопок принятия звонка с аудио и видео.',
                ),
                color(
                  style.colors.onPrimaryOpacity25,
                  'Цвет тени пересланных сообщений.',
                ),
                color(
                  style.colors.onPrimaryOpacity7,
                  'Дополнительный цвет бэкграунда звонка.',
                ),
                color(
                    style.colors.backgroundAuxiliary, 'Цвет активного звонка.'),
                color(
                  style.colors.backgroundAuxiliaryLight,
                  'Цвет фона профиля.',
                ),
                color(
                  style.colors.onSecondaryOpacity88,
                  'Цвет верхней перетаскиваемой строки заголовка.',
                ),
                color(style.colors.onSecondary, 'Цвет кнопок в звонке.'),
                color(
                  style.colors.onSecondaryOpacity60,
                  'Дополнительный цвет верхней перетаскиваемой строки заголовка.',
                ),
                color(
                  style.colors.onSecondaryOpacity50,
                  'Цвет кнопок в галерее.',
                ),
                color(
                  style.colors.onSecondaryOpacity20,
                  'Цвет мобильного селектора.',
                ),
                color(style.colors.primaryHighlight, 'Цвет выпадающего меню.'),
                color(style.colors.primary, 'Цвет кнопок и ссылок.'),
                color(
                  style.colors.primaryHighlightShiniest,
                  'Цвет прочитанного сообщения.',
                ),
                color(
                  style.colors.primaryHighlightLightest,
                  'Цвет обводки прочитанного сообщения.',
                ),
                color(
                  style.colors.backgroundAuxiliaryLighter,
                  'Цвет отмены загрузки.',
                ),
                color(
                  style.colors.backgroundAuxiliaryLightest,
                  'Цвет фона участников группы и непрочитанного сообщения.',
                ),
                color(
                  style.colors.acceptAuxiliaryColor,
                  'Цвет панели пользователя.',
                ),
                color(style.colors.acceptColor, 'Цвет кнопки принятия звонка.'),
                color(
                  style.colors.dangerColor,
                  'Цвет, предупредающий о чем-либо.',
                ),
                color(
                  style.colors.declineColor,
                  'Цвет кнопки завершения звонка.',
                ),
                color(
                    style.colors.warningColor, 'Цвет статуса "Не беспокоить".'),
              ],
            ),
            const SizedBox(height: 50),
            Text(
              'Цвета аватаров:',
              style: context.textTheme.displayLarge!.copyWith(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: style.colors.userColors.map(color).toList(),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
