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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/line_divider.dart';

/// Description about monolog features
class MonologDescription extends StatelessWidget {
  const MonologDescription({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: <Widget>[
        Text(
          'label_chat_with_yourself'.l10n,
          style: style.fonts.small.regular.secondary,
        ),
        const SizedBox(height: 24),
        LineDivider('label_monolog_features'.l10n),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'label_monolog_features_description'.l10n,
            style: style.fonts.small.regular.secondary,
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }
}
