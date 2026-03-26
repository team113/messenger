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

import '/api/backend/schema.dart';
import '/domain/model/link.dart';
import '/store/model/link.dart';

/// Extension adding models construction from a [DirectLinkMixin].
extension DirectLinkConversion on DirectLinkMixin {
  /// Constructs a new [DirectLink] from this [DirectLinkMixin].
  DirectLink toModel() => DirectLink(
    slug: slug,
    location: switch (location.$$typename) {
      'DirectLinkLocationUser' => DirectLinkLocationUser(
        (location as DirectLinkMixin$Location$DirectLinkLocationUser)
            .responder
            .id,
      ),
      'DirectLinkLocationGroup' => DirectLinkLocationGroup(
        (location as DirectLinkMixin$Location$DirectLinkLocationGroup).group.id,
      ),
      (_) => throw Exception(
        'DirectLinkConversion.toModel() -> unknown location for link: ${location.$$typename}',
      ),
    },
    isEnabled: isEnabled,
    createdAt: createdAt,
    visitors: stats.visitors,
  );

  /// Constructs a new [DtoDirectLink] from this [DirectLinkMixin].
  DtoDirectLink toDto({DirectLinksCursor? cursor}) =>
      DtoDirectLink(toModel(), ver, cursor);
}
