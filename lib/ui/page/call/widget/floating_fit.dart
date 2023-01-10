// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

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
