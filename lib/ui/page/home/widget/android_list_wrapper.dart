import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/util/platform_utils.dart';

class ListWrapper extends StatelessWidget {
  const ListWrapper({
    super.key,
    required BuildContext context,
    required this.child,
    this.bottomPadding = 60,
  }) : buildContext = context;

  final Widget child;

  final BuildContext buildContext;

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = buildContext.mediaQuery;
    print(buildContext.mediaQueryViewPadding);
    print(buildContext.mediaQuery);
    print(buildContext.mediaQueryViewInsets);
    print(buildContext.mediaQuerySize);
    print(buildContext.mediaQueryPadding);
    print(buildContext.height);
    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(
          top: 60,
          bottom: mediaQuery.padding.bottom,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(top: mediaQuery.padding.top + 5, bottom: 5),
        height: buildContext.height -
            (context.isMobile ? mediaQuery.padding.bottom + 5 : 11),
        child: child,
      ),
    );
  }
}
