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

// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import '/ui/page/call/widget/hint.dart';
import '/ui/page/home/page/chat/widget/time_label.dart';
import '/ui/page/home/page/chat/widget/unread_label.dart';
import '/themes.dart';

/// View of all system messages in app.
class SystemMessagesWidget extends StatelessWidget {
  const SystemMessagesWidget(this.isDarkMode, {super.key});

  /// Indicator whether this page is in dark mode.
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: style.colors.onPrimary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 20, left: 20),
            child: Tooltip(
              message: 'HintWidget',
              child: SizedBox(
                width: 290,
                child: HintWidget(
                  text:
                      'Add and remove elements of the control panel by drag-and-drop.',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Tooltip(
            message: 'TimeLabelWidget',
            child: TimeLabelWidget(DateTime.now()),
          ),
          const SizedBox(height: 16),
          const Tooltip(
            message: 'UnreadLabel',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: UnreadLabel(3),
            ),
          ),
        ],
      ),
    );
  }
}
