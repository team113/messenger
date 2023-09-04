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

import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';

class CountryCodeChipl extends StatelessWidget {
  final Country country;
  final bool showFlag;
  final bool showDialCode;
  final TextStyle textStyle;

  final double flagSize;
  final TextDirection? textDirection;

  CountryCodeChipl({
    Key? key,
    required IsoCode isoCode,
    this.textStyle = const TextStyle(),
    this.showFlag = true,
    this.showDialCode = true,
    this.flagSize = 16,
    this.textDirection,
  })  : country = Country(isoCode, ''),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
          onTap: () {
            print('I\'m clickable actually');
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFlag) ...[
                CircleFlag(
                  country.isoCode.name,
                  size: flagSize,
                ),
                const SizedBox(width: 8),
              ],
              if (showDialCode)
                Text(
                  country.displayCountryCode,
                  style: textStyle,
                  textDirection: textDirection,
                ),
            ],
          )),
    );
  }
}
