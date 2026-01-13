// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
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

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '/config.dart';
import '/domain/service/disposable_service.dart';
import '/l10n/l10n.dart';
import '/provider/drift/skipped_version.dart';
import '/pubspec.g.dart';
import '/routes.dart';
import '/ui/widget/upgrade_popup/view.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// Worker fetching [Config.appcast] file and prompting [UpgradePopupView] on
/// new [Release]s available.
class UpgradeWorker extends Dependency {
  UpgradeWorker(this._skippedLocal);

  /// Latest [Release] fetched during the [fetchUpdates].
  final Rx<Release?> latest = Rx(null);

  /// [ReleaseDownload] being active.
  final Rx<ReleaseDownload?> activeDownload = Rx(null);

  /// Latest [Release] scheduled to be displayed.
  ///
  /// This may differ from the [latest], because user might want to dismiss this
  /// notification.
  final Rx<Release?> scheduled = Rx(null);

  /// [SkippedVersionDriftProvider] for maintaining the skipped [Release]s.
  final SkippedVersionDriftProvider? _skippedLocal;

  /// [Timer] to periodically fetch updates over time.
  Timer? _timer;

  /// Latest [String] representing `flutter_bootstrap.js` file fetched.
  String? _lastBootstrapJs;

  /// Indicator whether [_schedulePopup] was invoked and there's a
  /// [MessagePopup.success] invoke being active.
  bool _scheduled = false;

  /// [Duration] to display the [UpgradePopupView] after, when [_schedulePopup]
  /// is triggered.
  static const Duration _popupDelay = Duration(seconds: 1);

  /// [Duration] being the period of [_timer].
  static const Duration _refreshPeriod = Duration(minutes: 3);

