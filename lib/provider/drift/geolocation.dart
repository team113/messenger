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
  Set<Column> get primaryKey => {ip, language};

  TextColumn get ip => text()();
  TextColumn get data => text()();
  TextColumn get language => text().nullable()();
  IntColumn get updatedAt => integer().map(const PreciseDateTimeConverter())();
}

/// [DriftProviderBase] for manipulating the persisted [IpGeoLocation].
class GeoLocationDriftProvider extends DriftProviderBase {
  GeoLocationDriftProvider(super.database);

  /// [IpGeoLocation] stored in the database and accessible synchronously.
  final Map<(IpAddress, String?), DtoIpGeoLocation> data = {};

  /// Creates or updates the provided [geo] in the database.
  Future<void> upsert(
    IpAddress ip,
    IpGeoLocation geo, {
    String? language,
  }) async {
    data[(ip, language)] = DtoIpGeoLocation(geo, PreciseDateTime.now());

    await safe<DtoIpGeoLocation?>((db) async {
      final result = await db
          .into(db.geoLocations)
          .insertReturning(
            geo.toDb(ip, language: language),
            onConflict: DoUpdate((_) => geo.toDb(ip, language: language)),
          );

      return _IpGeoLocationDb.fromDb(result);
    });
  }

  /// Returns the [IpGeoLocation] stored in the database by the provided [ip],
  /// if any.
  Future<DtoIpGeoLocation?> read(IpAddress ip, {String? language}) async {
    final DtoIpGeoLocation? existing = data[(ip, language)];
    if (existing != null) {
      return existing;
    }

    final result = await safe<DtoIpGeoLocation?>((db) async {
      final stmt = db.select(db.geoLocations);

      stmt.where((u) => u.ip.equals(ip.val));
      if (language != null) {
        stmt.where((u) => u.language.equals(language));
      }

      final GeoLocationRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _IpGeoLocationDb.fromDb(row);
    });

    if (result == null) {
      return null;
    }

    return data[(ip, language)] = result;
  }

  /// Deletes the [IpGeoLocation] identified by the provided [ip] from the
  /// database.
  Future<void> delete(IpAddress ip, {String? language}) async {
    data.remove((ip, language));

    await safe((db) async {
      final stmt = db.delete(db.geoLocations);

      stmt.where((u) => u.ip.equals(ip.val));
      if (language != null) {
        stmt.where((u) => u.language.equals(language));
      }

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
      language: e.language,
    );
  }

  /// Constructs a [GeoLocationRow] from these [IpGeoLocation].
  GeoLocationRow toDb(IpAddress ip, {String? language}) {
    return GeoLocationRow(
      ip: ip.val,
      data: jsonEncode(toJson()),
      updatedAt: PreciseDateTime.now(),
      language: language,
    );
  }
}
