import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/util/platform_utils.dart';
import 'app_bar.dart';
import 'navigation_bar.dart';

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
            top: CustomAppBar.height,
            bottom: bottomPadding ?? CustomNavigationBar.height + 5,
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: mediaQuery.padding.top + 5,
            bottom: mediaQuery.padding.bottom - CustomNavigationBar.height,
          ),
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
