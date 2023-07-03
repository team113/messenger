import 'package:flutter/material.dart';

import '../element/widget/header.dart';
import 'widget/family.dart';
import 'widget/style.dart';

class FontsView extends StatelessWidget {
  const FontsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Header(label: 'Typography'),
        SmallHeader(label: 'Font'),
        FontFamiliesView(),
        Divider(),
        SmallHeader(label: 'Styles'),
        FontStyleView(),
        Divider(),
      ],
    );
  }
}
