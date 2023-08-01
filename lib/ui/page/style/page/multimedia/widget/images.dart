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

import '/themes.dart';
import '/ui/page/home/tab/chats/widget/unread_counter.dart';
import '/ui/widget/svg/svg.dart';

///
class ImagesColumn extends StatelessWidget {
  const ImagesColumn({super.key, this.inverted = false, this.dense = false});

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this [ImagesColumn] should be compact, meaning
  /// minimal [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (style, _) = Theme.of(context).styles;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color:
                    inverted ? style.colors.onPrimary : const Color(0xFF1F3C5D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SvgImage.asset(
                    'assets/images/background_${inverted ? 'dark' : 'light'}.svg',
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Container(
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
            const SizedBox(height: 16),
            Container(
              width: 150,
              height: 130,
              decoration: BoxDecoration(
                color: style.colors.onPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: List.generate(20, (index) {
                    final int number = index + 1;

                    return UnreadCounter(number);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
