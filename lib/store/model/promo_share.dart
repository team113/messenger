// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '/domain/model/promo_share.dart';
import 'version.dart';

/// Persisted in storage [PromoShare]'s [value].
class DtoPromoShare implements Comparable<DtoPromoShare> {
  DtoPromoShare(this.value, this.version);

  /// Persisted [PromoShare] model.
  final PromoShare value;

  /// Version of the [value].
  final PromoShareVersion version;

  @override
  int compareTo(DtoPromoShare other) {
    return value.addedAt.compareTo(other.value.addedAt);
  }
}

/// Version of [PromoShare]'s state.
class PromoShareVersion extends Version {
  PromoShareVersion(super.val);
}
