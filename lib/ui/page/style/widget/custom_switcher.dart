// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
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
import 'package:messenger/themes.dart';

///
class CustomSwitcher extends StatefulWidget {
  const CustomSwitcher({super.key, this.onChanged});

//// Called when the user toggles the switch on or off.
  final ValueChanged<bool>? onChanged;

  @override
  State<CustomSwitcher> createState() => _CustomSwitcherState();
}

///
class _CustomSwitcherState extends State<CustomSwitcher>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] of this [CustomSwitcher].
  late AnimationController _animationController;

  ///
  late Animation<double> _animation;

  ///
  bool _value = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleValue() {
    setState(() {
      _value = !_value;
      widget.onChanged?.call(_value);
      _value ? _animationController.forward() : _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GestureDetector(
      onTap: _toggleValue,
      child: Container(
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: _value ? const Color(0xFF1F3C5D) : Colors.orange[300],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value * 20, 0),
                child: child,
              );
            },
            child: Row(
              children: [
                Container(
                  width: 22.0,
                  height: 22.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: style.colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
