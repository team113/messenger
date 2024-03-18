import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/worker/upgrade.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/login/widget/primary_button.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
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

              children = const [
                DownloadButton.windows(),
                SizedBox(height: 8),
                DownloadButton.macos(),
                SizedBox(height: 8),
                DownloadButton.linux(),
                SizedBox(height: 8),
                DownloadButton.appStore(),
                SizedBox(height: 8),
                DownloadButton.googlePlay(),
                SizedBox(height: 8),
                DownloadButton.android(),
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
                      Text(
                        release.body,
                        style: style.fonts.normal.regular.onBackground,
                      ),
                      const SizedBox(height: 8),
                      // MarkdownBody(
                      //   data: release.body,
                      //   onTapLink: (_, href, __) async =>
                      //       await launchUrlString(href!),
                      //   styleSheet: MarkdownStyleSheet(
                      //     h2Padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),

                      //     // TODO: Exception.
                      //     h2: style.fonts.largest.bold.onBackground
                      //         .copyWith(fontSize: 20),

                      //     p: style.fonts.normal.regular.onBackground,
                      //     code: style.fonts.small.regular.onBackground.copyWith(
                      //       letterSpacing: 1.2,
                      //       backgroundColor: style.colors.secondaryHighlight,
                      //     ),
                      //     codeblockDecoration: BoxDecoration(
                      //       color: style.colors.secondaryHighlight,
                      //     ),
                      //     codeblockPadding: const EdgeInsets.all(16),
                      //     blockquoteDecoration: BoxDecoration(
                      //       color: style.colors.secondaryHighlight,
                      //     ),
                      //   ),
                      // ),

                      // const SizedBox(height: 8),
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

enum _OperatingSystem {
  windows,
  macos,
  ios,
  android,
  linux;

  String get asFile => switch (this) {
        windows => 'messenger-windows.zip',
        macos => 'messenger-macos.zip',
        ios => 'messenger-ios.zip',
        android => 'messenger-android.apk',
        linux => 'messenger-linux.zip',
      };
}

extension DateTimeRfc822 on DateTime {
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

  static DateTime? parse(String input) {
    input = input.replaceFirst('GMT', '+0000');

    final splits = input.split(' ');

    final splitYear = splits[3];

    final splitMonth = _months[splits[2]];
    if (splitMonth == null) return null;

    var splitDay = splits[1];
    if (splitDay.length == 1) {
      splitDay = '0$splitDay';
    }

    final splitTime = splits[4], splitZone = splits[5];

    var reformatted = '$splitYear-$splitMonth-$splitDay $splitTime $splitZone';

    return DateTime.tryParse(reformatted);
  }
}
