// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:get/get.dart';

import '/routes.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'menu_interceptor/menu_interceptor.dart';

/// [ContextMenuInterceptor] respecting the [RouterState.obscuring].
///
/// Workarounds an issue with [TextField]s becoming unresponsive under Web
/// platforms:
/// https://github.com/flutter/flutter/issues/157579
class ObscuredMenuInterceptor extends StatefulWidget {
  const ObscuredMenuInterceptor({
    super.key,
    this.margin = EdgeInsets.zero,
    required this.child,
    this.enabled = true,
    this.debug = false,
  });

  /// [EdgeInsets] being the margin of the interception.
  final EdgeInsets margin;

  /// Widget being wrapped.
  final Widget child;

  /// Indicator whether this widget should be active or not.
  final bool enabled;

  /// Indicator whether a semi-transparent red background should be renderer or
  /// not, used for debug purposes.
  final bool debug;

  @override
  State<ObscuredMenuInterceptor> createState() =>
      _ObscuredMenuInterceptorState();
}

/// State of a [ObscuredMenuInterceptor] maintaining the [GlobalKey].
class _ObscuredMenuInterceptorState extends State<ObscuredMenuInterceptor> {
  /// [GlobalKey] to use with [KeyedSubtree] to keep child from rebuilding.
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final bool isApplicable =
        PlatformUtils.isWeb && (WebUtils.isSafari || WebUtils.isFirefox);

    Widget child() => KeyedSubtree(key: _key, child: widget.child);
    Widget interceptor() => ContextMenuInterceptor(
      margin: widget.margin,
      enabled: widget.enabled,
      debug: widget.debug,
      child: child(),
    );

    if (!isApplicable) {
      return interceptor();
    }

    return Obx(() {
      if (router.obscuring.isNotEmpty) {
        return child();
      }

      return interceptor();
    });
  }
}
