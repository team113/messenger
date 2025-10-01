// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '../widget/headline.dart';
import '/config.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Routes.style] images section.
class ImagesSection {
  /// Returns the [Widget]s of this [ImagesSection].
  static List<Widget> build() {
    return [
      Headline(
        headline: 'background_light.svg',
        subtitle: _downloadButton('background_light.svg'),
        child: const SvgImage.asset(
          'assets/images/background_light.svg',
          height: 300,
          fit: BoxFit.cover,
        ),
      ),
      Headline(
        headline: 'background_dark.svg',
        subtitle: _downloadButton('background_dark.svg'),
        child: const SvgImage.asset(
          'assets/images/background_dark.svg',
          height: 300,
          fit: BoxFit.cover,
        ),
      ),
    ];
  }

  /// Returns the button downloading the provided [asset].
  static Widget _downloadButton(String asset, {String? prefix}) {
    final style = Theme.of(router.context!).style;

    return SelectionContainer.disabled(
      child: WidgetButton(
        onPressed: () async {
          final file = await PlatformUtils.saveTo(
            '${Config.origin}/assets/assets/icons$prefix/$asset',
          );
          if (file != null) {
            MessagePopup.success('$asset downloaded');
          }
        },
        child: Text('Download', style: style.fonts.smaller.regular.primary),
      ),
    );
  }
}
