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
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: ListView(
        controller: ScrollController(),
        padding: const EdgeInsets.all(8),
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.light_mode, color: Colors.orange),
              Switch(
                value: isDarkMode,
                onChanged: (b) => setState(() => isDarkMode = b),
              ),
              const Icon(Icons.dark_mode, color: Colors.grey),
            ],
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'background - Общий фон.',
            context.theme.colorScheme.background,
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'primary - Основной цвет текста и обводки.',
            context.theme.colorScheme.primary,
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Hover на кнопках.',
            context.theme.colorScheme.primary.withOpacity(0.04),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Нажатие на кнопку.',
            context.theme.colorScheme.primary.withOpacity(0.12),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Основной цвет текста и обводки.',
            context.theme.colorScheme.primary,
          ),
          _GradientWidget(
            isDarkMode: isDarkMode,
            'Градиент кнопки начать общение.',
            const LinearGradient(
              colors: [Color(0xFF03A803), Color(0xFF20CD66)],
            ),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Цвет заднего фона звонка.',
            const Color(0xFF444444),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Цвет затемнения заднего фона в звонке.',
            const Color(0x40000000),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Цвет надписей и иконок над задним фоном звонка.',
            const Color(0xFFBBBBBB),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Цвет кнопок принятия звонка.',
            const Color(0xA634B139),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Цвет кнопки завершения звонка.',
            const Color(0xA6FF0000),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Цвет кнопок в звонке.',
            const Color(0xA6818181),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Цвет разделителей в панели ПКМ и в панели настроек.',
            const Color(0x99000000),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Задний фон панели настроек.',
            const Color(0xCCFFFFFF),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Задний фон панели ПКМ.',
            const Color(0xE6FFFFFF),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Цвет нижней панели с кнопками в звонке.',
            const Color(0x66000000),
          ),
          _ColorWidget(
            isDarkMode: isDarkMode,
            'Цвет разделителей в нижней панели с кнопками в звонке.',
            const Color(0x99FFFFFF),
          ),
          const SizedBox(height: 60)
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
    this.gradient,
    this.outline,
  }) : super(key: key);

  /// Color of the container.
  final Color? color;

  /// Gradient of the container.
  final Gradient? gradient;

  /// Optional outline of the container.
  final Color? outline;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          border: Border.all(color: outline ?? Colors.black),
        ),
        height: 50,
      );
}

class _ColorWidget extends StatelessWidget {
  final String desc;
  final Color color;
  final bool isDarkMode;
  const _ColorWidget(
    this.desc,
    this.color, {
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Caption(
          '${color.toHex()}, $desc',
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        _Colored(
          color: color,
          outline: isDarkMode ? Colors.white : Colors.black,
        )
      ],
    );
  }
}

class _GradientWidget extends StatelessWidget {
  final String desc;
  final Gradient gradient;
  final bool isDarkMode;
  const _GradientWidget(
    this.desc,
    this.gradient, {
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Caption(
          '${gradient.colors.map((e) => e.toHex())}, $desc',
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        _Colored(
          gradient: gradient,
          outline: isDarkMode ? Colors.white : Colors.black,
        )
      ],
    );
  }
}
