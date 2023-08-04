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

import '/ui/page/style/page/multimedia/widget/animations.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/images.dart';
import 'widget/media_container.dart';

/// View of the [StyleTab.multimedia] page.
class MultimediaView extends StatelessWidget {
  const MultimediaView({super.key, this.inverted = false, this.dense = false});

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this view should be compact, meaning minimal [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> sounds = [
      ('chinese', 'Incoming call'),
      ('chinese-web', 'Web incoming call'),
      ('ringing', 'Outgoing call'),
      ('reconnect', 'Call reconnection'),
      ('message_sent', 'Sended message'),
      ('notification', 'Notification sound'),
      ('pop', 'Pop sound'),
    ];

    return ScrollableColumn(
      children: [
        const SizedBox(height: 16),
        const Header('Multimedia'),
        const SubHeader('Images'),
        ImagesColumn(inverted: inverted, dense: dense),
        const SubHeader('Animation'),
        AnimationsColumn(inverted: inverted, dense: dense),
        const SubHeader('Sound'),
        BuilderWrap(sounds, (e) => MediaContainer(e.$1, subtitle: e.$2)),
        const SizedBox(height: 16),
      ],
    );
  }
}
