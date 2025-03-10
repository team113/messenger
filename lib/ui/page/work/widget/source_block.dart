// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/widget/widget_button.dart';

/// [Block] listing the source code links.
class SourceCodeBlock extends StatelessWidget {
  const SourceCodeBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    // Returns a [Text] wrapped in a [WidgetButton] invoking [onPressed].
    Widget button({required String label, void Function()? onPressed}) {
      return WidgetButton(
        onPressed: onPressed,
        child: Text(label, style: style.fonts.normal.regular.primary),
      );
    }

    return Block(
      title: 'label_source_code'.l10n,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        button(
          label: '- GitHub repository',
          onPressed:
              () => launchUrlString('https://github.com/team113/messenger'),
        ),
        Row(
          children: [
            button(
              label: '- Styles page',
              onPressed: () => router.style(push: true),
            ),
            const SizedBox(width: 4),
            Text('(', style: style.fonts.normal.regular.onBackground),
            button(
              label: 'btn_open_separately'.l10n,
              onPressed:
                  () => launchUrlString('${Config.origin}${Routes.style}'),
            ),
            Text(')', style: style.fonts.normal.regular.onBackground),
          ],
        ),
        button(
          label: '- GraphQL API',
          onPressed:
              () => launchUrlString(
                'https://messenger.soc.stg.t11913.org/api/graphql/playground',
              ),
        ),
      ],
    );
  }
}
