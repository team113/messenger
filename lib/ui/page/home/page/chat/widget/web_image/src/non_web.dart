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

/// Web [html.ImageElement] showing images natively.
///
/// Uses exponential backoff algorithm to re-fetch the [src] in case of errors.
///
/// Invokes the provided [onForbidden] callback on the `403 Forbidden` HTTP
/// errors.
///
/// Uses [Image.network] on non-web platforms.
class WebImage extends StatelessWidget {
  const WebImage(
    this.src, {
    super.key,
    this.onForbidden,
  });

  /// URL of the image to display.
  final String src;

  /// Callback, called when loading an image from the provided [src] fails with
  /// a forbidden network error.
  final Future<void> Function()? onForbidden;

  @override
  Widget build(BuildContext context) => Image.network(src);
}
