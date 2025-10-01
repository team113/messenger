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

import '/ui/widget/svg/svg.dart';

/// Widget displaying [SvgIcons.partner] with the provided [balance].
class PartnerIcon extends StatelessWidget {
  const PartnerIcon({super.key, this.balance = 0, this.visible = true});

  /// Number to display over the icon.
  final double balance;

  /// Indicator whether [balance] should be visible at all.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final Widget icon;
    final Widget overlay;

    if (visible) {
      if (balance > 0) {
        icon = const SvgIcon(SvgIcons.partnerEmpty);

        overlay = Transform.translate(
          offset: Offset(0, balance > 0 ? 2 : 0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
            child: FittedBox(
              child: Text(
                _balance(balance),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
        );
      } else {
        icon = const SvgIcon(SvgIcons.partner);
        overlay = const SizedBox();
      }
    } else {
      icon = const SvgIcon(SvgIcons.partner);
      overlay = const SizedBox();
    }

    return Transform.translate(
      offset: Offset(0, -1 + balance > 0 ? -2 : 0),
      child: Stack(
        children: [
          icon,
          Positioned.fill(child: Center(child: overlay)),
        ],
      ),
    );
  }

  /// Returns a [String] shrinking down the [balance] to append `m` or `k`.
  ///
  /// For example:
  /// - 1 000.0 -> "1k"
  /// - 92 000.0 -> "92k"
  /// - 52 100 000.0 -> "52M"
  String _balance(double balance) {
    if (balance < 1000) {
      return balance.toInt().toString();
    } else if (balance < 1000000) {
      return '${balance ~/ 1000}k';
    } else {
      return '${balance ~/ 1000000}m';
    }
  }
}
