import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/util/platform_utils.dart';

class ListWrapper extends StatelessWidget {
  const ListWrapper({
    super.key,
    required BuildContext context,
    required this.child,
  }) : buildContext = context;

  final Widget child;

  final BuildContext buildContext;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = buildContext.mediaQuery;
    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(
          top: 60,
          bottom: 60,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(top: mediaQuery.padding.top + 5),
        height: buildContext.height - (context.isMobile ? 59 : 11),
        child: child,
      ),
    );
  }
}
