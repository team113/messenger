import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '/themes.dart';

/// [SlidableAction] appearing with fade in animation.
class FadingSlidableAction extends StatelessWidget {
  const FadingSlidableAction({
    super.key,
    required this.icon,
    required this.text,
    this.onPressed,
  });

  /// [Widget] to display as the leading icon of this action.
  final Widget icon;

  /// Text of this action.
  final String text;

  /// Callback, called when this [FadingSlidableAction] is invoked.
  final void Function(BuildContext context)? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Expanded(
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 3, 3, 3),
          child: LayoutBuilder(builder: (context, constraints) {
            return OutlinedButton(
              onPressed: () {
                onPressed?.call(context);
                Slidable.of(context)?.close();
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: style.colors.danger,
                foregroundColor: style.colors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: style.cardRadius),
                side: BorderSide.none,
              ),
              child: Opacity(
                opacity: constraints.maxWidth > 50
                    ? 1
                    : constraints.maxWidth > 25
                        ? (constraints.maxWidth - 25) / 25
                        : 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(height: 8),
                    Text(text, maxLines: 1),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
