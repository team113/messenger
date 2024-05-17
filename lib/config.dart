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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:log_me/log_me.dart' as me;
import 'package:toml/toml.dart';

import '/util/log.dart';
import '/util/platform_utils.dart';
import 'pubspec.g.dart';
import 'routes.dart';

/// Configuration of this application.
class Config {
  /// Backend's HTTP URL.
  static String url = 'http://localhost';

  /// Backend's HTTP port.
  static int port = 80;

  /// GraphQL API endpoint of HTTP backend server.
  static String graphql = '/api/graphql';

  /// Backend's WebSocket URL.
  static String ws = 'ws://localhost';

  /// File storage HTTP URL.
  static String files = 'http://localhost/files';

  /// Sentry DSN (Data Source Name) to send errors to.
  ///
  /// If empty, then omitted.
  static String sentryDsn = '';

  /// Domain considered as an origin of the application.
  static String origin = '';

  /// [ChatDirectLink] prefix.
  ///
  /// If empty, then [origin] is used.
  static String link = '';

  /// Directory to download files to.
  static String downloads = '';

  /// Indicator whether download links should be present within application.
  ///
  /// Should be `false` for builds uploaded to application stores, as usually
  /// those prohibit such links being present.
  static bool downloadable = true;

  /// URL of the application entry in App Store.
  static String appStoreUrl = 'https://apps.apple.com/app/gapopa/id6444211477';

  /// URL of the application entry in Google Play.
  static String googlePlayUrl =
      'https://play.google.com/store/apps/details?id=com.team113.messenger';

  /// VAPID (Voluntary Application Server Identification) key for Web Push.
  static String vapidKey =
      'BGYb_L78Y9C-X8Egon75EL8aci2K2UqRb850ibVpC51TXjmnapW9FoQqZ6Ru9rz5IcBAMwBIgjhBi-wn7jAMZC0';

  /// Indicator whether all looped animations should be disabled.
  ///
  /// Intended to be used in E2E testing.
  static bool disableInfiniteAnimations = false;

  /// Product identifier of `User-Agent` header to put in network queries.
  static String userAgentProduct = 'Gapopa';

  /// Version identifier of `User-Agent` header to put in network queries.
  static String userAgentVersion = '';

  /// Unique identifier of Windows application.
  static String clsid = '';

  /// Version of the application, used to clear cache if mismatch is detected.
  ///
  /// If not specified, [Pubspec.version] is used.
  ///
  /// Intended to be used in E2E testing.
  static String? version;

  /// Level of [Log]ger to log.
  static me.LogLevel logLevel = me.LogLevel.info;

  /// Version of the [Hive] schema, used to clear cache if mismatch is detected.
  static String? schema = '1';

  /// Version of the [CredentialsHiveProvider] schema, used to clear it, if
  /// mismatch is detected.
  static String? credentials = '0';

  /// URL of a Sparkle Appcast XML file.
  ///
  /// Intended to be used in [UpgradeWorker] to notify users about new releases
  /// available.
  static String appcast = '';

  /// Optional copyright to display at the bottom of [Routes.auth] page.
  static String copyright = '';

  /// Email address of the support service displayed on the [Routes.support]
  /// page.
  static String support = 'admin@gapopa.com';

  /// URL of the repository (or anything else) for users to report bugs to.
  static String repository = 'https://github.com/team113/messenger/issues';

  /// Initializes this [Config] by applying values from the following sources
  /// (in the following order):
  /// - compile-time environment variables;
  /// - bundled configuration file (`conf.toml`);
  /// - default values.
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    final Map<String, dynamic> document =
        TomlDocument.parse(await rootBundle.loadString('assets/conf.toml'))
            .toMap();

    graphql = const bool.hasEnvironment('SOCAPP_HTTP_GRAPHQL')
        ? const String.fromEnvironment('SOCAPP_HTTP_GRAPHQL')
        : (document['server']?['http']?['graphql'] ?? graphql);

    port = const bool.hasEnvironment('SOCAPP_HTTP_PORT')
        ? const int.fromEnvironment('SOCAPP_HTTP_PORT')
        : (document['server']?['http']?['port'] ?? port);

    url = const bool.hasEnvironment('SOCAPP_HTTP_URL')
        ? const String.fromEnvironment('SOCAPP_HTTP_URL')
        : (document['server']?['http']?['url'] ?? url);

