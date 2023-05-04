import 'package:flutter/material.dart';

/// [Scaffold] widget which combines all stackable content.
class MobileScaffold extends StatelessWidget {
  const MobileScaffold(
    this.content,
    this.ui,
    this.overlay, {
    super.key,
  });

  /// List of [Widget] that make up the stackable content.
  final List<Widget> content;

  /// List of [Widget] that make up the user interface.
  final List<Widget> ui;

  /// List of [Widget] which will be displayed on top of the main content
  /// on the screen.
  final List<Widget> overlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF444444),
      body: Stack(
        children: [
          ...content,
          const MouseRegion(
            opaque: false,
            cursor: SystemMouseCursors.basic,
          ),
          ...ui.map((e) => ClipRect(child: e)),
          ...overlay,
        ],
      ),
    );
  }
}
