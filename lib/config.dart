// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:log_me/log_me.dart' as me;
import 'package:toml/toml.dart';
import 'package:yaml/yaml.dart';

import '/util/log.dart';
import '/util/platform_utils.dart';
import 'pubspec.g.dart';
import 'routes.dart';
import 'util/ios_utils.dart';

/// Configuration of this application.
class Config {
  /// Backend's HTTP URL.
  static String url = 'http://localhost';

  /// Backend's HTTP port.
  static int port = 80;

  /// GraphQL API endpoint of HTTP backend server.
  static String graphql = '/api/graphql/v1';

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
  static String appStoreUrl = '';

  /// URL of the application entry in Google Play.
  static String googlePlayUrl = '';

  /// VAPID (Voluntary Application Server Identification) key for Web Push.
  static String vapidKey =
      'BGYb_L78Y9C-X8Egon75EL8aci2K2UqRb850ibVpC51TXjmnapW9FoQqZ6Ru9rz5IcBAMwBIgjhBi-wn7jAMZC0';

  /// Indicator whether all looped animations should be disabled.
  ///
  /// Intended to be used in E2E testing.
  static bool disableInfiniteAnimations = false;

  /// Indicator whether all [DropRegion]s should be disabled.
  ///
  /// Intended to be used in E2E testing.
  static bool disableDragArea = false;

  /// Indicator whether any activity in [AppLifecycleState.detached] is allowed.
  ///
  /// Intended to be used in E2E testing.
  static bool allowDetachedActivity = false;

  /// Product identifier of `User-Agent` header to put in network queries.
  static String userAgentProduct = 'Tapopa';

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

  /// Maximum allowed [LogImpl.maxLogs] amount of log entries to keep.
  static int logAmount = 4096;

  /// Indicator whether [Log]s should obfuscate any private information
  /// (messages, tokens, etc).
  static bool logObfuscated = true;

  /// Indicator whether [Log]s should be written to a [File].
  static bool logWrite = false;

  /// URL of a Sparkle Appcast XML file.
  ///
  /// Intended to be used in [UpgradeWorker] to notify users about new releases
  /// available.
  static String appcast = '';

  /// Optional copyright to display at the bottom of [Routes.auth] page.
  static String copyright = '';

  /// URL of the repository (or anything else) for users to report bugs to.
  static String repository = 'https://github.com/tapopa/messenger/issues';

  /// Schema version of the [CommonDatabase].
  ///
  /// Should be bumped up, when breaking changes in this scheme occur, however
  /// be sure to write migrations and test them.
  static int commonVersion = 7;

  /// Schema version of the [ScopedDatabase].
  ///
  /// Should be bumped up, when breaking changes in this scheme occur, however
  /// be sure to write migrations and test them.
  static int scopedVersion = 3;

  /// Custom URL scheme to associate the application with when opening the deep
  /// links.
  static String scheme = 'tapopa';

  /// URL address of IP geolocation API server.
  static String geoEndpoint = 'https://ipwho.is';

  /// URL address of IP address discovering API server.
  static String ipEndpoint = 'https://api.ipify.org?format=json';

  /// Map of localized [Announcement]s that should be displayed within the app.
  ///
  /// Each key is expected to be a string of Unicode BCP47 Locale Identifier.
  static Map<String, Announcement> announcements = {};

  // TODO: Replace this hardcoded [UserId] with backend query.
  /// [UserId] of the support [Chat] user.
  static String supportId = '5TnWvlDyfr1pYagapHpInO';

