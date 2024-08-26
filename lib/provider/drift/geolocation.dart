// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:convert';

import 'package:drift/drift.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';
import '/store/model/geo.dart';
import 'common.dart';
import 'drift.dart';

/// [IpGeoLocation]s to be stored in a [Table].
@DataClassName('GeoLocationRow')
class GeoLocations extends Table {
  @override
  Set<Column> get primaryKey => {ip};

  TextColumn get ip => text()();
  TextColumn get data => text()();
  IntColumn get updatedAt => integer().map(const PreciseDateTimeConverter())();
}

/// [DriftProviderBase] for manipulating the persisted [IpGeoLocation].
class GeoLocationDriftProvider extends DriftProviderBase {
  GeoLocationDriftProvider(super.database);

  /// [IpGeoLocation] stored in the database and accessible synchronously.
  final Map<IpAddress, DtoIpGeoLocation> data = {};

  /// Creates or updates the provided [geo] in the database.
  Future<void> upsert(IpAddress ip, IpGeoLocation geo) async {
    data[ip] = DtoIpGeoLocation(geo, PreciseDateTime.now());

    await safe<DtoIpGeoLocation?>((db) async {
      final result = await db.into(db.geoLocations).insertReturning(
            geo.toDb(ip),
            onConflict: DoUpdate((_) => geo.toDb(ip)),
          );

      return _IpGeoLocationDb.fromDb(result);
    });
  }

  /// Returns the [IpGeoLocation] stored in the database by the provided [ip],
  /// if any.
  Future<DtoIpGeoLocation?> read(IpAddress ip) async {
    final DtoIpGeoLocation? existing = data[ip];
    if (existing != null) {
      return existing;
    }

    final result = await safe<DtoIpGeoLocation?>((db) async {
      final stmt = db.select(db.geoLocations)
        ..where((u) => u.ip.equals(ip.val));
      final GeoLocationRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _IpGeoLocationDb.fromDb(row);
    });

    if (result == null) {
      return null;
    }

    return data[ip] = result;
  }

  /// Deletes the [IpGeoLocation] identified by the provided [ip] from the
  /// database.
  Future<void> delete(IpAddress ip) async {
    data.remove(ip);

    await safe((db) async {
      final stmt = db.delete(db.geoLocations)
        ..where((e) => e.ip.equals(ip.val));
      await stmt.go();
    });
  }

  /// Deletes all the [IpGeoLocation]s stored in the database.
  Future<void> clear() async {
    data.clear();

    await safe((db) async {
      await db.delete(db.geoLocations).go();
    });
  }
}

/// Extension adding conversion methods from [GeoLocationRow] to
/// [IpGeoLocation].
extension _IpGeoLocationDb on IpGeoLocation {
  /// Constructs the [IpGeoLocation] from the provided [GeoLocationRow].
  static DtoIpGeoLocation fromDb(GeoLocationRow e) {
    return DtoIpGeoLocation(
      IpGeoLocation.fromJson(jsonDecode(e.data)),
      e.updatedAt,
    );
  }

  /// Constructs a [GeoLocationRow] from these [IpGeoLocation].
  GeoLocationRow toDb(IpAddress ip) {
    return GeoLocationRow(
      ip: ip.val,
      data: jsonEncode(toJson()),
      updatedAt: PreciseDateTime.now(),
    );
  }
}
