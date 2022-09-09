import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';

class StyleView extends StatelessWidget {
  const StyleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: StyleController(),
      builder: (StyleController c) {
        return Container();
      },
    );
  }
}
