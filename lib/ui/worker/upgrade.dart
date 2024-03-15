import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
import '/domain/service/disposable_service.dart';
import '/l10n/l10n.dart';
import '/pubspec.g.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/login/widget/primary_button.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
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
        final style = Theme.of(router.context!).style;

        await MessagePopup.alert(
          'Доступно обновление',
          additional: [
            Text(release.name, style: style.fonts.medium.regular.onBackground),
            const SizedBox(height: 8),
            MarkdownBody(
              data: release.body,
              onTapLink: (_, href, __) async => await launchUrlString(href!),
              styleSheet: MarkdownStyleSheet(
                h2Padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),

                // TODO: Exception.
                h2: style.fonts.largest.bold.onBackground
                    .copyWith(fontSize: 20),

                p: style.fonts.normal.regular.onBackground,
                code: style.fonts.small.regular.onBackground.copyWith(
                  letterSpacing: 1.2,
                  backgroundColor: style.colors.secondaryHighlight,
                ),
                codeblockDecoration: BoxDecoration(
                  color: style.colors.secondaryHighlight,
                ),
                codeblockPadding: const EdgeInsets.all(16),
                blockquoteDecoration: BoxDecoration(
                  color: style.colors.secondaryHighlight,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              release.publishedAt.toRelative(),
              style: style.fonts.small.regular.secondary,
            ),
          ],
          button: (context) {
            return Row(
              children: [
                Expanded(
                  child: OutlinedRoundedButton(
                    key: const Key('Skip'),
                    maxWidth: double.infinity,
                    onPressed: () => Navigator.of(context).pop(false),
                    color: style.colors.onBackgroundOpacity7,
                    child: Text(
                      'Пропустить'.l10n,
                      style: style.fonts.medium.regular.onBackground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryButton(
                    key: const Key('Download'),
                    onPressed: () => Navigator.of(context).pop(true),
                    title: 'btn_download'.l10n,
                  ),
                ),
              ],
            );
          },
        );
      });
    });
  }
}

class Release {
  const Release({
    required this.url,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.assets,
  });

  factory Release.fromJson(Map<String, dynamic> json) {
    return Release(
      url: json['url'],
      name: json['name'],
      body: json['body'],
      publishedAt: DateTime.parse(json['published_at']),
      assets: (json['assets'] as List)
          .map((e) => ReleaseAsset.fromJson(e))
          .toList(),
    );
  }

  final String url;
  final String name;
  final String body;
  final DateTime publishedAt;
  final List<ReleaseAsset> assets;

  @override
  String toString() {
    return 'Release(url: $url, name: $name, body: $body, publishedAt: $publishedAt, assets: $assets)';
  }
}

class ReleaseAsset {
  const ReleaseAsset({
    required this.url,
    required this.name,
    required this.contentType,
    required this.downloadCount,
    required this.size,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      url: json['url'],
      name: json['name'],
      contentType: json['content_type'],
      downloadCount: json['download_count'],
      size: json['size'],
    );
  }

  final String url;
  final String name;
  final String contentType;
  final int downloadCount;
  final int size;

  @override
  String toString() {
    return 'ReleaseAsset(url: $url, name: $name, contentType: $contentType, downloadCount: $downloadCount, size: $size)';
  }
}
