import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messenger/themes.dart';

class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({
    super.key,
    this.color,
    this.backgroundColor,
    this.valueColor,
    this.strokeWidth = 2.0,
    this.value,
  });

  final double? value;
  final Color? backgroundColor;
  final Color? color;
  final Animation<Color?>? valueColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    // if (value != null) {
    return CircularProgressIndicator(
      value: value,
      color: color ?? Theme.of(context).colorScheme.secondary,
      backgroundColor: backgroundColor,
      valueColor: valueColor,
      strokeWidth: strokeWidth,
    );
    // }

    // return LoadingAnimationWidget.flickr(
    //   leftDotColor: Theme.of(context).colorScheme.secondary,
    //   rightDotColor: Theme.of(context).colorScheme.secondary,
    //   size: 54,
    // );

    // return LoadingAnimationWidget.threeRotatingDots(
    //   color: Theme.of(context).colorScheme.secondary,
    //   size: 40,
    // );
  }
}
