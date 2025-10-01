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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';

/// Card displaying [nominal] over a stylized asset.
class AmountTile extends StatelessWidget {
  const AmountTile({super.key, this.nominal = 0, this.height = 100});

  /// Amount to display over the asset.
  final num nominal;

  /// Height of the asset.
  final double height;

  /// Resolves a [Color] to display [AmountTile] with according to the [amount].
  static Color _colorFor(num amount) {
    return switch (amount) {
      // $0.01 - $4.99
      < 5 => Color(0xFFBFD5F0),

      // $5.00 - $9.99
      < 10 => Color(0xFFBFD5F0),

      // $10.00 - $24.99
      < 25 => Color(0xFF8FE3B9),

      // $25.00 - $49.99
      < 50 => Color(0xFFF99B9B),

      // $50.00 - $74.99
      < 75 => Color(0xFFF9D397),

      // $75.00 - $99.99
      < 100 => Color(0xFFAC9BF9),

      // $100.00
      (_) => Color(0xFF8CDBF8),
    };
  }

  /// Resolves a [Positioned] widget that should be displayed at [AmountTile]
  /// according to the [amount].
  static Positioned _positionedFor(num amount) {
    return switch (amount) {
      // $0
      <= 0 => Positioned(
        right: 0,
        bottom: 0,
        child: SvgImage.asset('assets/icons/nominal_5.svg'),
      ),

      // $0.01 - $9.99
      < 10 => Positioned(
        right: 0,
        bottom: 0,
        child: SvgImage.asset('assets/icons/nominal_5.svg'),
      ),

      // $10.00 - $24.99
      < 25 => Positioned(
        right: 0,
        bottom: 0,
        child: SvgImage.asset('assets/icons/nominal_10.svg'),
      ),

      // $25.00 - $49.99
      < 50 => Positioned(
        right: 0,
        bottom: 0,
        child: SvgImage.asset('assets/icons/nominal_25.svg'),
      ),

      // $50.00 - $74.99
      < 75 => Positioned(
        right: 0,
        bottom: 0,
        child: SvgImage.asset('assets/icons/nominal_50.svg'),
      ),

      // $75.00 - $99.99
      < 100 => Positioned(
        right: 0,
        bottom: 0,
        child: SvgImage.asset('assets/icons/nominal_75.svg'),
      ),

      // $100.00
      (_) => Positioned(
        right: 0,
        bottom: 0,
        child: SvgImage.asset('assets/icons/nominal_100.svg'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      decoration: BoxDecoration(
        color: _colorFor(nominal),
        borderRadius: BorderRadius.circular(10),
      ),
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _positionedFor(nominal),
          Positioned(
            left: 16,
            top: 16,
            child: Text(
              'currency_amount'.l10nfmt({'amount': nominal}),
              style: style.fonts.largest.bold.onPrimary.copyWith(
                fontSize: 36,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.3).round()),
                    offset: Offset(3, 3),
                    blurRadius: 1,
                    blurStyle: BlurStyle.outer,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgIcon(SvgIcons.priceSticker),
                Text(
                  '\$${(nominal * 1.299).toStringAsFixed(2)}',
                  style: style.fonts.small.regular.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
