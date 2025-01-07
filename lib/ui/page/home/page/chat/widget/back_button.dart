// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';

/// Custom styled [BackButton].
class StyledBackButton extends StatelessWidget {
  const StyledBackButton({super.key, this.onPressed});

  /// Callback, called when this button is pressed.
  ///
  /// Invokes [Navigator.maybePop], if not specified.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    if (onPressed != null || ModalRoute.of(context)?.canPop == true) {
      return AnimatedButton(
        onPressed: onPressed ?? () => Navigator.maybePop(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: SvgIcon(SvgIcons.back),
        ),
      );
    } else {
      return const SizedBox(width: 30);
    }
  }
}
