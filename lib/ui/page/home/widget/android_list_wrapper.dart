import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/util/platform_utils.dart';

class ListWrapper extends StatelessWidget {
  const ListWrapper({
    super.key,
    required BuildContext context,
    required this.child,
    this.bottomPadding,
  }) : buildContext = context;

  final Widget child;

  final BuildContext buildContext;

  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = buildContext.mediaQuery;
    if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
      return MediaQuery(
        data: mediaQuery.copyWith(
          padding: mediaQuery.padding.copyWith(
            top: 60,
            bottom: bottomPadding ?? 61,
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(
              top: mediaQuery.padding.top + 5,
              bottom: mediaQuery.padding.bottom - 61 + 5),
          height: buildContext.height,
          child: child,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: child,
      );
    }
  }
}
