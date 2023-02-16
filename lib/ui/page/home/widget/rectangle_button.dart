import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';

class RectangleButton extends StatelessWidget {
  const RectangleButton({
    super.key,
    this.selected = false,
    this.onPressed,
    this.label = '',
    this.trailingColor,
  });

  final String label;
  final bool selected;
  final void Function()? onPressed;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Material(
      borderRadius: BorderRadius.circular(10),
      color: selected
          ? style.cardSelectedColor.withOpacity(0.8)
          : Colors.white.darken(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: selected ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
              if (trailingColor == null)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selected
                        ? CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            radius: 12,
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          )
                        : const SizedBox(),
                  ),
                )
              else
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircleAvatar(
                    backgroundColor: trailingColor,
                    radius: 12,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : const SizedBox(key: Key('None')),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
