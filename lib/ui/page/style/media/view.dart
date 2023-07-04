import 'package:flutter/material.dart';

import '../element/widget/header.dart';
import 'widget/animation.dart';
import 'widget/images.dart';
import 'widget/sounds.dart';

class MultimediaView extends StatelessWidget {
  const MultimediaView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Header(label: 'Multimedia'),
        SmallHeader(label: 'Images'),
        ImagesView(),
        Divider(),
        SmallHeader(label: 'Animation'),
        AnimationStyleWidget(),
        Divider(),
        SmallHeader(label: 'Sound'),
        SoundsWidget(),
        Divider(),
      ],
    );
  }
}
