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
import 'package:messenger/ui/page/home/tab/chats/widget/unread_counter.dart';

import '/themes.dart';
import '/ui/widget/svg/svg.dart';

class ImagesView extends StatelessWidget {
  const ImagesView({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final (style, _) = Theme.of(context).styles;

    return Column(
      children: [
        Row(
          children: [
            Flexible(
              child: Tooltip(
                message: 'Dark background image',
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? style.colors.onPrimary
                        : const Color(0xFF1F3C5D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SvgImage.asset(
                        'assets/images/background_${isDarkMode ? 'dark' : 'light'}.svg',
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Tooltip(
              message: 'Full-length Logo',
              child: Column(
                children: [
                  Container(
                    height: 300,
                    width: 200,
                    decoration: BoxDecoration(
                      color: style.colors.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: SvgImage.asset('assets/images/logo/logo0000.svg'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Tooltip(
                  message: 'Logo head',
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: style.colors.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: SvgImage.asset('assets/images/logo/head0000.svg'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Tooltip(
                  message: 'Unread message counter icons',
                  child: Container(
                    width: 150,
                    height: 130,
                    decoration: BoxDecoration(
                      color: style.colors.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Wrap(
                        runAlignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 3,
                        runSpacing: 3,
                        alignment: WrapAlignment.center,
                        children: List.generate(20, (index) {
                          final int number = index + 1;

                          return UnreadCounter(number);
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