  /// Initializes this [Config] by applying values from the following sources
  /// (in the following order):
  /// - compile-time environment variables;
  /// - bundled configuration file (`conf.toml`);
  /// - default values.
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    final Map<String, dynamic> document = TomlDocument.parse(
      await PlatformUtils.loadString('assets/conf.toml'),
    ).toMap();

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
          kDebugMode || kProfileMode ? me.LogLevel.debug : me.LogLevel.debug,
    );

    logAmount = const bool.hasEnvironment('SOCAPP_LOG_AMOUNT')
        ? const int.fromEnvironment('SOCAPP_LOG_AMOUNT')
        : (document['log']?['amount'] ?? 4096);

    logObfuscated = const bool.hasEnvironment('SOCAPP_LOG_OBFUSCATED')
        ? const bool.fromEnvironment('SOCAPP_LOG_OBFUSCATED')
        : (document['log']?['obfuscated'] ?? !kDebugMode);

    logWrite = const bool.hasEnvironment('SOCAPP_LOG_WRITE')
        ? const bool.fromEnvironment('SOCAPP_LOG_WRITE')
        : (document['log']?['write'] ?? !PlatformUtils.isWeb);

    appcast = const bool.hasEnvironment('SOCAPP_APPCAST_URL')
        ? const String.fromEnvironment('SOCAPP_APPCAST_URL')
        : (document['appcast']?['url'] ?? appcast);

    copyright = const bool.hasEnvironment('SOCAPP_LEGAL_COPYRIGHT')
        ? const String.fromEnvironment('SOCAPP_LEGAL_COPYRIGHT')
        : (document['legal']?['copyright'] ?? copyright);

    repository = const bool.hasEnvironment('SOCAPP_LEGAL_REPOSITORY')
        ? const String.fromEnvironment('SOCAPP_LEGAL_REPOSITORY')
        : (document['legal']?['repository'] ?? repository);

    scheme = const bool.hasEnvironment('SOCAPP_LINK_SCHEME')
        ? const String.fromEnvironment('SOCAPP_LINK_SCHEME')
        : (document['link']?['scheme'] ?? scheme);

    geoEndpoint = const bool.hasEnvironment('SOCAPP_GEO_ENDPOINT')
        ? const String.fromEnvironment('SOCAPP_GEO_ENDPOINT')
        : (document['geo']?['endpoint'] ?? geoEndpoint);

    ipEndpoint = const bool.hasEnvironment('SOCAPP_IP_ENDPOINT')
        ? const String.fromEnvironment('SOCAPP_IP_ENDPOINT')
        : (document['ip']?['endpoint'] ?? ipEndpoint);

    try {
      final dynamic announcementsOrNull = document['announcement'];
      if (announcementsOrNull is Map<String, dynamic>) {
        announcements.clear();
        for (var entry in announcementsOrNull.entries) {
          announcements[entry.key] = Announcement.parse(entry.value);
        }
      }

      // `bool.hasEnvironment` can only be used as a `const` constructor.
      if (const bool.hasEnvironment('SOCAPP_ANNOUNCEMENT_EN_US')) {
        announcements['en-US'] = Announcement.parse(
          const String.fromEnvironment('SOCAPP_ANNOUNCEMENT_EN_US'),
        );
      }

      // `bool.hasEnvironment` can only be used as a `const` constructor.
      if (const bool.hasEnvironment('SOCAPP_ANNOUNCEMENT_ES_ES')) {
        announcements['es-ES'] = Announcement.parse(
          const String.fromEnvironment('SOCAPP_ANNOUNCEMENT_ES_ES'),
        );
      }

      // `bool.hasEnvironment` can only be used as a `const` constructor.
      if (const bool.hasEnvironment('SOCAPP_ANNOUNCEMENT_RU_RU')) {
        announcements['en-US'] = Announcement.parse(
          const String.fromEnvironment('SOCAPP_ANNOUNCEMENT_RU_RU'),
        );
      }
    } catch (e) {
      Log.warning('init() -> announcements failed: $e', 'Config');
    }

    supportId = const bool.hasEnvironment('SOCAPP_SUPPORT_ID')
        ? const String.fromEnvironment('SOCAPP_SUPPORT_ID')
        : (document['support']?['id'] ?? supportId);

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
        final response = await (await PlatformUtils.dio).fetch(
          RequestOptions(path: '$url:$port/conf?${Pubspec.ref}'),
        );
        if (response.statusCode == 200) {
          dynamic remote;

          try {
            remote = TomlDocument.parse(response.data.toString()).toMap();
          } catch (e) {
            remote = loadYaml(response.data.toString());
          }

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
            copyright =
                remote['legal']?[Uri.base.host]?['copyright'] ??
                remote['legal']?['copyright'] ??
                copyright;
            repository = remote['legal']?['repository'] ?? repository;
            geoEndpoint = remote['geo']?['endpoint'] ?? geoEndpoint;
            ipEndpoint = remote['ip']?['endpoint'] ?? ipEndpoint;
            if (remote['log']?['level'] != null) {
              logLevel = me.LogLevel.values.firstWhere(
                (e) => e.name == remote['log']?['level'],
                orElse: () => logLevel,
              );
            }
            logAmount = _asInt(remote['log']?['amount']) ?? logAmount;
            logObfuscated = remote['log']?['obfuscated'] ?? logObfuscated;
            logWrite = remote['log']?['obfuscated'] ?? logWrite;

            try {
              final dynamic announcementsOrNull = remote['announcement'];
              if (announcementsOrNull is Map) {
                announcements.clear();
                for (var entry in announcementsOrNull.entries) {
                  if (entry.key is String && entry.value is String) {
                    announcements[entry.key] = Announcement.parse(entry.value);
                  }
                }
              }
            } catch (e) {
              Log.warning('init() -> announcements failed: $e', 'Config');
            }

            supportId = remote['support']?['id'] ?? supportId;

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

    // Notification Service Extension needs those to send message received
    // notification to backend.
    if (PlatformUtils.isIOS && !PlatformUtils.isWeb) {
      IosUtils.writeDefaults('url', url);
      IosUtils.writeDefaults('endpoint', graphql);

      // Store user agent to use as a `User-Agent` header in Notification
      // Service Extension.
      PlatformUtils.userAgent.then((agent) {
        if (agent.endsWith(')')) {
          agent = '${agent.substring(0, agent.length - 1)}; NSE)';
        }

        IosUtils.writeDefaults('agent', agent);
      });
    }
  }
}

/// [title] with a [body] intended to be used as an announcement to make to the
/// client in a non-dismissible way.
class Announcement {
  const Announcement({required this.title, this.body});

  /// Constructs an [Announcement] from the provided [text].
  ///
  /// First line of the [text], if there's multiple present, is considered as a
  /// [title].
  factory Announcement.parse(String text) {
    final split = text.split('\n');
    if (split.length >= 2) {
      final String title = split.first;
      return Announcement(
        title: title.trim(),
        body: text.substring(title.length + 1).trim(),
      );
    }

    return Announcement(title: text);
  }

  /// Indicates whether this [Announcement] is empty.
  bool get isEmpty => title.isEmpty && body?.isNotEmpty != true;

  /// Title of this [Announcement].
  final String title;

  /// Optional body of this [Announcement].
  final String? body;
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
