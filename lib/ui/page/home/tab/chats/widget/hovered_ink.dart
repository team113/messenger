import 'package:flutter/material.dart';

class InkWellWithHover extends StatefulWidget {
  const InkWellWithHover({
    Key? key,
    this.borderRadius,
    this.selectedHoverColor,
    this.unselectedHoverColor,
    this.hoveredBorder,
    this.unhoveredBorder,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
    required this.child,
  }) : super(key: key);

  final void Function()? onTap;
  final BorderRadius? borderRadius;
  final Color? selectedHoverColor;
  final Color? unselectedHoverColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Border? hoveredBorder;
  final Border? unhoveredBorder;
  final Widget child;
  final bool isSelected;

  @override
  State<InkWellWithHover> createState() => _InkWellWithHoverState();
}

class _InkWellWithHoverState extends State<InkWellWithHover> {
  bool isHovered = false;
  late bool isSelected;

  @override
  void initState() {
    isSelected = widget.isSelected;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant InkWellWithHover oldWidget) {
    isSelected = widget.isSelected;
    super.didUpdateWidget(oldWidget);
  }

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
        color: isHovered
            ? isSelected
                ? widget.selectedHoverColor
                : widget.unselectedHoverColor
            : isSelected
                ? widget.selectedColor
                : widget.unselectedColor,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: () {
            setState(() {
              isSelected = true;
            });

            widget.onTap?.call();
          },
          onHover: (b) => setState(() => isHovered = b),
          hoverColor: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}
