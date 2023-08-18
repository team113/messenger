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

import '../controller.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/widget/sharable.dart';
import '/ui/widget/allow_overflow.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';

/// View of all [TextField] elements in app.
class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({super.key, required this.isDarkMode});

  /// Indicator whether this page is in dark mode.
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
        init: ElementsController(),
        builder: (ElementsController c) {
          return Column(
            children: [
              _ReactiveTextFieldCard(
                isDarkMode: isDarkMode,
                title: 'ReactiveTextField',
                children: [
                  SizedBox(
                    width: 320,
                    height: 55,
                    child: ReactiveTextField(
                      state: c.name,
                      onSuffixPressed: () => MessagePopup.success('Copied'),
                      label: 'Name',
                      hint: 'Your publicly visible name',
                      filled: true,
                      trailing: Transform.translate(
                        offset: const Offset(0, -1),
                        child: Transform.scale(
                          scale: 1.15,
                          child: const SvgImage.asset(
                            'assets/icons/copy.svg',
                            height: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    height: 55,
                    child: ReactiveTextField(
                      state: c.typing,
                      label: 'Name',
                      hint: 'Your publicly visible name',
                      filled: true,
                      trailing: Transform.translate(
                        offset: const Offset(0, -1),
                        child: WidgetButton(
                          child: AllowOverflow(
                            child: Text(
                              'Save',
                              style: style.fonts.labelSmallPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    height: 55,
                    child: ReactiveTextField(
                      state: c.loading,
                      label: 'Name',
                      hint: 'Your publicly visible name',
                      filled: true,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    height: 55,
                    child: ReactiveTextField(
                      state: c.success,
                      label: 'Name',
                      hint: 'Your publicly visible name',
                      filled: true,
                      trailing: Transform.translate(
                        offset: const Offset(0, -1),
                        child: Transform.scale(
                          scale: 1.15,
                          child: const SvgImage.asset(
                            'assets/icons/copy.svg',
                            height: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 320,
                    height: 85,
                    child: _ErrorTextField(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _CopyableTextFieldCard(
                    isDarkMode: isDarkMode,
                    title: 'CopyableTextField',
                    children: [
                      SizedBox(
                        width: 320,
                        height: 55,
                        child: CopyableTextField(
                          state: TextFieldState(
                            text: '8642 4348 7885 5329',
                            editable: false,
                          ),
                          label: 'Gapopa ID',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SharableTextFieldCard(
                    isDarkMode: isDarkMode,
                    title: 'SharableField',
                    children: [
                      SizedBox(
                        width: 320,
                        height: 51,
                        child: SharableTextField(
                          text: '8642 4348 7885 5329',
                          label: 'Gapopa ID',
                          share: 'Gapopa ID: 8642 4348 7885 5329',
                          trailing: const SvgImage.asset(
                            'assets/icons/share.svg',
                            width: 18,
                          ),
                          style: style.fonts.bodyMedium,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          );
        });
  }
}

/// Error view of the [ReactiveTextField].
class _ErrorTextField extends StatelessWidget {
  const _ErrorTextField();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          cursorColor: style.colors.onBackground,
          decoration: InputDecoration(
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Icon(
                Icons.error,
                size: 18,
                color: style.colors.dangerColor,
              ),
            ),
            hintText: 'Your publicly visible name',
            labelText: 'Name',
            fillColor: style.colors.onPrimary,
            filled: true,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.0),
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: style.colors.dangerColor, width: 2),
              borderRadius: const BorderRadius.all(Radius.circular(30)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, left: 16),
          child: Text(
            'Incorrect input',
            style: style.fonts.labelMedium.copyWith(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

/// [ReactiveTextField]'s background
class _ReactiveTextFieldCard extends StatelessWidget {
  const _ReactiveTextFieldCard({
    required this.isDarkMode,
    required this.title,
    required this.children,
  });

  /// Indicator whether this page is in dark mode.
  final bool isDarkMode;

  /// Header of this [_ReactiveTextFieldCard].
  final String title;

  /// [Widget]s to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      height: 520,
      width: 490,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: style.colors.onPrimary,
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Text(title, style: style.fonts.headlineLarge),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 490,
                height: 455,
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
                                'Default',
                                style: style.fonts.titleMedium.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              Text(
                                'Typing',
                                style: style.fonts.titleMedium.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              Text(
                                'Is loading',
                                style: style.fonts.titleMedium.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              Text(
                                'Success',
                                style: style.fonts.titleMedium.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Text(
                                  'Error',
                                  style: style.fonts.titleMedium.copyWith(
                                    color: isDarkMode
                                        ? style.colors.onPrimary
                                        : const Color(0xFF1F3C5D),
                                  ),
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

/// [CopyableTextField]'s background.
class _CopyableTextFieldCard extends StatelessWidget {
  const _CopyableTextFieldCard({
    required this.isDarkMode,
    required this.title,
    required this.children,
  });

  /// Indicator whether this page is in dark mode.
  final bool isDarkMode;

  /// Header of this [_CopyableTextFieldCard].
  final String title;

  /// [Widget]s to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      height: 150,
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
            style: style.fonts.headlineLarge,
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 490,
                height: 85,
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
                                'Default',
                                style: style.fonts.titleMedium.copyWith(
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

/// [SharableTextField]'s background.
class _SharableTextFieldCard extends StatelessWidget {
  const _SharableTextFieldCard({
    required this.isDarkMode,
    required this.title,
    required this.children,
  });

  /// Indicator whether this page is in dark mode.
  final bool isDarkMode;

  /// Header of this [_SharableTextFieldCard].
  final String title;

  /// [Widget]s to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      height: 150,
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
            style: style.fonts.headlineLarge,
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 490,
                height: 85,
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
                                'Default',
                                style: style.fonts.titleMedium.copyWith(
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
