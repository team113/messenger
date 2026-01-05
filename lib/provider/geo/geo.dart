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

import 'package:dio/dio.dart';

import '/config.dart';
import '/domain/model/session.dart';
import '/util/platform_utils.dart';

/// [IpGeoLocation] fetching provider.
class GeoLocationProvider {
  /// [Dio] client lazily initialized.
  Dio? _client;

  /// Returns the [Dio] client used to fetch the data.
  Future<Dio> get _dio async {
    _client ??= await PlatformUtils.dio;
    return _client!;
  }

  /// Returns the [IpGeoLocation] associated with the provided [IpAddress].
  Future<IpGeoLocation> get(IpAddress ip, {String? language}) async {
    final Dio dio = await _dio;
    final Response response = await dio.get(
      '${Config.geoEndpoint}/$ip?fields=country,country_code,city${language == null ? '' : '&lang=$language'}',
    );

    if (response.statusCode != 200 ||
        response.data is! Map<String, dynamic> ||
        response.data?['country'] == null ||
        response.data?['country_code'] == null ||
        response.data?['city'] == null) {
      throw Exception(
        'Failed to fetch geo information. Status code: ${response.statusCode}. Data: ${response.data}',
      );
    }

    return IpGeoLocation.fromJson(response.data);
  }

  /// Returns the current [IpAddress] detected by [Config.ipEndpoint].
  Future<IpAddress> current() async {
    final Dio dio = await _dio;
    final Response response = await dio.get(Config.ipEndpoint);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch current IP. Status code: ${response.statusCode}. Data: ${response.data}',
      );
    }

    return IpAddress(response.data['ip']);
  }
}
