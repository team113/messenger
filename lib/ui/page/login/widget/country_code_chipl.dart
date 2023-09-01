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
    return GestureDetector(
        onTap: () {},
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
            const SizedBox(width: 8),
          ],
        ));
  }
}
