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
    this.padding = const EdgeInsets.fromLTRB(32, 16, 32, 16),
    this.children = const [],
  });

  final String? headline;
  final List<Widget>? preview;
  final int take;
  final EdgeInsets padding;
  final List<Widget> children;

  @override
  State<ExpandableBlock> createState() => _ExpandableBlockState();
}

class _ExpandableBlockState extends State<ExpandableBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Stack(
      children: [
        Block(
          headline: widget.headline,
          padding: widget.padding,
          // underline: AnimatedButton(
          //   onPressed: () => setState(() => _expanded = !_expanded),
          //   child: Icon(
          //     _expanded ? Icons.expand_less : Icons.expand_more,
          //     color: style.colors.primary,
          //   ),
          // ),
          fade: !_expanded,
          expanded: [
            ..._expanded ? widget.children.skip(widget.take).toList() : [],
            const SizedBox(height: 32)
          ],
          children: [
            const SizedBox(height: 32),
            ...(widget.preview ?? (widget.children.take(widget.take).toList())),
          ],
        ),
      ],
    );
  }
}
