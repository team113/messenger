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

/// Builder building the [builder] with a [GlobalKey].
class WithGlobalKey extends StatefulWidget {
  const WithGlobalKey(this.builder, {super.key});

  /// Builder building the [Widget].
  final Widget Function(BuildContext context, GlobalKey key) builder;

  @override
  State<WithGlobalKey> createState() => _WithGlobalKeyState();
}

/// State of a [WithGlobalKey] maintaining the [_key].
class _WithGlobalKeyState extends State<WithGlobalKey> {
  /// [GlobalKey] itself.
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _key);
  }
}
