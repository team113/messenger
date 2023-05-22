import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/dock.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/controller.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/widget_button.dart';

class MessageFieldOverlay extends StatelessWidget {
  const MessageFieldOverlay(this.c, {super.key});

  final MessageFieldController c;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return LayoutBuilder(builder: (context, constraints) {
      Rect? rect = c.globalKey.globalPaintBounds;

      double left = rect?.left ?? 0;
      double right = rect == null ? 0 : (constraints.maxWidth - rect.right);
      double bottom = rect == null
          ? 0
          : (constraints.maxHeight - rect.bottom + rect.height);

      return Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: (_) {
              c.entry?.remove();
              c.entry = null;
            },
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: Colors.transparent,
            ),
          ),
          Positioned(
            left: left,
            right: right,
            // right: 0,
            bottom: bottom + 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                // color: candidate.any((e) => e?.c == c)
                //     ? const Color(0xE0165084)
                //     : const Color(0x9D165084),
                borderRadius: style.cardRadius,
                boxShadow: [
                  CustomBoxShadow(
                    blurRadius: 8,
                    color: style.colors.onBackgroundOpacity13,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 35),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.start,
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 21,
                      children: c.panel.map((e) {
                        return SizedBox(
                          width: 100,
                          height: 100,
                          child: Column(
                            children: [
                              DelayedDraggable(
                                feedback: Transform.translate(
                                  offset: const Offset(
                                    -60 / 2,
                                    -60 / 2,
                                  ),
                                  child: SizedBox(
                                    height: 60,
                                    width: 60,
                                    child: e.build(),
                                  ),
                                ),
                                data: e,
                                // onDragStarted: () {
                                //   c.showDragAndDropButtonsHint = false;
                                //   c.draggedButton.value = e;
                                // },
                                // onDragCompleted: () =>
                                //     c.draggedButton.value = null,
                                // onDragEnd: (_) => c.draggedButton.value = null,
                                // onDraggableCanceled: (_, __) =>
                                //     c.draggedButton.value = null,
                                // maxSimultaneousDrags: e.isRemovable ? null : 0,
                                dragAnchorStrategy: pointerDragAnchorStrategy,
                                child: e.build(hinted: false),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                e.hint,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
