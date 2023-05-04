import 'package:flutter/material.dart';
import 'package:messenger/util/web/web_utils.dart';

import '../../../../../themes.dart';

/// [Scaffold] widget for desktop which combines all stackable content.
class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({
    super.key,
    required this.content,
    required this.ui,
    this.onPanUpdate,
    this.titleBar,
  });

  /// List of [Widget] that make up the stackable content.
  final List<Widget> content;

  /// List of [Widget] that make up the user interface.
  final List<Widget> ui;

  /// [Widget] that represents the title bar.
  ///
  /// It is displayed at the top of the scaffold if [WebUtils.isPopup] is false.
  final Widget? titleBar;

  /// Callback [Function] that handles drag update events.
  final void Function(DragUpdateDetails)? onPanUpdate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!WebUtils.isPopup)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: onPanUpdate,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    CustomBoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      blurStyle: BlurStyle.outer,
                    )
                  ],
                ),
                child: titleBar,
              ),
            ),
          Expanded(child: Stack(children: [...content, ...ui])),
        ],
      ),
    );
  }
}