    String wsUrl = const bool.hasEnvironment('SOCAPP_WS_URL')
        ? const String.fromEnvironment('SOCAPP_WS_URL')
        : (document['server']?['ws']?['url'] ?? 'ws://localhost');

    int wsPort = const bool.hasEnvironment('SOCAPP_WS_PORT')
        ? const int.fromEnvironment('SOCAPP_WS_PORT')
        : (document['server']?['ws']?['port'] ?? 80);

    files = const bool.hasEnvironment('SOCAPP_FILES_URL')
        ? const String.fromEnvironment('SOCAPP_FILES_URL')
        : (document['files']?['url'] ?? files);

    sentryDsn = const bool.hasEnvironment('SOCAPP_SENTRY_DSN')
        ? const String.fromEnvironment('SOCAPP_SENTRY_DSN')
        : (document['sentry']?['dsn'] ?? sentryDsn);

    downloads = const bool.hasEnvironment('SOCAPP_DOWNLOADS_DIRECTORY')
        ? const String.fromEnvironment('SOCAPP_DOWNLOADS_DIRECTORY')
        : (document['downloads']?['directory'] ?? downloads);

    downloadable = const bool.hasEnvironment('SOCAPP_DOWNLOADS_DOWNLOADABLE')
        ? const bool.fromEnvironment('SOCAPP_DOWNLOADS_DOWNLOADABLE')
        : (document['downloads']?['downloadable'] ?? downloadable);

    appStoreUrl = const bool.hasEnvironment('SOCAPP_DOWNLOADS_APP_STORE_URL')
        ? const String.fromEnvironment('SOCAPP_DOWNLOADS_APP_STORE_URL')
        : (document['downloads']?['app_store_url'] ?? appStoreUrl);

    googlePlayUrl =
        const bool.hasEnvironment('SOCAPP_DOWNLOADS_GOOGLE_PLAY_URL')
            ? const String.fromEnvironment('SOCAPP_DOWNLOADS_GOOGLE_PLAY_URL')
            : (document['downloads']?['google_play_url'] ?? googlePlayUrl);

    userAgentProduct = const bool.hasEnvironment('SOCAPP_USER_AGENT_PRODUCT')
        ? const String.fromEnvironment('SOCAPP_USER_AGENT_PRODUCT')
        : (document['user']?['agent']?['product'] ?? userAgentProduct);

    String version = const bool.hasEnvironment('SOCAPP_USER_AGENT_VERSION')
        ? const String.fromEnvironment('SOCAPP_USER_AGENT_VERSION')
        : (document['user']?['agent']?['version'] ?? '');

    userAgentVersion = version.isNotEmpty ? version : Pubspec.ref;

    clsid = const bool.hasEnvironment('SOCAPP_WINDOWS_CLSID')
        ? const String.fromEnvironment('SOCAPP_WINDOWS_CLSID')
        : (document['windows']?['clsid'] ?? clsid);

    vapidKey = const bool.hasEnvironment('SOCAPP_FCM_VAPID_KEY')
        ? const String.fromEnvironment('SOCAPP_FCM_VAPID_KEY')
        : (document['fcm']?['vapidKey'] ?? vapidKey);

    origin = url;

    link = const bool.hasEnvironment('SOCAPP_LINK_PREFIX')
        ? const String.fromEnvironment('SOCAPP_LINK_PREFIX')
        : (document['link']?['prefix'] ?? link);

    logLevel = me.LogLevel.values.firstWhere(
      (e) => const bool.hasEnvironment('SOCAPP_LOG_LEVEL')
          ? e.name == const String.fromEnvironment('SOCAPP_LOG_LEVEL')
          : e.name == document['log']?['level'],
      orElse: () =>
          kDebugMode || kProfileMode ? me.LogLevel.debug : me.LogLevel.info,
    );

    appcast = const bool.hasEnvironment('SOCAPP_APPCAST_URL')
        ? const String.fromEnvironment('SOCAPP_APPCAST_URL')
        : (document['appcast']?['url'] ?? appcast);

    copyright = const bool.hasEnvironment('SOCAPP_LEGAL_COPYRIGHT')
        ? const String.fromEnvironment('SOCAPP_LEGAL_COPYRIGHT')
        : (document['legal']?['copyright'] ?? copyright);

    support = const bool.hasEnvironment('SOCAPP_LEGAL_SUPPORT')
        ? const String.fromEnvironment('SOCAPP_LEGAL_SUPPORT')
        : (document['legal']?['support'] ?? support);

