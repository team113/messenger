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
  const ColorStyleTabView({Key? key}) : super(key: key);

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
                    color: hsl.lightness > 0.5 ? Colors.black : Colors.white,
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
      backgroundColor:
          isDarkMode ? style.colors.onBackground : style.colors.onPrimary,
      body: ListView(
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
            spacing: 16,
            runSpacing: 16,
            children: [
              color(style.colors.primary, 'Цвет кнопок и ссылок.'),
              color(style.colors.secondary, 'Цвет текста и обводок.'),
              color(style.colors.background, 'Общий фон.'),
              color(style.colors.secondaryBackground, 'Фон текста и обводки.'),
              color(
                style.colors.secondaryBackgroundLight,
                'Цвет заднего фона звонка.',
              ),
              color(
                style.colors.secondaryBackgroundLightest,
                'Цвет заднего фона аватара, кнопок звонка.',
              ),
              color(style.colors.secondaryHighlight, 'Цвет колеса загрузки.'),
              color(
                style.colors.secondaryHighlightDark,
                'Цвет кнопок навигационной панели.',
              ),
              color(
                style.colors.secondaryHighlightDarkest,
                'Цвет надписей и иконок над задним фоном звонка.',
              ),
              color(
                style.colors.onPrimary,
                'Цвет, использующийся в левой части страницы профиля.',
              ),
              color(style.colors.primaryHighlight, 'Цвет выпадающего меню.'),
              color(
                style.colors.primaryHighlightShinier,
                'Цвет затемнения основного вида при неактивном вызове.',
              ),
              color(
                style.colors.primaryHighlightShiniest,
                'Цвет сообщения в чате.',
              ),
              color(style.colors.onSecondary, 'Цвет кнопок в звонке.'),
              color(style.colors.backgroundAuxiliary, 'Цвет активного звонка.'),
              color(
                style.colors.backgroundAuxiliaryLight,
                'Цвет фона профиля.',
              ),
              color(
                style.colors.backgroundAuxiliaryLighter,
                'Цвет отмены загрузки.',
              ),
              color(
                style.colors.backgroundAuxiliaryLightest,
                'Цвет фона участников группы.',
              ),
              color(
                style.colors.onBackground,
                'Цвет основного текста приложения.',
              ),
              color(style.colors.acceptColor, 'Цвет кнопки принятия звонка.'),
              color(
                style.colors.acceptAuxiliaryColor,
                'Цвет панели пользователя.',
              ),
              color(
                style.colors.declineColor,
                'Цвет кнопки завершения звонка.',
              ),
              color(
                style.colors.dangerColor,
                'Цвет, предупредающий о чем-либо.',
              ),
              color(style.colors.warningColor, 'Цвет статуса "Не беспокоить".'),
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
            spacing: 16,
            runSpacing: 16,
            children: style.colors.userColors.map(color).toList(),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

/// Displays a colored container.
class _Colored extends StatelessWidget {
  const _Colored({
    Key? key,
    this.color,
    this.outline,
  }) : super(key: key);

  /// Color of the container.
  final Color? color;

  /// Optional outline of the container.
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: outline ?? style.colors.onBackground),
      ),
      height: 50,
    );
  }
}
