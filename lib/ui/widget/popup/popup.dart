import 'package:flutter/cupertino.dart' show kCupertinoModalBarrierColor;
import 'package:flutter/material.dart';
import 'package:messenger/util/platform_utils.dart';

abstract class Popup {
  static Future<T?> show<T>(BuildContext context, Widget child,
      {double contentMaxWidth = 300,
      double layoutMaxWidth = 420,
      double verticalPadding = 10}) {
    if (context.isMobile) {
      return showModalBottomSheet(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: child,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    } else {
      return showDialog(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        builder: (context) => Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: layoutMaxWidth),
                padding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: verticalPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        InkResponse(
                          onTap: Navigator.of(context).pop,
                          radius: 11,
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xBB818181),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Center(child: child),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
