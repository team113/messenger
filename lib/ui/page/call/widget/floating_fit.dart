import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// TODO:
/// 1. Primary view and floating secondary panel
/// 2. Primary/secondary should be reported back (via callbacks?), or use RxLists directly to manipulate them here?
/// 3. Clicking on secondary changes places with primary WITH ANIMATION
class FloatingFit<T> extends StatefulWidget {
  const FloatingFit({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final RxList<T> primary;
  final RxList<T> secondary;

  @override
  State<FloatingFit> createState() => _FloatingFitState();
}

class _FloatingFitState extends State<FloatingFit> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [],
    );
  }
}
