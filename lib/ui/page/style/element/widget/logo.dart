import 'package:flutter/material.dart';

import '../../../../widget/svg/svg.dart';

class LogoView extends StatelessWidget {
  const LogoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Tooltip(
          message: 'Full-length Logo',
          child: SvgImage.asset(
            'assets/images/logo/logo0000.svg',
            height: 300,
            width: 300,
          ),
        ),
        const SizedBox(width: 100),
        Tooltip(
          message: 'Logo head',
          child: SvgImage.asset(
            'assets/images/logo/head0000.svg',
            height: 150,
            width: 150,
          ),
        ),
      ],
    );
  }
}
