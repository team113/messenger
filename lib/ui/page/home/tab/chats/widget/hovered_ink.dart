import 'package:flutter/material.dart';

class InkWellWithHover extends StatefulWidget {
  const InkWellWithHover({
    Key? key,
    this.borderRadius,
    this.hoverColor,
    this.hoveredBorder,
    this.unhoveredBorder,
    this.onTap,
    this.color,
    required this.child,
  }) : super(key: key);

  final void Function()? onTap;
  final BorderRadius? borderRadius;
  final Color? hoverColor;
  final Color? color;
  final Border? hoveredBorder;
  final Border? unhoveredBorder;
  final Widget child;

  @override
  State<InkWellWithHover> createState() => _InkWellWithHoverState();
}

class _InkWellWithHoverState extends State<InkWellWithHover> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: isHovered ? widget.hoveredBorder : widget.unhoveredBorder,
        color: Colors.transparent,
      ),
      child: Material(
        type: MaterialType.card,
        borderRadius: widget.borderRadius,
        color: widget.color,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onHover: (b) => setState(() => isHovered = b),
          hoverColor: widget.hoverColor,
          child: widget.child,
        ),
      ),
    );
  }
}
