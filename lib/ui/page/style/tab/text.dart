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

import '../widget/caption.dart';
import '/themes.dart';

/// Fonts tab view of the [Routes.style] page.
class FontStyleTabView extends StatelessWidget {
  const FontStyleTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return DefaultTextStyle.merge(
      maxLines: 1,
      child: ListView(
        controller: ScrollController(),
        padding: const EdgeInsets.all(8),
        children: [
          _font(
            'Largest of the display styles.',
            'displayLarge',
            fonts.displayLarge!,
          ),
          _font(
            'Middle size of the display styles.',
            'displayMedium',
            fonts.displayMedium!,
          ),
          _font(
            'Smallest of the display styles.',
            'displaySmall',
            fonts.displaySmall!,
          ),
          _font(
            'Largest of the headline styles.',
            'headlineLarge',
            fonts.headlineLarge!,
          ),
          _font(
            'Middle size of the headline styles.',
            'headlineMedium',
            fonts.headlineMedium!,
          ),
          _font(
            'Smallest of the headline styles.',
            'headlineSmall',
            fonts.headlineSmall!,
          ),
          _font(
            'Largest of the title styles.',
            'titleLarge',
            fonts.titleLarge!,
          ),
          _font(
            'Middle size of the title styles.',
            'titleMedium',
            fonts.titleMedium!,
          ),
          _font(
            'Smallest of the title styles.',
            'titleSmall',
            fonts.titleSmall!,
          ),
          _font(
            'Largest of the label styles.',
            'labelLarge',
            fonts.labelLarge!,
          ),
          _font(
            'Middle size of the label styles.',
            'labelMedium',
            fonts.labelMedium!,
          ),
          _font(
            'Smallest of the label styles.',
            'labelSmall',
            fonts.labelSmall!,
          ),
          _font(
            'Largest of the body styles.',
            'bodyLarge',
            fonts.bodyLarge!,
          ),
          _font(
            'Middle size of the body styles.',
            'bodyMedium',
            fonts.bodyMedium!,
          ),
          _font(
            'Smallest of the body styles.',
            'bodySmall',
            fonts.bodySmall!,
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _font(String sample, String title, TextStyle style) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            ListTile(
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 5),
                  Text(sample, style: style),
                ],
              ),
              trailing: Text(
                'Шрифт: ${style.fontSize} пт, цвет: ${style.color?.toHex()}',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
