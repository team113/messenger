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
import 'package:messenger/util/web/web_utils.dart';

import '/themes.dart';

/// [Scaffold] widget for desktop which combines all stackable content.
class StackableScaffold extends StatelessWidget {
  const StackableScaffold({
    super.key,
    required this.content,
    required this.ui,
    this.onPanUpdate,
    this.titleBar,
  });

  /// List of [Widget] that make up the stackable content.
  final List<Widget> content;

  /// List of [Widget] that make up the user interface.
  final List<Widget> ui;

  /// [Widget] that represents the title bar.
  ///
  /// It is displayed at the top of the scaffold if [WebUtils.isPopup] is false.
  final Widget? titleBar;

  /// Callback [Function] that handles drag update events.
  final void Function(DragUpdateDetails)? onPanUpdate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!WebUtils.isPopup)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: onPanUpdate,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    CustomBoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      blurStyle: BlurStyle.outer,
                    )
                  ],
                ),
                child: titleBar,
              ),
            ),
          Expanded(child: Stack(children: [...content, ...ui])),
        ],
      ),
    );
  }
}
