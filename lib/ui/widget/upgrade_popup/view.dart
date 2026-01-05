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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/markdown.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/primary_button.dart';
import '/ui/worker/upgrade.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'controller.dart';

/// Upgrade to [Release] prompt modal.
class UpgradePopupView extends StatelessWidget {
  const UpgradePopupView(this.release, {super.key, this.critical = false});

  /// [Release] to prompt to upgrade to.
  final Release release;

  /// Indicator whether this [release] is considered critical, meaning the one
  /// user can't skip.
  final bool critical;

  /// Displays an [UpgradePopupView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Release release,
    bool critical = false,
  }) {
    return ModalPopup.show(
      context: context,
      child: UpgradePopupView(release, critical: critical),
      isDismissible: !critical,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('UpgradePopup'),
      init: UpgradePopupController(Get.find()),
      builder: (UpgradePopupController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;

          switch (c.screen.value) {
            case UpgradePopupScreen.download:
              header = ModalPopupHeader(
                text: 'label_download'.l10n,
                onBack: () => c.screen.value = UpgradePopupScreen.notice,
              );

              final ReleaseArtifact? windows = release.assets.firstWhereOrNull(
                (e) => e.os == 'windows',
              );
              final ReleaseArtifact? macos = release.assets.firstWhereOrNull(
                (e) => e.os == 'macos',
              );
              final ReleaseArtifact? linux = release.assets.firstWhereOrNull(
                (e) => e.os == 'linux',
              );
              final ReleaseArtifact? android = release.assets.firstWhereOrNull(
                (e) => e.os == 'android',
              );
              final ReleaseArtifact? ios = release.assets.firstWhereOrNull(
                (e) => e.os == 'ios',
              );

              children =
                  [
                        if (windows != null) ...[
                          DownloadButton.windows(
                            link: windows.url,
                            onPressed: () => c.download(windows),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (macos != null) ...[
                          DownloadButton.macos(
                            link: macos.url,
                            onPressed: () => c.download(macos),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (linux != null) ...[
                          DownloadButton.linux(
                            link: linux.url,
                            onPressed: () => c.download(linux),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (Config.appStoreUrl.isNotEmpty) ...[
                          DownloadButton.appStore(),
                          const SizedBox(height: 8),
                        ],
                        if (ios != null) ...[
                          DownloadButton.ios(
                            link: ios.url,
                            onPressed: () => c.download(ios),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (Config.googlePlayUrl.isNotEmpty) ...[
                          DownloadButton.googlePlay(),
                          const SizedBox(height: 8),
                        ],
                        if (android != null)
                          DownloadButton.android(
                            link: android.url,
                            onPressed: () => c.download(android),
                          ),
                      ]
                      .map(
                        (e) => Padding(
                          padding: ModalPopup.padding(context),
                          child: e,
                        ),
                      )
                      .toList();
              break;

            case UpgradePopupScreen.notice:
              header = ModalPopupHeader(
                text: critical
                    ? 'label_critical_update_is_available'.l10n
                    : 'label_update_available'.l10n,
              );
              children = [
                Flexible(
                  child: ListView(
                    padding: ModalPopup.padding(context),
                    shrinkWrap: true,
                    children: [
                      Text(
                        release.name,
                        style: style.fonts.medium.regular.onBackground,
                      ),
                      const SizedBox(height: 8),
                      if (release.description != null)
                        MarkdownWidget(release.description!),
                      const SizedBox(height: 8),
                      Text(
                        release.publishedAt.toRelative(),
                        style: style.fonts.small.regular.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Row(
                    children: [
                      if (!critical) ...[
                        Expanded(
                          child: OutlinedRoundedButton(
                            key: const Key('SkipButton'),
                            maxWidth: double.infinity,
                            onPressed: () {
                              c.skip(release);
                              Navigator.of(context).pop(false);
                            },
                            color: style.colors.onBackgroundOpacity7,
                            child: Text(
                              'btn_skip'.l10n,
                              style: style.fonts.medium.regular.onBackground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (PlatformUtils.isWeb)
                        Expanded(
                          child: PrimaryButton(
                            key: const Key('RefreshButton'),
                            onPressed: WebUtils.refresh,
                            title: 'btn_refresh_page'.l10n,
                          ),
                        )
                      else
                        Expanded(
                          child: PrimaryButton(
                            key: const Key('DownloadButton'),
                            onPressed: Config.downloadable
                                ? () {
                                    final String system = PlatformUtils.isMacOS
                                        ? 'macos'
                                        : PlatformUtils.isWindows
                                        ? 'windows'
                                        : PlatformUtils.isAndroid
                                        ? 'android'
                                        : PlatformUtils.isIOS
                                        ? 'ios'
                                        : 'linux';

                                    final ReleaseArtifact? artifact = release
                                        .assets
                                        .firstWhereOrNull(
                                          (e) => e.os == system,
                                        );

                                    if (artifact != null) {
                                      c.download(artifact);
                                      Navigator.of(context).pop();
                                      return;
                                    }

                                    c.screen.value =
                                        UpgradePopupScreen.download;
                                  }
                                : PlatformUtils.isIOS &&
                                      Config.appStoreUrl.isNotEmpty
                                ? () => launchUrlString(Config.appStoreUrl)
                                : PlatformUtils.isAndroid &&
                                      Config.googlePlayUrl.isNotEmpty
                                ? () => launchUrlString(Config.googlePlayUrl)
                                : null,
                            title: 'btn_download'.l10n,
                          ),
                        ),
                    ],
                  ),
                ),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Column(
              key: Key(c.screen.value.name),
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 13),
                ...children,
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }
}