  @override
  void onReady() {
    Log.debug('onReady()', '$runtimeType');

    // Don't check for updates in [WebUtils.isPopup].
    if (!WebUtils.isPopup) {
      fetchUpdates();

      if (Config.appcast.isNotEmpty || PlatformUtils.isWeb) {
        _timer = Timer.periodic(_refreshPeriod, (_) {
          fetchUpdates();
        });
      }
    }

    super.onReady();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// Skips the [release], meaning no popups will be prompted for this one.
  Future<void> skip(Release release) async {
    Log.debug('skip($release)', '$runtimeType');

    if (scheduled.value == release) {
      scheduled.value = null;
    }

    await _skippedLocal?.upsert(release.name);
  }

  /// Initiates the downloading of the provided [release].
  Future<void> download(ReleaseArtifact release) async {
    final releaseDownload = ReleaseDownload(release.url);
    activeDownload.value?.cancel();
    activeDownload.value = releaseDownload;

    try {
      await activeDownload.value?.start();
      activeDownload.value = releaseDownload;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.cancel:
          activeDownload.value?.cancel();
          activeDownload.value = null;
          break;

        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.badCertificate:
        case DioExceptionType.badResponse:
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          activeDownload.value?.cancel();
          activeDownload.value = null;
          try {
            await launchUrlString(release.url);
          } catch (e) {
            MessagePopup.error(e);
            rethrow;
          }
      }
    } catch (e) {
      activeDownload.value?.cancel();
      activeDownload.value = null;
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Invokes [_fetchBootstrapJs] over [PlatformUtilsImpl.isWeb] and
  /// [_fetchAppcast] otherwise to check against any updates being available.
  Future<bool> fetchUpdates({bool force = false}) async {
    if (Config.appcast.isNotEmpty) {
      return await _fetchAppcast(force: force);
    } else if (PlatformUtils.isWeb) {
      return await _fetchBootstrapJs();
    }

    return false;
  }

  /// Fetches the [Config.appcast] file to [_schedulePopup], if new [Release] is
  /// detected.
  ///
  /// Returns `true`, if new update is detected.
  ///
  /// If [force] is `true`, then ignores the [_skippedLocal] stored one.
  Future<bool> _fetchAppcast({bool force = false}) async {
    Log.debug('_fetchAppcast(force: $force)', '$runtimeType');

    if (Config.appcast.isEmpty) {
      return false;
    }

    try {
      final response = await (await PlatformUtils.dio).get(Config.appcast);

      if (response.statusCode != 200 || response.data == null) {
        throw DioException.connectionError(
          requestOptions: RequestOptions(),
          reason: 'Status code ${response.statusCode}',
        );
      }

      final XmlDocument document = XmlDocument.parse(response.data);
      final XmlElement? rss = document.findElements('rss').firstOrNull;
      final XmlElement? channel = rss?.findElements('channel').firstOrNull;

      if (channel != null) {
        final Iterable<XmlElement> items = channel.findElements('item');

        if (items.isNotEmpty) {
          final Release release = Release.fromXml(
            items.first,
            language: L10n.chosen.value,
          );

          // If the latest fetched [Release] is the same as this one, then don't
          // even try to compare it.
          if (latest.value?.name == release.name) {
            return false;
          }

          bool silent = latest.value != null;
          latest.value = release;

          Log.debug(
            'Comparing `${release.name}` to `${Pubspec.ref}`',
            '$runtimeType',
          );

          if (release.name != Pubspec.ref) {
            Version? ours;
            try {
              ours = VersionExtension.parse(Pubspec.ref);
            } catch (e) {
              // No-op.
            }

            Version? their;
            try {
              their = VersionExtension.parse(release.name);
            } catch (e) {
              // No-op.
            }

            // Shouldn't prompt user with versions lower than current.
            final bool lower = ours != null && their != null
                ? ours < their
                : Pubspec.ref.compareTo(release.name) == -1;
            Log.info(
              'Whether `${Pubspec.ref}` is lower than `${release.name}`: $lower',
              '$runtimeType',
            );

            // Critical releases must always be displayed and can't be skipped.
            final bool critical = ours?.isCritical(their) ?? false;
            Log.info(
              'Whether `$ours` is considered critical relative to `$their`: $critical',
              '$runtimeType',
            );

            final bool skipped =
                !force && await _skippedLocal?.read() == release.name;
            if (critical || (lower && !skipped && Config.downloadable)) {
              _schedulePopup(
                release,
                critical: critical,
                delay: !force && critical,
                silent: silent,
              );
              return true;
            }
          }
        }
      }
    } catch (e) {
      Log.info('Failed to fetch `appcast.xml` releases: $e', '$runtimeType');
    }

    return false;
  }

  /// Fetches the `flutter_bootstrap.js` file hosted over [Config.origin] with
  /// every Flutter Web build to check whether there's any new build available.
  ///
  /// Returns `true`, if new update is detected.
  Future<bool> _fetchBootstrapJs() async {
    Log.debug('_fetchBootstrapJs()', '$runtimeType');

    try {
      final response = await (await PlatformUtils.dio).get(
        '${Config.origin}/flutter_bootstrap.js?${const Uuid().v4()}',
      );

      if (response.statusCode != 200 || response.data == null) {
        throw DioException.connectionError(
          requestOptions: RequestOptions(),
          reason: 'Status code ${response.statusCode}',
        );
      }

      final String bootstrapJs = response.data as String;

      if (_lastBootstrapJs != null && _lastBootstrapJs != bootstrapJs) {
        _schedulePopup(
          Release(
            name: 'label_update_available'.l10n,
            description: null,
            publishedAt: DateTime.now(),
            assets: [],
          ),
          critical: false,
          delay: false,
          silent: true,
        );
      }

      _lastBootstrapJs = bootstrapJs;
    } catch (e) {
      Log.info('Failed to fetch `flutter_bootstrap.js`: $e', '$runtimeType');
    }

    return false;
  }

  /// Schedules an [UpgradePopupView] prompt displaying.
  Future<void> _schedulePopup(
    Release release, {
    bool critical = false,
    bool delay = true,
    bool silent = false,
  }) async {
    Log.debug('_schedulePopup($release)', '$runtimeType');

    Future<void> displayPopup() async {
      // Only restrain from displaying the popup if app has authorization.
      if (!critical) {
        if (_scheduled) {
          return;
        }

        _scheduled = true;
        scheduled.value = release;

        return;
      }

      if (router.context != null) {
        await UpgradePopupView.show(
          router.context!,
          release: release,
          critical: critical,
        );
      }
    }

    if (delay) {
      await Future.delayed(_popupDelay, () {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) async => await displayPopup(),
        );
      });
    } else {
      await displayPopup();
    }
  }
}

