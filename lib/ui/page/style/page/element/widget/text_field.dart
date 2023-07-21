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
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/widget/allow_overflow.dart';

import '../../../../../../util/message_popup.dart';
import '../../../../../widget/svg/svg.dart';
import '../../../../../widget/text_field.dart';
import '../../../../../widget/widget_button.dart';
import '../../../../home/widget/sharable.dart';
import '../controller.dart';
import '/themes.dart';

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return GetBuilder(
        init: ElementsController(),
        builder: (ElementsController c) {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
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
                          child: SvgImage.asset(
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
                              style: fonts.labelSmall!.copyWith(
                                color: style.colors.primary,
                              ),
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
                          child: SvgImage.asset(
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
              Column(
                children: [
                  _CopyableTextFieldCard(
                    isHaveError: false,
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
                  _SharableFieldCard(
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
                          trailing: SvgImage.asset(
                            'assets/icons/share.svg',
                            width: 18,
                          ),
                          style: fonts.bodyMedium,
                          onTap: () {},
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

class _ErrorTextField extends StatelessWidget {
  const _ErrorTextField();

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

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
            style: fonts.labelMedium!.copyWith(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _ReactiveTextFieldCard extends StatelessWidget {
  const _ReactiveTextFieldCard({
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
      height: 520,
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
                                style: fonts.titleMedium!.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              Text(
                                'Typing',
                                style: fonts.titleMedium!.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              Text(
                                'Is loading',
                                style: fonts.titleMedium!.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              Text(
                                'Success',
                                style: fonts.titleMedium!.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Text(
                                  'Error',
                                  style: fonts.titleMedium!.copyWith(
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

class _CopyableTextFieldCard extends StatelessWidget {
  const _CopyableTextFieldCard({
    required this.isDarkMode,
    required this.title,
    required this.children,
    this.isHaveError = true,
  });

  final bool isDarkMode;

  final bool isHaveError;

  final String title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

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
            style: fonts.headlineLarge,
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
                                style: fonts.titleMedium!.copyWith(
                                  color: isDarkMode
                                      ? style.colors.onPrimary
                                      : const Color(0xFF1F3C5D),
                                ),
                              ),
                              if (isHaveError)
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

class _SharableFieldCard extends StatelessWidget {
  const _SharableFieldCard({
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
            style: fonts.headlineLarge,
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
