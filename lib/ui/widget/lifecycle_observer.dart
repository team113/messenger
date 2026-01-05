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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:log_me/log_me.dart';

import '/util/platform_utils.dart';

/// Reporter of [AppLifecycleState] changes via a [onStateChange].
class LifecycleObserver extends StatefulWidget {
  const LifecycleObserver({super.key, required this.child, this.onStateChange});

  /// [Widget] to wrap this [LifecycleObserver] into.
  final Widget child;

  /// Callback, called when the [AppLifecycleState] is changed.
  final void Function(AppLifecycleState state)? onStateChange;

  @override
  State<LifecycleObserver> createState() => _LifecycleObserverState();
}

/// State of a [LifecycleObserver] used to observe the [AppLifecycleState].
class _LifecycleObserverState extends State<LifecycleObserver> {
  /// [AppLifecycleListener] listening for [AppLifecycleState] changes.
  late final AppLifecycleListener _listener;

  /// Subscription to the [PlatformUtilsImpl.onFocusChanged].
  StreamSubscription? _onFocusChanged;

  /// Indicator whether the first [build] was not invoked yet.
  bool _initial = true;

  /// Latest [AppLifecycleState] reported via the callback.
  AppLifecycleState? _reported;

  @override
  void initState() {
    _listener = AppLifecycleListener(onStateChange: _report);

    // It seems that `AppLifecycleListener` under Web doesn't fire any lifecycle
    // events at all.
    if (PlatformUtils.isWeb && PlatformUtils.isMobile) {
      _onFocusChanged = PlatformUtils.onFocusChanged.listen((focused) {
        Log.debug('_onFocusChanged -> $focused', '$runtimeType');

        if (focused) {
          _report(AppLifecycleState.resumed);
        } else {
          _report(switch (_reported) {
            AppLifecycleState.detached => AppLifecycleState.detached,
            AppLifecycleState.hidden => AppLifecycleState.hidden,
            AppLifecycleState.paused => AppLifecycleState.paused,
            AppLifecycleState.resumed => AppLifecycleState.hidden,
            AppLifecycleState.inactive => AppLifecycleState.inactive,
            null => AppLifecycleState.hidden,
          });
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    _listener.dispose();
    _onFocusChanged?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // It seems that initial transition from `detached` to `resumed` doesn't
    // fire despite a mention in the documentation to do so:
    // https://github.com/flutter/flutter/issues/134728
    if (_initial) {
      switch (_reported) {
        case AppLifecycleState.detached:
        case null:
          _report(AppLifecycleState.resumed);
          break;

        case AppLifecycleState.resumed:
        case AppLifecycleState.hidden:
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          // No-op.
          break;
      }

      _initial = false;
    }

    return widget.child;
  }

  /// Reports the [state].
  void _report(AppLifecycleState state) {
    if (_reported != state) {
      _reported = state;
      widget.onStateChange?.call(state);
    }
  }
}
