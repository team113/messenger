import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

class ListDividerWidget extends StatelessWidget {
  const ListDividerWidget({
    super.key,
    required this.label,
    this.padding = defaultPadding,
  });

  final EdgeInsets padding;
  final String label;

  static const EdgeInsets defaultPadding = EdgeInsets.fromLTRB(56, 12, 0, 2);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: padding,
      child: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: style.fonts.big.regular.secondary,
          ),
        ),
      ),
    );
  }
}
