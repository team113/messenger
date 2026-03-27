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

/// Info of a [Page] in [Pagination].
///
/// Represents a [GraphQL Cursor Connections Specification][1] page info
/// structure.
///
/// [1]: https://relay.dev/graphql/connections.htm
class PageInfo<K> {
  PageInfo({
    this.hasNext = false,
    this.hasPrevious = false,
    this.startCursor,
    this.endCursor,
  });

  /// Indicator whether the next [Page] exists.
  bool hasNext;

  /// Indicator whether the previous [Page] exists.
  bool hasPrevious;

  /// Cursor of the first item in the [Page] this [PageInfo] is about.
  K? startCursor;

  /// Cursor of the last item in the [Page] this [PageInfo] is about.
  K? endCursor;

  @override
  String toString() =>
      'Page(hasNext: $hasNext, hasPrevious: $hasPrevious, startCursor: $startCursor, endCursor: $endCursor)';
}