/// Application release information.
class Release {
  const Release({
    required this.name,
    required this.description,
    required this.publishedAt,
    required this.assets,
  });

  /// Constructs a [Release] from the provided [XmlElement].
  ///
  /// If [xml] contains language attributes specified for `description`, then
  /// this will try to use the [language] specified (or English, if `null`).
  factory Release.fromXml(XmlElement xml, {Language? language}) {
    language ??= L10n.languages.first;

    String title = xml.findElements('title').first.innerText;

    // Omit the leading `v` of the release version, if any.
    if (title.startsWith('v')) {
      title = title.substring(1);
    }

    final String? description =
        xml
            .findElements('description')
            .firstWhereOrNull(
              (e) => e.attributes.any(
                (p) =>
                    p.name.qualified == 'xml:lang' &&
                    p.value == language?.toString(),
              ),
            )
            ?.innerText ??
        xml.findElements('description').firstOrNull?.innerText;

    final String date = xml.findElements('pubDate').first.innerText;
    final List<ReleaseArtifact> assets = xml
        .findElements('enclosure')
        .map((e) => ReleaseArtifact.fromXml(e))
        .toList();

    return Release(
      name: title,
      description: (description?.isEmpty ?? true) ? null : description?.trim(),
      publishedAt: Rfc822ToDateTime.tryParse(date) ?? DateTime.now(),
      assets: assets,
    );
  }

  /// Title of this [Release] (usually a version).
  final String name;

  /// Release notes of this [Release].
  final String? description;

  /// [DateTime] when this [Release] was published.
  final DateTime publishedAt;

  /// [ReleaseArtifact] attached to this [Release].
  final List<ReleaseArtifact> assets;

  @override
  String toString() {
    return 'Release(name: $name, description: $description, publishedAt: $publishedAt, assets: $assets)';
  }

  @override
  bool operator ==(Object other) {
    return other is Release &&
        name == other.name &&
        description == other.description &&
        publishedAt == other.publishedAt &&
        const ListEquality().equals(assets, other.assets);
  }

  @override
  int get hashCode => Object.hash(name, description, publishedAt, assets);
}

/// Artifact of the [Release].
class ReleaseArtifact {
  const ReleaseArtifact({required this.url, required this.os});

  /// Constructs a [ReleaseArtifact] from the provided [xml].
  factory ReleaseArtifact.fromXml(XmlElement xml) {
    final String url = xml.getAttribute('url')!;
    final String os = xml.getAttribute('sparkle:os')!;

    return ReleaseArtifact(url: url, os: os);
  }

  /// URL of the binary this [ReleaseArtifact] is about.
  final String url;

  /// Operating system this [ReleaseArtifact] is for.
  final String os;

  @override
  String toString() => 'ReleaseArtifact(url: $url, os: $os)';

  @override
  bool operator ==(Object other) {
    return other is ReleaseArtifact && url == other.url && os == other.os;
  }

  @override
  int get hashCode => Object.hash(url, os);
}

/// [Release] being downloaded, exposing its [url], [progress] and [file]
/// parameters.
class ReleaseDownload {
  ReleaseDownload(this.url);

  /// URL to download from.
  final String url;

  /// Progress of the downloading.
  final RxDouble progress = RxDouble(0);

  /// Downloaded [File].
  final Rx<File?> file = Rx(null);

  /// [CancelToken] canceling the download.
  CancelToken? _cancelToken;

  /// Starts the downloading.
  Future<void> start() async {
    if (_cancelToken != null) {
      return;
    }

    _cancelToken = CancelToken();

    progress.value = 0;

    try {
      file.value = await PlatformUtils.download(
        url,
        url.split('/').lastOrNull ?? 'file',
        null,
        onReceiveProgress: (a, b) {
          if (b != 0) {
            progress.value = a / b;
          }
        },
        cancelToken: _cancelToken,
      );

      if (file.value != null) {
        progress.value = 1;
        MessagePopup.success('label_file_downloaded'.l10n);
      }
    } finally {
      progress.value = 0;
    }
  }

  /// Cancels the download.
  void cancel() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}

