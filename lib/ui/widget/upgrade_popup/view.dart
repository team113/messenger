import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/login/widget/primary_button.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/worker/upgrade.dart';
import 'controller.dart';

class UpgradePopupView extends StatelessWidget {
  const UpgradePopupView(this.release, {super.key});

  final Release release;

  /// Displays an [UpgradePopupView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {required Release release}) {
    return ModalPopup.show(context: context, child: UpgradePopupView(release));
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: UpgradePopupController(),
      builder: (UpgradePopupController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;

          switch (c.screen.value) {
            case UpgradePopupScreen.download:
              header = ModalPopupHeader(
                text: 'Downloads',
                onBack: () => c.screen.value = UpgradePopupScreen.notice,
              );

              final windows =
                  release.assets.firstWhereOrNull((e) => e.os == 'windows');
              final macos =
                  release.assets.firstWhereOrNull((e) => e.os == 'macos');
              final linux =
                  release.assets.firstWhereOrNull((e) => e.os == 'linux');
              final android =
                  release.assets.firstWhereOrNull((e) => e.os == 'android');
              final ios = release.assets.firstWhereOrNull((e) => e.os == 'ios');

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
              header = const ModalPopupHeader(text: 'Доступно обновление');
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
                      MarkdownBody(
                        data: release.body,
                        onTapLink: (_, href, __) async =>
                            await launchUrlString(href!),
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
