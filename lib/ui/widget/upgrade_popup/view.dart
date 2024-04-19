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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/login/widget/primary_button.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/markdown.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/worker/upgrade.dart';
import 'controller.dart';

/// Upgrade to [Release] prompt modal.
class UpgradePopupView extends StatelessWidget {
  const UpgradePopupView(this.release, {super.key});

  /// [Release] to prompt to upgrade to.
  final Release release;

  /// Displays an [UpgradePopupView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {required Release release}) {
    return ModalPopup.show(context: context, child: UpgradePopupView(release));
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
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

              final ReleaseArtifact? windows =
                  release.assets.firstWhereOrNull((e) => e.os == 'windows');
              final ReleaseArtifact? macos =
                  release.assets.firstWhereOrNull((e) => e.os == 'macos');
              final ReleaseArtifact? linux =
                  release.assets.firstWhereOrNull((e) => e.os == 'linux');
              final ReleaseArtifact? android =
                  release.assets.firstWhereOrNull((e) => e.os == 'android');
              final ReleaseArtifact? ios =
                  release.assets.firstWhereOrNull((e) => e.os == 'ios');

              children = [
                if (windows != null) DownloadButton.windows(link: windows.url),
                const SizedBox(height: 8),
                if (macos != null) DownloadButton.macos(link: macos.url),
                const SizedBox(height: 8),
                if (linux != null) DownloadButton.linux(link: linux.url),
                const SizedBox(height: 8),
                if (ios != null) DownloadButton.appStore(link: ios.url),
                const SizedBox(height: 8),
                if (android != null) DownloadButton.android(link: android.url),
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
              header = ModalPopupHeader(text: 'label_update_is_available'.l10n);
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
                      Expanded(
                        child: OutlinedRoundedButton(
                          key: const Key('Skip'),
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
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('Download'),
                          onPressed: () =>
                              c.screen.value = UpgradePopupScreen.download,
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
                const SizedBox(height: 4),
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
