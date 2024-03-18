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
  @override
  void onReady() {
    // _fetchUpdates();
    super.onReady();
  }

  Future<void> _fetchUpdates() async {
    if (Config.releasesUrl == null) {
      return;
    }

    try {
      final response = await (await PlatformUtils.dio).get(
        'https://raw.githubusercontent.com/team113/messenger/new-design-preview/appcast.xml',
      );

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

          if (release.name != Pubspec.version) {
            _schedulePopup(release);
          }
        }
      }
    } catch (e) {
      Log.info('Failed to fetch releases: $e', '$runtimeType');
    }
  }

  void _schedulePopup(Release release) {
    Future.delayed(const Duration(seconds: 1), () {
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
        .firstWhere(
          (e) => e.attributes.any((p) =>
              p.name.qualified == 'xml:lang' &&
              p.value == language?.locale.languageCode),
        )
        .innerText;
    final List<ReleaseAsset> assets = xml
        .findElements('enclosure')
        .map((e) => ReleaseAsset.fromXml(e))
        .toList();

    return Release(
      name: title,
      body: description,
      publishedAt: DateTime.now(),
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
  const ReleaseAsset({
    required this.version,
    required this.url,
    required this.os,
  });

  factory ReleaseAsset.fromXml(XmlElement xml) {
    final version = xml.getAttribute('sparkle:version')!;
    final url = xml.getAttribute('url')!;
    final os = xml.getAttribute('sparkle:os')!;

    return ReleaseAsset(
      version: version,
      url: url,
      os: os,
    );
  }

  final String version;
  final String url;
  final String os;

  @override
  String toString() {
    return 'ReleaseAsset(url: $url, version: $version, os: $os)';
  }
}
