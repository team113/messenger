import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/provider/hive/skipped_version.dart';
import 'package:messenger/pubspec.g.dart';
import 'package:xml/xml.dart';

import '/config.dart';
import '/domain/service/disposable_service.dart';
import '/routes.dart';
import '/ui/widget/upgrade_popup/view.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';

class UpgradeWorker extends DisposableService {
  UpgradeWorker(this._skippedLocal);

  /// [SkippedVersionHiveProvider] for maintaining the skipped [Release.name]s.
  final SkippedVersionHiveProvider? _skippedLocal;

  /// [Duration] to display the [UpgradePopupView], when [_schedulePopup] is
  /// triggered.
  static const Duration _popupDelay = Duration(seconds: 1);

  @override
  void onReady() {
    // Web gets its updates out of the box with a simple page refresh.
    //
    // iOS gets its via App Store or TestFlight updates mechanisms.
    if (!PlatformUtils.isWeb && !PlatformUtils.isIOS) {
      _fetchUpdates();
    }

    super.onReady();
  }

  /// Skips the [release], meaning no popups will be prompted for this one.
  Future<void> skip(Release release) async {
    await _skippedLocal?.set(release.name);
  }

  /// Fetches the [Config.appcast] file to [_schedulePopup], if new [Release] is
  /// detected.
  Future<void> _fetchUpdates() async {
    print('_skippedLocal: $_skippedLocal');

    Log.debug('_fetchUpdates()', '$runtimeType');

    if (Config.appcast.isEmpty) {
      return;
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
          final Release release =
              Release.fromXml(items.first, language: L10n.chosen.value);

          Log.debug(
            'Comparing `${release.name}` to `${Pubspec.ref}`',
            '$runtimeType',
          );

          final bool skipped = _skippedLocal?.get() == release.name;
          if (release.name != Pubspec.ref && !skipped) {
            _schedulePopup(release);
          }
        }
      }
    } catch (e) {
      Log.info('Failed to fetch releases: $e', '$runtimeType');
    }
  }

  /// Schedules an [UpgradePopupView] prompt displaying.
  void _schedulePopup(Release release) {
    Log.debug('_schedulePopup($release)', '$runtimeType');

    Future.delayed(_popupDelay, () {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await UpgradePopupView.show(router.context!, release: release);
      });
    });
  }
}

/// Application release information.
class Release {
  const Release({
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.assets,
  });

  /// Constructs a [Release] from the provided [XmlElement].
  ///
  /// If [xml] contains language attributes specified for `description`, then
  /// this will try to use the [language] specified (or English, if `null`).
  factory Release.fromXml(XmlElement xml, {Language? language}) {
    language ??= L10n.languages.first;

    final String title = xml.findElements('title').first.innerText;
    final String description = xml
            .findElements('description')
            .firstWhereOrNull(
              (e) => e.attributes.any(
                (p) =>
                    p.name.qualified == 'xml:lang' &&
                    p.value == language?.locale.languageCode,
              ),
            )
            ?.innerText ??
        xml.findElements('description').first.innerText;
    final String date = xml.findElements('pubDate').first.innerText;
    final List<ReleaseArtifact> assets = xml
        .findElements('enclosure')
        .map((e) => ReleaseArtifact.fromXml(e))
        .toList();

    return Release(
      name: title,
      body: description,
      publishedAt: Rfc822ToDateTime.tryParse(date) ?? DateTime.now(),
      assets: assets,
    );
  }

  /// Title of this [Release] (usually a version).
  final String name;

  /// Release notes of this [Release].
  final String body;

  /// [DateTime] when this [Release] was published.
  final DateTime publishedAt;

  /// [ReleaseArtifact] attached to this [Release].
  final List<ReleaseArtifact> assets;

  @override
  String toString() {
    return 'Release(name: $name, body: $body, publishedAt: $publishedAt, assets: $assets)';
  }
}

/// Artifact of the [Release], usually in a binary form.
class ReleaseArtifact {
  const ReleaseArtifact({required this.url, required this.os});

  /// Constructs a [ReleaseArtifact] from the provided [xml].
  factory ReleaseArtifact.fromXml(XmlElement xml) {
    final String url = xml.getAttribute('url')!;
    final String os = xml.getAttribute('sparkle:os')!;

    return ReleaseArtifact(url: url, os: os);
  }

  /// URL the binary of this [ReleaseArtifact] is located.
  final String url;

  /// Operating system this [ReleaseArtifact] is for.
  final String os;

  @override
  String toString() => 'ReleaseArtifact(url: $url, os: $os)';
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
  /// Examples of valid [input]s:
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
