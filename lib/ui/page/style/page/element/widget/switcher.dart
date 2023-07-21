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

import '../../../../../widget/text_field.dart';
import '../../../../home/widget/paddings.dart';
import '/themes.dart';

class SwitcherWidget extends StatelessWidget {
  const SwitcherWidget({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _SwitcherCard(
            isDarkMode: isDarkMode,
            title: 'SwitchField',
            children: [
              SizedBox(
                height: 60,
                width: 325,
                child: SwitchField(
                  text: 'Load images',
                  value: true,
                  onChanged: (v) {},
                ),
              ),
              SizedBox(
                height: 60,
                width: 325,
                child: SwitchField(
                  text: 'Load images',
                  value: false,
                  onChanged: (v) {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitcherCard extends StatelessWidget {
  const _SwitcherCard({
    required this.isDarkMode,
    required this.title,
    required this.children,
  });

  final bool isDarkMode;

  final String title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Container(
      height: 220,
      width: 490,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: style.colors.onPrimary,
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Text(title, style: fonts.headlineLarge),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 490,
                height: 160,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: MediaQuery.sizeOf(context).width,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF142839)
                              : const Color(0xFFF4F9FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enabled',
                                style: fonts.titleMedium!.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              Text(
                                'Disabled',
                                style: fonts.titleMedium!.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                            ],
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

/// TODO: replace after merge #425
/// Custom-styled [ReactiveTextField] with [Switch.adaptive].
class SwitchField extends StatelessWidget {
  const SwitchField({
    super.key,
    this.text,
    this.value = false,
    this.onChanged,
  });

  /// Text of the [ReactiveTextField].
  final String? text;

  /// Indicator whether this switch is `on` or `off`.
  final bool value;

  /// Callback, called when the user toggles the switch `on` or `off`.
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Paddings.dense(
      Stack(
        alignment: Alignment.centerRight,
        children: [
          IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(text: text, editable: false),
              style: fonts.bodyMedium!.copyWith(color: style.colors.secondary),
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
                  data: ThemeData(platform: TargetPlatform.macOS),
                  child: Switch.adaptive(
                    activeColor: style.colors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: value,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
