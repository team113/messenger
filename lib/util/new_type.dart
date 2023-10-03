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

import 'package:hive/hive.dart';

/// Helper for implementing a "new-type" idiom.
class NewType<T> {
  const NewType(this.val);

  /// Actual value wrapped by this [NewType].
  @HiveField(0)
  final T val;

  @override
  int get hashCode => val.hashCode;

  @override
  String toString() => val.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewType<T> &&
          runtimeType == other.runtimeType &&
          val == other.val;
}

/// Adds comparison operators to [Comparable] [NewType]s.
extension NewTypeComparable<T extends Comparable> on NewType<T> {
  bool operator >(NewType<T>? other) =>
      other == null || val.compareTo(other.val) > 0;

  bool operator >=(NewType<T>? other) =>
      other == null || val.compareTo(other.val) >= 0;

  bool operator <(NewType<T>? other) =>
      other != null && val.compareTo(other.val) < 0;

  bool operator <=(NewType<T>? other) =>
      other != null && val.compareTo(other.val) <= 0;
}
