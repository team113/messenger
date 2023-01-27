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

import 'package:flutter/widgets.dart';

/// [Widget] invoking the provided [callback] in its [State.initState].
class InitCallback extends StatefulWidget {
  const InitCallback({Key? key, this.callback, this.child}) : super(key: key);

  /// Callback, called in the [State.initState] of this [Widget].
  final void Function()? callback;

  /// Optional [Widget] to build as a child of this [Widget].
  final Widget? child;

  @override
  State<InitCallback> createState() => _InitCallbackState();
}

/// State of an [InitCallback].
class _InitCallbackState extends State<InitCallback> {
  @override
  void initState() {
    widget.callback?.call();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? Container();
  }
}
