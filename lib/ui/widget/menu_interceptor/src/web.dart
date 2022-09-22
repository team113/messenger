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

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Wrapper to prevent a default web context menu over its [child].
class ContextMenuInterceptor extends StatelessWidget {
  ContextMenuInterceptor({
    Key? key,
    required this.child,
    this.enabled = true,
    this.debug = false,
  }) : super(key: key) {
    if (!_registered) {
      _register();
    }
  }

  /// Widget being wrapped.
  final Widget child;

  /// Indicator whether this widget should be active or not.
  final bool enabled;

  /// Indicator whether a semi-transparent red background should be renderer or
  /// not, used for debug purposes.
  final bool debug;

  /// Indicator whether this widget has already registered its view factories or
  /// not.
  static bool _registered = false;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final String viewType = _getViewType(debug: debug);
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: HtmlElementView(viewType: viewType)),
        child,
      ],
    );
  }

  /// Registers the view factories for the widgets.
  static void _register() {
    assert(!_registered);

    _registerFactory();
    _registerFactory(debug: true);

    _registered = true;
  }

  /// Returns a view type for different configurations of this widget.
  static String _getViewType({bool debug = false}) {
    if (debug) {
      return '__webMenuInterceptorViewType__debug__';
    } else {
      return '__webMenuInterceptorViewType__';
    }
  }

  /// Registers a [ViewFactory] for this widget.
  static void _registerFactory({bool debug = false}) {
    final String viewType = _getViewType(debug: debug);

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final html.Element htmlElement = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('oncontextmenu', 'return false;');
        if (debug) {
          htmlElement.style.backgroundColor = 'rgba(255, 0, 0, .5)';
        }
        return htmlElement;
      },
      isVisible: false,
    );
  }
}
