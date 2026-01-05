// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
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

import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/domain/model/country.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/tab/wallet/select_country/view.dart';
import '/ui/widget/svg/svg.dart';
import 'field_button.dart';

/// [FieldButton] displaying the provided [IsoCode] as a country invoking
/// [SelectCountryView] when pressed.
class CountryButton extends StatelessWidget {
  const CountryButton({
    super.key,
    this.country,
    this.onCode,
    this.available = const {},
    this.restricted = const {},
    this.error = false,
  });

  /// [IsoCode] of the country to display.
  final IsoCode? country;

  /// Callback, called with the result of [SelectCountryView].
  final void Function(IsoCode)? onCode;

  /// [IsoCode]s available in the [SelectCountryView].
  final Set<IsoCode> available;

  /// [IsoCode]s restricted in the [SelectCountryView].
  final Set<IsoCode> restricted;

  /// Indicator whether this button should display an error.
  final bool error;

  @override
  Widget build(BuildContext context) {
    return FieldButton(
      headline: Text('label_country'.l10n),
      onPressed: onCode == null
          ? null
          : () async {
              final result = await SelectCountryView.show(
                context,
                available: available,
                restricted: restricted,
              );

              if (result != null) {
                onCode?.call(result);
              }
            },
      error: error,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (country != null) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: ClipOval(
                child: SvgImage.asset(
                  'assets/images/country/${country?.name.toLowerCase()}.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              country == null
                  ? 'label_choose_country'.l10n
                  : 'country_${country?.name.toLowerCase()}'.l10n,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clickable flag of the provided [country] invoking [SelectCountryView] when
/// pressed.
class CountryFlag extends StatelessWidget {
  const CountryFlag({
    super.key,
    this.country,
    this.onCode,
    this.available = const {},
    this.restricted = const {},
    this.error = false,
  });

  /// [IsoCode] of the country to display.
  final IsoCode? country;

  /// Callback, called with the result of [SelectCountryView].
  final void Function(IsoCode)? onCode;

  /// [IsoCode]s available in the [SelectCountryView].
  final Set<IsoCode> available;

  /// [IsoCode]s restricted in the [SelectCountryView].
  final Set<IsoCode> restricted;

  /// Indicator whether this button should display an error.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final TextStyle bigWithShadows = style.fonts.big.regular.onPrimary.copyWith(
      shadows: [
        Shadow(
          color: style.colors.onBackgroundOpacity50,
          blurRadius: 1,
          offset: Offset(-1, 1),
        ),
        Shadow(
          color: style.colors.acceptShadow,
          blurRadius: 1,
          offset: Offset(1, 1),
        ),
        Shadow(
          color: style.colors.acceptShadow,
          blurRadius: 1,
          offset: Offset(-0.5, -0.5),
        ),
      ],
    );

    return WidgetButton(
      onPressed: () async {
        final result = await SelectCountryView.show(
          context,
          available: available,
          restricted: restricted,
        );

        if (result != null) {
          onCode?.call(result);
        }
      },
      child: Container(
        width: 164,
        height: 122,
        decoration: BoxDecoration(
          color: country == null ? style.colors.secondaryLight : null,
          border: Border.all(color: style.colors.secondary, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (country != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SvgImage.asset(
                  'assets/images/country/${country?.name.toLowerCase()}.svg',
                  fit: BoxFit.cover,
                ),
              ),
            Center(
              child: Text(
                country == null
                    ? 'label_choose_country'.l10n
                    : 'country_${country?.name.toLowerCase()}'.l10n,
                textAlign: TextAlign.center,
                style: bigWithShadows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
