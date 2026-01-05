// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/session.dart';
import '/domain/repository/session.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/session/controller.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/tab/chats/widget/periodic_builder.dart';
import '/ui/widget/svg/svg.dart';

/// Visual representation of a [RxSession].
class SessionTileWidget extends StatelessWidget {
  const SessionTileWidget(this.rxSession, {super.key, this.isCurrent = false});

  /// [RxSession] to display.
  final RxSession rxSession;

  /// Indicator whether the [rxSession] should be displayed as current.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Session session = rxSession.session.value;
      final IpGeoLocation? geo = rxSession.geo.value;

      return Container(
        key: Key(isCurrent ? 'CurrentSession' : 'Session_${session.id}'),
        decoration: BoxDecoration(
          border: style.cardBorder,
          borderRadius: style.cardRadius,
          color: style.colors.onPrimary,
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: style.colors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgIcon(switch (session.userAgent.system) {
                  'macOS' => SvgIcons.userAgentMacOs,
                  'iOS' => SvgIcons.userAgentIOs,
                  'iPadOS' => SvgIcons.userAgentIOs,
                  'watchOS' => SvgIcons.userAgentIOs,
                  'Android' => SvgIcons.userAgentAndroid,
                  'Linux' => SvgIcons.userAgentLinux,
                  'Windows' => SvgIcons.userAgentWindows,
                  (_) => SvgIcons.menuSupport,
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.userAgent.system,
                    style: style.fonts.medium.regular.onBackground,
                  ),
                  SizedBox(height: 4),
                  Text(
                    session.userAgent.application,
                    style: style.fonts.small.regular.onBackground,
                  ),
                  SizedBox(height: 4),
                  PeriodicBuilder(
                    period: Duration(minutes: 1),
                    builder: (_) {
                      return Text(
                        'label_city_country_activated_at'.l10nfmt({
                          'city': geo?.city ?? '',
                          'country': geo?.country ?? '',
                          'at': session.lastActivatedAt.val.toDifferenceAgo(),
                        }),
                        style: style.fonts.small.regular.secondary,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
