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

/// Reporter of [AppLifecycleState] changes via a [didChangeAppLifecycleState].
class LifecycleObserver extends StatefulWidget {
  const LifecycleObserver({
    super.key,
    required this.child,
    this.didChangeAppLifecycleState,
  });

  /// [Widget] to wrap this [LifecycleObserver] into.
  final Widget child;

  /// Callback, called when the [AppLifecycleState] is changed.
  final void Function(AppLifecycleState state)? didChangeAppLifecycleState;

  @override
  State<LifecycleObserver> createState() => _LifecycleObserverState();
}

/// State of a [LifecycleObserver] used to observe the [AppLifecycleState].
class _LifecycleObserverState extends State<LifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.didChangeAppLifecycleState?.call(state);
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