    repository = const bool.hasEnvironment('SOCAPP_LEGAL_REPOSITORY')
        ? const String.fromEnvironment('SOCAPP_LEGAL_REPOSITORY')
        : (document['legal']?['repository'] ?? repository);

    // Change default values to browser's location on web platform.
    if (PlatformUtils.isWeb) {
      if (document['server']?['http']?['url'] == null &&
          !const bool.hasEnvironment('SOCAPP_HTTP_URL')) {
        url = '${Uri.base.scheme}://${Uri.base.host}';
      }

      if (document['server']?['http']?['port'] == null &&
          !const bool.hasEnvironment('SOCAPP_HTTP_PORT')) {
        port = Uri.base.scheme == 'https' ? 443 : 80;
      }

      if (document['server']?['ws']?['url'] == null &&
          !const bool.hasEnvironment('SOCAPP_WS_URL')) {
        wsUrl =
            (Uri.base.scheme == 'https' ? 'wss://' : 'ws://') + Uri.base.host;
      }

      if (document['server']?['ws']?['port'] == null &&
          !const bool.hasEnvironment('SOCAPP_WS_PORT')) {
        wsPort = Uri.base.scheme == 'https' ? 443 : 80;
      }
    }

    if (document['files']?['url'] == null &&
        !const bool.hasEnvironment('SOCAPP_FILES_URL')) {
      files = '$url/files';
    }

    bool confRemote = const bool.hasEnvironment('SOCAPP_CONF_REMOTE')
        ? const bool.fromEnvironment('SOCAPP_CONF_REMOTE')
        : (document['conf']?['remote'] ?? true);

    // If [confRemote], then try to fetch and merge the remotely available
    // configuration.
    if (confRemote) {
      try {
        final response = await (await PlatformUtils.dio)
            .fetch(RequestOptions(path: '$url:$port/conf.toml'));
        if (response.statusCode == 200) {
          final Map<String, dynamic> remote =
              TomlDocument.parse(response.data.toString()).toMap();

          confRemote = remote['conf']?['remote'] ?? confRemote;
          if (confRemote) {
            graphql = remote['server']?['http']?['graphql'] ?? graphql;
            port = _asInt(remote['server']?['http']?['port']) ?? port;
            url = remote['server']?['http']?['url'] ?? url;
            wsUrl = remote['server']?['ws']?['url'] ?? wsUrl;
            wsPort = _asInt(remote['server']?['ws']?['port']) ?? wsPort;
            files = remote['files']?['url'] ?? files;
            sentryDsn = remote['sentry']?['dsn'] ?? sentryDsn;
            downloads = remote['downloads']?['directory'] ?? downloads;
            userAgentProduct =
                remote['user']?['agent']?['product'] ?? userAgentProduct;
            userAgentVersion =
                remote['user']?['agent']?['version'] ?? userAgentVersion;
            vapidKey = remote['fcm']?['vapidKey'] ?? vapidKey;
            link = remote['link']?['prefix'] ?? link;
            appcast = remote['appcast']?['url'] ?? appcast;
            copyright = remote['legal']?[Uri.base.host]['copyright'] ??
                remote['legal']?['copyright'] ??
                copyright;
            support = remote['legal']?['support'] ?? support;
            repository = remote['legal']?['repository'] ?? repository;
            if (remote['log']?['level'] != null) {
              logLevel = me.LogLevel.values.firstWhere(
                (e) => e.name == remote['log']?['level'],
                orElse: () => logLevel,
              );
            }
            origin = url;
          }
        }
      } catch (e) {
        Log.info('Remote configuration fetch failed.', 'Config');
      }
    }

    if (PlatformUtils.isWeb) {
      if ((Uri.base.scheme == 'https' && Uri.base.port != 443) ||
          Uri.base.scheme == 'http' && Uri.base.port != 80) {
        origin = '${Uri.base.scheme}://${Uri.base.host}:${Uri.base.port}';
      } else {
        origin = '${Uri.base.scheme}://${Uri.base.host}';
      }
    }

    if (link.isEmpty) {
      link = '$origin${Routes.chatDirectLink}';
    }

    ws = '$wsUrl:$wsPort$graphql';
  }
}

/// Parses the provided [val] as [int].
int? _asInt(dynamic val) {
  if (val is double) {
    return val.toInt();
  } else if (val is int) {
    return val;
  } else if (val is String) {
    return int.tryParse(val);
  }

  return null;
}
