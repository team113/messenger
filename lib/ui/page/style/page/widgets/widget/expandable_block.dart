import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/util/platform_utils.dart';

class ExpandableBlock extends StatefulWidget {
  const ExpandableBlock({
    super.key,
    this.headline,
    this.preview,
    this.take = 11,
    this.children = const [],
  });

  final String? headline;
  final List<Widget>? preview;
  final int take;
  final List<Widget> children;

  @override
  State<ExpandableBlock> createState() => _ExpandableBlockState();
}

class _ExpandableBlockState extends State<ExpandableBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Stack(
      children: [
        Block(
          headline: widget.headline,
          underline: AnimatedButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: style.colors.primary,
            ),
          ),
          children: [
            const SizedBox(height: 32),
            ..._expanded
                ? widget.children
                : (widget.preview ??
                    (widget.children.take(widget.take).toList())),
            const SizedBox(height: 32),
          ],
        ),
      ],
    );
  }
}
