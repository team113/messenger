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

import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

import '../../../home/tab/menu/widget/menu_button.dart';
import '../../../home/widget/field_button.dart';
import '../../../home/widget/shadowed_rounded_button.dart';
import '../../colors/widget/custom_switcher.dart';
import '/themes.dart';

class ButtonsWidget extends StatefulWidget {
  const ButtonsWidget({super.key});

  @override
  State<ButtonsWidget> createState() => _ButtonsWidgetState();
}

class _ButtonsWidgetState extends State<ButtonsWidget> {
  /// Indicator whether this page is in dark mode.
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SizedBox(
      height: 600,
      child: Stack(
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: SvgImage.asset(
                'assets/images/background_${isDarkMode ? 'dark' : 'light'}.svg',
                fit: BoxFit.fill,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.light_mode, color: style.colors.warningColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: CustomSwitcher(
                        onChanged: (b) => setState(() => isDarkMode = b),
                      ),
                    ),
                    const Icon(Icons.dark_mode, color: Color(0xFF1F3C5D)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(40),
                child: SizedBox(
                  height: 450,
                  width: MediaQuery.sizeOf(context).width,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _DefaultButtonsColumn(isDarkMode: isDarkMode),
                      const SizedBox(width: 35),
                      _HoveredButtonsColumn(isDarkMode: isDarkMode),
                      const SizedBox(width: 35),
                      _PressedButtonsColumn(isDarkMode: isDarkMode),
                      const SizedBox(width: 35),
                      _UnavailableButtonsColumn(isDarkMode: isDarkMode),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DefaultButtonsColumn extends StatelessWidget {
  const _DefaultButtonsColumn({this.isDarkMode = false});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      children: [
        Text(
          'Default',
          style: fonts.displayMedium!.copyWith(
            color:
                isDarkMode ? style.colors.onPrimary : const Color(0xFF1F3C5D),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 300,
          height: 43,
          child: OutlinedRoundedButton(
            color: style.colors.primary,
            title: Text(
              'Proceed',
              style: fonts.bodyMedium!.copyWith(
                color: style.colors.onPrimary,
              ),
            ),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 320,
          height: 51,
          child: FieldButton(
            text: 'Change password',
            style: fonts.titleMedium!.copyWith(
              color: style.colors.primary,
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 330,
          height: 73,
          child: MenuButton(
            icon: Icons.person,
            title: 'Public information',
            subtitle: 'Avatar and name',
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 30),
        ShadowedRoundedButton(
          onPressed: () {},
          child: Text(
            'Cancel',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: fonts.titleLarge,
          ),
        ),
      ],
    );
  }
}

class _HoveredButtonsColumn extends StatelessWidget {
  const _HoveredButtonsColumn({this.isDarkMode = false});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      children: [
        Text(
          'Hovered',
          style: fonts.displayMedium!.copyWith(
            color:
                isDarkMode ? style.colors.onPrimary : const Color(0xFF1F3C5D),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 300,
          height: 43,
          child: OutlinedRoundedButton(
            color: style.colors.primary,
            title: Text(
              'Proceed',
              style: fonts.bodyMedium!.copyWith(
                color: style.colors.onPrimary,
              ),
            ),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 320,
          height: 51,
          child: FieldButton(
            color: const Color(0xFFF7F7F7),
            text: 'Change password',
            style: fonts.titleMedium!.copyWith(
              color: style.colors.primary,
            ),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 30),
        const SizedBox(
          width: 330,
          height: 73,
          child: MenuButton(
            color: Color(0xFFF7F7F7),
            icon: Icons.person,
            title: 'Public information',
            subtitle: 'Avatar and name',
          ),
        ),
        const SizedBox(height: 30),
        ShadowedRoundedButton(
          onPressed: () {},
          child: Text(
            'Cancel',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: fonts.titleLarge,
          ),
        ),
      ],
    );
  }
}

class _PressedButtonsColumn extends StatelessWidget {
  const _PressedButtonsColumn({this.isDarkMode = false});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      children: [
        Text(
          'Pressed',
          style: fonts.displayMedium!.copyWith(
            color:
                isDarkMode ? style.colors.onPrimary : const Color(0xFF1F3C5D),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 300,
          height: 43,
          child: OutlinedRoundedButton(
            color: const Color(0xFFA5BAD3),
            title: Text(
              'Proceed',
              style: fonts.bodyMedium!.copyWith(
                color: const Color(0xFFF0F8FB),
              ),
            ),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 320,
          height: 51,
          child: FieldButton(
            color: const Color(0xFFF7F7F7),
            text: 'Change password',
            style: fonts.titleMedium!.copyWith(
              color: style.colors.primary,
            ),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 30),
        const SizedBox(
          width: 330,
          height: 73,
          child: MenuButton(
            icon: Icons.person,
            title: 'Public information',
            subtitle: 'Avatar and name',
            inverted: true,
          ),
        ),
        const SizedBox(height: 30),
        ShadowedRoundedButton(
          onPressed: () {},
          color: const Color(0xFFD6D6D6),
          child: Text(
            'Cancel',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: fonts.titleLarge,
          ),
        ),
      ],
    );
  }
}

class _UnavailableButtonsColumn extends StatelessWidget {
  const _UnavailableButtonsColumn({this.isDarkMode = false});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      children: [
        Text(
          'Unavailable',
          style: fonts.displayMedium!.copyWith(
            color:
                isDarkMode ? style.colors.onPrimary : const Color(0xFF1F3C5D),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 300,
          height: 43,
          child: OutlinedRoundedButton(
            color: style.colors.primary,
            title: Text(
              'Proceed',
              style: fonts.bodyMedium!.copyWith(
                color: style.colors.onBackground,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 320,
          height: 51,
          child: FieldButton(
            text: 'Change password',
            style: fonts.titleMedium!.copyWith(
              color: style.colors.primary,
            ),
          ),
        ),
        const SizedBox(height: 30),
        const SizedBox(
          width: 330,
          height: 73,
          child: MenuButton(
            icon: Icons.person,
            title: 'Public information',
            subtitle: 'Avatar and name',
          ),
        ),
        const SizedBox(height: 30),
        ShadowedRoundedButton(
          child: Text(
            'Cancel',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: fonts.titleLarge,
          ),
        ),
      ],
    );
  }
}
