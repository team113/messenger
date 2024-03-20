import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/pubspec.g.dart';
import 'package:xml/xml.dart';

import '/config.dart';
import '/domain/service/disposable_service.dart';
import '/routes.dart';
import '/ui/widget/upgrade_popup/view.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';

class UpgradeWorker extends DisposableService {
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

  Future<void> _fetchUpdates() async {
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

          if (release.name != Pubspec.ref) {
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

class Release {
  const Release({
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.assets,
  });

  factory Release.fromXml(XmlElement xml, {Language? language}) {
    language ??= L10n.languages.first;

    final title = xml.findElements('title').first.innerText;
    final description = xml
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
    final date = xml.findElements('pubDate').first.innerText;
    final List<ReleaseAsset> assets = xml
        .findElements('enclosure')
        .map((e) => ReleaseAsset.fromXml(e))
        .toList();

    return Release(
      name: title,
      body: description,
      publishedAt: Rfc822ToDateTime.tryParse(date) ?? DateTime.now(),
      assets: assets,
    );
  }

  final String name;
  final String body;
  final DateTime publishedAt;
  final List<ReleaseAsset> assets;

  @override
  String toString() {
    return 'Release(name: $name, body: $body, publishedAt: $publishedAt, assets: $assets)';
  }
}

class ReleaseAsset {
  const ReleaseAsset({required this.url, required this.os});

  factory ReleaseAsset.fromXml(XmlElement xml) {
    final url = xml.getAttribute('url')!;
    final os = xml.getAttribute('sparkle:os')!;

    return ReleaseAsset(url: url, os: os);
  }

  final String url;
  final String os;

  @override
  String toString() => 'ReleaseAsset(url: $url, os: $os)';
}

/// Extension adding parsing on RFC-822 date format to [DateTime].
extension Rfc822ToDateTime on DateTime {
  /// Map of month abbreviations to their respective numbers.
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

  static DateTime? tryParse(String input) {
    input = input.replaceFirst('GMT', '+0000');

    final List<String> splits = input.split(' ');

    final String year = splits[3];
    final String month = _months[splits[2]]!;
    final String day = splits[1].padLeft(2, '0');
    final String time = splits[4];
    final String zone = splits.elementAtOrNull(5) ?? '+0000';
    final reformatted = '$year-$month-$day $time $zone';

    return DateTime.tryParse(reformatted);
  }
}