/// Extension adding parsing of RFC-822 date format to [DateTime].
extension Rfc822ToDateTime on DateTime {
  /// Month abbreviations to their respective numbers.
  static const Map<String, String> _months = {
    'Jan': '01',
    'Feb': '02',
    'Mar': '03',
    'Apr': '04',
    'May': '05',
    'Jun': '06',
    'Jul': '07',
    'Aug': '08',
    'Sep': '09',
    'Oct': '10',
    'Nov': '11',
    'Dec': '12',
  };

  /// Possible days of the week.
  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Tries parsing the [input] being a RFC-822 date to the [DateTime].
  ///
  /// If fails to do so, then returns `null`.
  ///
  /// Examples of the valid [input]s:
  /// - `Wed, 20 Mar 2024 12:00:03 +0300`
  /// - `Sun, 1 Jun 2024 15:10:51 +0000`
  /// - `Tue, 5 Dec 2000 01:02:03 GMT`
  /// - `1 Sep 2007 23:23:59 +0100`
  static DateTime? tryParse(String input) {
    // Replace the possible GMT to the +0000.
    input = input.replaceFirst('GMT', '+0000');

    final List<String> splits = input.split(' ');

    // Completely ignore the day of the week part.
    final int i = _days.any((e) => splits[0].startsWith(e)) ? 1 : 0;

    final String day = splits[i].padLeft(2, '0');
    final String? month = _months[splits[i + 1]];
    if (month == null) {
      return null;
    }

    final String year = splits[i + 2];
    final String time = splits[i + 3];
    final String zone = splits.elementAtOrNull(i + 4) ?? '+0000';

    return DateTime.tryParse('$year-$month-$day $time $zone');
  }
}

