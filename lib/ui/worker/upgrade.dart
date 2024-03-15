import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';

import '/config.dart';
import '/domain/service/disposable_service.dart';
import '/pubspec.g.dart';
import '/routes.dart';
import '/ui/widget/upgrade_popup/view.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';

class UpgradeWorker extends DisposableService {
  final List<Release> _releases = [];

  @override
  void onReady() {
    _fetchUpdates();
    super.onReady();
  }

  Future<void> _fetchUpdates() async {
    if (Config.releasesUrl == null) {
      return;
    }

    try {
      final Response response =
          await (await PlatformUtils.dio).get(Config.releasesUrl!);

      _releases.addAll(
        (response.data as List).map((e) => Release.fromJson(e)).toList(),
      );

      final Release? best =
          _releases.firstWhereOrNull((e) => e.name != Pubspec.version);

      if (best != null) {
        _schedulePopup(best);
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

  factory Release.fromJson(Map<String, dynamic> json) {
    return Release(
      name: json['name'],
      body: json['body'],
      publishedAt: DateTime.parse(json['published_at']),
      assets: (json['assets'] as List)
          .map((e) => ReleaseAsset.fromJson(e))
          .toList(),
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
    required this.url,
    required this.name,
    required this.contentType,
    required this.size,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      url: json['browser_download_url'],
      name: json['name'],
      contentType: json['content_type'],
      size: json['size'],
    );
  }

  final String url;
  final String name;
  final String contentType;
  final int size;

  @override
  String toString() {
    return 'ReleaseAsset(url: $url, name: $name, contentType: $contentType, size: $size)';
  }
}
