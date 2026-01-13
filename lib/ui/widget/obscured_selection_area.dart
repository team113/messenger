// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:get/get.dart';

import '/routes.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// [SelectionArea] respecting the [RouterState.obscuring].
///
/// Workarounds an issue with [TextField]s becoming unresponsive under Web
/// platforms:
/// https://github.com/flutter/flutter/issues/157579
class ObscuredSelectionArea extends StatefulWidget {
  const ObscuredSelectionArea({
    super.key,
    this.focusNode,
    this.selectionControls,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    this.magnifierConfiguration,
    this.onSelectionChanged,
    required this.child,
  });

  /// Configuration for the magnifier in the selection region.
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// Optional focus node to use as the focus node for this widget.
  final FocusNode? focusNode;

  /// Delegate to build the selection handles and toolbar.
  ///
  /// If it is `null`, the platform specific selection control is used.
  final TextSelectionControls? selectionControls;

  /// Builds the text selection toolbar when requested by the user.
  final SelectableRegionContextMenuBuilder? contextMenuBuilder;

  /// Callback called when the selected content changes.
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  /// Child widget [SelectionArea] applies to.
  final Widget child;

  @override
  State<ObscuredSelectionArea> createState() => _ObscuredSelectionAreaState();

  /// Builds a [AdaptiveTextSelectionToolbar.selectableRegion] with the provided
  /// [selectableRegionState].
  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    SelectableRegionState selectableRegionState,
  ) {
    return AdaptiveTextSelectionToolbar.selectableRegion(
      selectableRegionState: selectableRegionState,
    );
  }
}

/// State of a [ObscuredSelectionArea] keeping [GlobalKey].
class _ObscuredSelectionAreaState extends State<ObscuredSelectionArea> {
  /// [GlobalKey] to use with [KeyedSubtree] to keep child from rebuilding.
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final bool isApplicable =
        PlatformUtils.isWeb && (WebUtils.isSafari || WebUtils.isFirefox);

    Widget child() => KeyedSubtree(key: _key, child: widget.child);
    Widget area() => SelectionArea(
      magnifierConfiguration: widget.magnifierConfiguration,
      focusNode: widget.focusNode,
      selectionControls: widget.selectionControls,
      contextMenuBuilder: widget.contextMenuBuilder,
      onSelectionChanged: (a) {
        final String? selected = a?.plainText;

        if (selected != null &&
            selected.isNotEmpty == true &&
            selected.length >= 2) {
          final String selected1 = selected.substring(0, selected.length ~/ 2);
          final String selected2 = selected.substring(
            selected.length ~/ 2,
            selected.length,
          );

          if (selected1 == selected2) {
            a = SelectedContent(plainText: selected1);
          }
        }

        widget.onSelectionChanged?.call(a);
      },
      child: child(),
    );

    if (!isApplicable) {
      return area();
    }

    return Obx(() {
      if (router.obscuring.isNotEmpty) {
        return child();
      }

      return area();
    });
  }
}