/// Extension adding ability to determine critical [Version]s, the ones user
/// can't skip.
extension CriticalVersionExtension on Version {
  /// Indicates whether this [Version] is considered critical compared to the
  /// [other], meaning the one user can't skip.
  ///
  /// Algorithm determining whether the [other] is consider critical follows the
  /// rules, which is easier to demonstrate with the following examples:
  /// - `0.1.0` -> `0.1.1` => `false`;
  /// - `0.1.0` -> `0.2.0` => `true`;
  /// - `0.1.0` -> `1.0.0` => `true`;
  /// - `1.0.0` -> `1.0.1` => `false`;
  /// - `1.0.0` -> `1.1.0` => `false`.
  ///
  /// And the suffixes:
  /// - `0.1.0-alpha` -> `0.1.0` => `true`;
  /// - `0.1.0-alpha` -> `0.1.0.alpha.1` => `true`;
  /// - `0.1.0-alpha.1` -> `0.1.0.alpha.2` => `true`;
  /// - `0.1.0-alpha.2` -> `0.1.0.alpha.2.1` => `false`;
  /// - `0.1.0-alpha.2.1` -> `0.1.0.alpha.2.16` => `false`;
  /// - `0.1.0-alpha.3` -> `0.1.0.beta.3` => `true`;
  /// - `0.1.0` -> `0.2.0-rc` => `false`;
  /// - `0.1.0` -> `1.0.0-beta` => `false`;
  /// - `1.0.0-beta` -> `1.0.0-rc` => `true`.
  bool isCritical(Version? other) {
    if (other == null) {
      return false;
    }

    // If ours version is higher than the [other], then this isn't a critical
    // release.
    if (this > other) {
      return false;
    }

    // First of all, compare pre-releases.
    if (preRelease.isEmpty && other.preRelease.isNotEmpty) {
      // If the compared version is a pre-release and ours isn't, then the
      // compared is never critical, as we shouldn't update to pre-releases from
      // stable versions.
      //
      // Example: `1.0.0` -> `2.0.0-alpha.1` => `false`.
      return false;
    } else if (preRelease.isNotEmpty && other.preRelease.isEmpty) {
      // If our version is a pre-release and the compared one isn't, then the
      // compared is considered critical.
      //
      // Example: `1.0.0-alpha.1` -> `1.0.0` => `true`.
      return true;
    } else if (preRelease.isNotEmpty && other.preRelease.isNotEmpty) {
      // Both versions contain pre-release labels, thus compare their respective
      // major/minor numbers first.
      //
      // Differences in major number are always considered critical.
      //
      // Example: `1.0.0-alpha` -> `2.0.0-alpha` => `true`.
      if (major < other.major) {
        return true;
      }

      if (major == 0) {
        // If major is `0`, then differences in minor number are considered
        // critical.
        //
        // Example: `0.1.0-alpha` -> `0.2.0-alpha` => `true`.
        if (minor < other.minor) {
          return true;
        }
      }

      // If both versions are different patches and have pre-releases, then this
      // is a critical release.
      //
      // Example: `0.1.0-alpha.1` -> `0.1.1-alpha.1` => `true`.
      if (patch != other.patch) {
        return true;
      }

      // If pre-releases are equal to each other, then this isn't a critical
      // release.
      if (const ListEquality().equals(preRelease, other.preRelease)) {
        return false;
      }

      final ourFirst = preRelease.first;
      final theirFirst = other.preRelease.first;

      if (ourFirst is Comparable && theirFirst is Comparable) {
        // First pre-release parts are equal (`alpha` and `alpha`, for example).
        if (ourFirst == theirFirst) {
          final ourSecond = preRelease.elementAtOrNull(1);
          final theirSecond = other.preRelease.elementAtOrNull(1);

          if (ourSecond is Comparable && theirSecond is Comparable) {
            // Second pre-release parts are equal (`1` and `1`, for example).
            if (ourSecond == theirSecond) {
              // If the second parts are equal, then the deeper parts are
              // different, which isn't considered a critical release.
              //
              // Example: `0.1.0-alpha.1` -> `0.1.0-alpha.1.1` => `false`.
              // Example: `0.1.0-alpha.1.1.2` -> `0.1.0-alpha.1.1.3` => `false`.
              // Example: `0.1.0-alpha.1.5` -> `0.1.0-alpha.1.6` => `false`.
              return false;
            } else {
              // If our second pre-release part is lower than the second
              // pre-release part of the other version, then this is critical.
              //
              // Example: `0.1.0-alpha.1` -> `0.1.0-alpha.2` => `true`.
              return ourSecond.compareTo(theirSecond) < 0;
            }
          }
        } else {
          // If our first pre-release part is lower than the first pre-release
          // part of the other version, then this is critical.
          //
          // Example: `0.1.0-alpha` -> `0.1.0-beta` => `true`.
          return ourFirst.compareTo(theirFirst) < 0;
        }
      }
    }

    // If the compared versions contain no pre-releases, then proceed comparing
    // major/minor numbers.
    //
    // Differences in major number are always considered critical.
    //
    // Example: `1.0.0` -> `2.0.0` => `true`.
    if (major < other.major) {
      return true;
    }

    if (major == 0) {
      // If major is `0`, then differences in minor number are considered
      // critical.
      //
      // Example: `0.1.0` -> `0.2.0` => `true`.
      if (minor < other.minor) {
        return true;
      }
    }

    // Otherwise this isn't a critical release.
    //
    // Example: `0.1.0` -> `0.1.1` => `false`.
    // Example: `1.0.0` -> `1.0.1` => `false`.
    // Example: `1.0.0` -> `1.2.3` => `false`.
    return false;
  }
}

/// Extension adding [Version]s parsing with hyphens in pre-releases parsed as
/// separate parts.
extension VersionExtension on Version {
  /// Returns the [Version] parsed from the [text] with the hyphens in
  /// pre-releases being parsed as a separate parts, if any.
  ///
  /// Example: `0.1.0-alpha.13-5-qwe` -> `preRelease: ['alpha', 13, 5, 'qwe']`.
  ///
  /// This is required due to [PubspecBuilder] using `git describe --tags`,
  /// which returns hyphens instead of dots, and replacing that behavior seems a
  /// bigger evil than this.
  static Version parse(String text) {
    final Version parsed = Version.parse(text);

    return Version(
      parsed.major,
      parsed.minor,
      parsed.patch,
      pre: parsed.preRelease.isEmpty
          ? null
          : parsed.preRelease
                .map((e) => e is String ? e.replaceAll('-', '.') : e)
                .join('.'),
      build: parsed.build.isEmpty ? null : parsed.build.join('.'),
    );
  }
}
