import 'package:flutter/material.dart';

import '../conditional_backdrop.dart';

/// [Container] with a specific alignment on the screen.
///
/// It is used to visualize the possible locations for dropping an item
/// during drag-and-drop operations.
class PossibleContainer extends StatelessWidget {
  const PossibleContainer(
    this.alignment, {
    super.key,
  });

  /// Variable determines the alignment of the [PossibleContainer]
  /// on the screen.
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    if (alignment == null) {
      return const SizedBox();
    }

    final double width =
        alignment == Alignment.topCenter || alignment == Alignment.bottomCenter
            ? double.infinity
            : 10;

    final double height =
        alignment == Alignment.topCenter || alignment == Alignment.bottomCenter
            ? 10
            : double.infinity;

    return Align(
      alignment: alignment!,
      child: ConditionalBackdropFilter(
        child: Container(
          height: height,
          width: width,
          color: const Color(0x4D165084),
        ),
      ),
    );
  }
}
