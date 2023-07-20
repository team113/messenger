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
import 'package:messenger/ui/page/home/page/my_profile/widget/download_button.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/rectangular_call_button.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '../../../home/widget/rectangle_button.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '../../../home/tab/menu/widget/menu_button.dart';
import '../../../home/widget/field_button.dart';
import '../../../home/widget/shadowed_rounded_button.dart';
import '/themes.dart';

class ButtonsWidget extends StatelessWidget {
  const ButtonsWidget({super.key, required this.isDarkMode});

  /// Indicator whether this page is in dark mode.
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ButtonCard(
                isDarkMode: isDarkMode,
                title: 'OutlinedRoundedButton',
                labels: const ['Default', 'Hovered', 'Pressed', 'Unavailable'],
                children: [
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
                ],
              ),
              _ButtonCard(
                isDarkMode: isDarkMode,
                title: 'FieldButton',
                labels: const ['Default', 'Hovered', 'Pressed', 'Unavailable'],
                children: [
                  SizedBox(
                    width: 320,
                    height: 51,
                    child: FieldButton(
                      onPressed: () {},
                      text: 'Change password',
                      style: fonts.titleMedium!.copyWith(
                        color: style.colors.primary,
                      ),
                    ),
                  ),
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
                ],
              ),
              _ButtonCard(
                labels: const ['Default', 'Hovered', 'Pressed', 'Unavailable'],
                isDarkMode: isDarkMode,
                title: 'OutlinedRoundedButton (2)',
                children: [
                  OutlinedRoundedButton(
                    title: Text('Login', style: fonts.titleLarge),
                    leading: SvgImage.asset(
                      'assets/icons/sign_in.svg',
                      width: 20 * 0.7,
                    ),
                    onPressed: () {},
                  ),
                  OutlinedRoundedButton(
                    color: const Color(0xFFFDFDFD),
                    title: Text('Login', style: fonts.titleLarge),
                    leading: SvgImage.asset(
                      'assets/icons/sign_in.svg',
                      width: 20 * 0.7,
                    ),
                    onPressed: () {},
                  ),
                  OutlinedRoundedButton(
                    color: const Color(0xFFD6D6D6),
                    title: Text('Login', style: fonts.titleLarge),
                    leading: SvgImage.asset(
                      'assets/icons/sign_in.svg',
                      width: 20 * 0.7,
                    ),
                    onPressed: () {},
                  ),
                  OutlinedRoundedButton(
                    title: Text('Login', style: fonts.titleLarge),
                    leading: SvgImage.asset(
                      'assets/icons/sign_in.svg',
                      width: 20 * 0.7,
                    ),
                  ),
                ],
              ),
              _ButtonCard(
                labels: const ['Default', 'Hovered', 'Pressed', 'Unavailable'],
                isDarkMode: isDarkMode,
                title: 'ShadowedRoundedButton',
                children: [
                  ShadowedRoundedButton(
                    onPressed: () {},
                    child: Text(
                      'Cancel',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: fonts.titleLarge,
                    ),
                  ),
                  ShadowedRoundedButton(
                    onPressed: () {},
                    child: Text(
                      'Cancel',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: fonts.titleLarge,
                    ),
                  ),
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
                  ShadowedRoundedButton(
                    child: Text(
                      'Cancel',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: fonts.titleLarge,
                    ),
                  ),
                ],
              ),
              _ButtonCard(
                height: 410,
                isDarkMode: isDarkMode,
                title: 'MenuButton',
                labels: const ['Default', 'Hovered', 'Selected', 'Unavailable'],
                children: [
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
                  const SizedBox(
                    width: 330,
                    height: 73,
                    child: MenuButton(
                      icon: Icons.person,
                      title: 'Public information',
                      subtitle: 'Avatar and name',
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  _ButtonCard(
                    height: 210,
                    isDarkMode: isDarkMode,
                    title: 'ContextMenuButton',
                    labels: const ['Default', 'Hovered', 'Pressed'],
                    children: [
                      Container(
                        height: 40,
                        width: 133,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 239, 239, 239),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: ContextMenuButton(label: 'Message info'),
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 133,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 239, 239, 239),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: ContextMenuButton(
                            label: 'Message info',
                            color: style.colors.primary,
                            style: fonts.bodySmall!.copyWith(
                              color: style.colors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 133,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 239, 239, 239),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: ContextMenuButton(
                            label: 'Message info',
                            style: fonts.bodySmall!.copyWith(
                              color: style.colors.onPrimary,
                            ),
                            color: style.colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ButtonCard(
                    height: 183,
                    isDarkMode: isDarkMode,
                    title: 'WidgetButton',
                    labels: const ['Default', 'Hovered', 'Pressed'],
                    children: [
                      WidgetButton(
                        child: Text(
                          'Upload',
                          style: fonts.bodySmall!.copyWith(
                            color: style.colors.primary,
                          ),
                        ),
                        onPressed: () {},
                      ),
                      WidgetButton(
                        child: Text(
                          'Upload',
                          style: fonts.bodySmall!.copyWith(
                            color: style.colors.primary,
                          ),
                        ),
                        onPressed: () {},
                      ),
                      WidgetButton(
                        child: Text(
                          'Upload',
                          style: fonts.bodySmall!.copyWith(
                            color: style.colors.primary,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              _ButtonCard(
                height: 360,
                labels: const ['Default', 'Hovered', 'Selected', 'Unavailable'],
                isDarkMode: isDarkMode,
                title: 'RectangleButton',
                children: [
                  SizedBox(
                    width: 300,
                    height: 70,
                    child: RectangleButton(
                      label: 'Display calls in a separate window.',
                      selected: false,
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    height: 70,
                    child: RectangleButton(
                      color: const Color(0xFFE9E9E9),
                      label: 'Display calls in a separate window.',
                      selected: false,
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    height: 70,
                    child: RectangleButton(
                      label: 'Display calls in a separate window.',
                      selected: true,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(
                    width: 300,
                    height: 70,
                    child: RectangleButton(
                      label: 'Display calls in a separate window.',
                      selected: false,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  _ButtonCard(
                    height: 184,
                    labels: const ['Default', 'Hovered'],
                    isDarkMode: isDarkMode,
                    title: 'DownloadButton',
                    children: const [
                      SizedBox(
                        width: 320,
                        height: 52,
                        child: DownloadButton(
                          asset: 'apple',
                          width: 23,
                          height: 29,
                          title: 'macOS',
                          link: 'messenger-macos.zip',
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        height: 52,
                        child: DownloadButton(
                          color: Color(0xFFF7F7F7),
                          asset: 'apple',
                          width: 23,
                          height: 29,
                          title: 'macOS',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ButtonCard(
                    height: 160,
                    labels: const ['Default', 'Inverted'],
                    isDarkMode: isDarkMode,
                    title: 'RectangularCallButton',
                    children: [
                      SizedBox(
                        width: 85,
                        height: 30,
                        child: RectangularCallButton(
                          isActive: false,
                          at: DateTime.now(),
                          onPressed: () {},
                        ),
                      ),
                      SizedBox(
                        width: 85,
                        height: 30,
                        child: RectangularCallButton(
                          isActive: true,
                          at: DateTime.now(),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ButtonCard extends StatelessWidget {
  const _ButtonCard({
    required this.isDarkMode,
    required this.title,
    required this.children,
    this.labels,
    this.height = 335,
  });

  final bool isDarkMode;

  final String title;

  final List<Widget> children;

  final List<String>? labels;

  final double height;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Container(
      height: height,
      width: 490,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: style.colors.onPrimary,
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Text(
            title,
            style: fonts.headlineLarge,
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 490,
                height: height - 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          child: SvgImage.asset(
                            'assets/images/background_${isDarkMode ? 'dark' : 'light'}.svg',
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (labels != null)
                            DefaultTextStyle(
                              style: fonts.titleMedium!.copyWith(
                                color: isDarkMode
                                    ? style.colors.onPrimary
                                    : const Color(0xFF1F3C5D),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  labels!.length,
                                  (i) => Text(labels![i]),
                                ),
                              ),
                            ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: children,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
