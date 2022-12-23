import 'package:flutter/material.dart';

class SwappableFit extends StatefulWidget {
  const SwappableFit({
    super.key,
    this.children = const [],
  });

  final List<Widget> children;

  @override
  State<SwappableFit> createState() => _SwappableFitState();
}

class _SwappableFitState extends State<SwappableFit> {
  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox();
    }

    return Container();
  }
}
