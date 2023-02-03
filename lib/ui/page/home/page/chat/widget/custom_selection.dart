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
import 'package:flutter/rendering.dart';

import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/util/platform_utils.dart';

/// Custom text selection widget.
class CustomSelection extends StatelessWidget {
  const CustomSelection({
    super.key,
    this.enabled = true,
    this.onSelectionChanged,
    required this.child,
  });

  /// Indicator whether selection is enabled or not.
  final bool enabled;

  /// Callback, called when the selected content changes.
  final void Function(SelectedContent?)? onSelectionChanged;

  /// [Widget] with text for selecting it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return SelectionArea(
        contextMenuBuilder: (_, state) => PlatformUtils.isMobile
            ? AdaptiveTextSelectionToolbar.selectableRegion(
                selectableRegionState: state,
              )
            : const SizedBox(),
        onSelectionChanged: onSelectionChanged,
        child: ContextMenuInterceptor(child: child),
      );
    } else {
      return ContextMenuInterceptor(child: child);
    }
  }
}
