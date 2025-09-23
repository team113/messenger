import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/widget_button.dart';
import '/util/global_key.dart';
import 'controller.dart';

class AccountsOverlayView extends StatelessWidget {
  const AccountsOverlayView({super.key, required this.avatarKey});

  final GlobalKey avatarKey;

  static Future<T?> show<T>(
    BuildContext context, {
    required GlobalKey key,
  }) async {
    final style = Theme.of(context).style;

    final route = RawDialogRoute<T>(
      barrierColor: style.barrierColor,
      barrierDismissible: true,
      pageBuilder: (_, _, _) {
        final Widget body = AccountsOverlayView(avatarKey: key);
        return body;
      },
      fullscreenDialog: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, Animation<double> animation, _, Widget child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: animation.value * 7,
                sigmaY: animation.value * 7,
              ),
              child: child,
            );
          },
          child: child,
        );
      },
    );

    router.obscuring.add(route);

    try {
      return await Navigator.of(context, rootNavigator: true).push<T>(route);
    } finally {
      router.obscuring.remove(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: AccountsOverlayController(Get.find()),
      builder: (AccountsOverlayController c) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final Rect bounds = avatarKey.globalPaintBounds ?? Rect.zero;

            return Stack(
              children: [
                WidgetButton(
                  onPressed: Navigator.of(context).pop,
                  child: SizedBox.expand(),
                ),
                Positioned(
                  left: bounds.left - 4,
                  top: bounds.top - 4,
                  width: bounds.width + 8,
                  height: bounds.height + 8,
                  child: Obx(() {
                    return Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: AvatarWidget.fromMyUser(
                        c.myUser.value,
                        radius: AvatarRadius.normal,
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
