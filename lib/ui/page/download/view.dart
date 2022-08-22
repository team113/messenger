import 'package:flutter/material.dart';
import 'package:messenger/config.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/util/web/web_utils.dart';

import '/ui/widget/modal_popup.dart';

class DownloadView extends StatelessWidget {
  const DownloadView(this.modal, {Key? key}) : super(key: key);

  final bool modal;

  /// Displays a [DownloadView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const DownloadView(true));
  }

  @override
  Widget build(BuildContext context) {
    Widget _button({
      String? asset,
      double? width,
      double? height,
      String title = '...',
      String? link,
    }) {
      return Center(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
            ],
            borderRadius: BorderRadius.circular(15 * 0.7),
          ),
          child: OutlinedRoundedButton(
            leading: SvgLoader.asset(
              'assets/icons/$asset.svg',
              width: width,
              height: height,
            ),
            title: Text(title),
            color: Colors.white,
            maxWidth: 250,
            onPressed: link == null
                ? null
                : () {
                    WebUtils.download('${Config.origin}/artifacts/$link', link);
                  },
          ),
        ),
      );
    }

    Widget content = ListView(
      shrinkWrap: true,
      children: [
        const SizedBox(height: 20),
        _button(
          asset: 'windows',
          width: 21.93,
          height: 22,
          title: 'Windows',
          link: 'messenger-windows.zip',
        ),
        const SizedBox(height: 10),
        _button(
          asset: 'apple',
          width: 23,
          height: 29,
          title: 'macOS',
          link: 'messenger-macos.zip',
        ),
        const SizedBox(height: 10),
        _button(
          asset: 'linux',
          width: 18.85,
          height: 22,
          title: 'Linux',
          link: 'messenger-linux.zip',
        ),
        const SizedBox(height: 30),
        _button(
          asset: 'apple',
          width: 23,
          height: 29,
          title: 'iOS',
        ),
        const SizedBox(height: 30),
        _button(
          asset: 'google',
          width: 20.33,
          height: 22.02,
          title: 'Android',
          link: 'messenger-android.aab',
        ),
        const SizedBox(height: 10),
        _button(
          asset: 'google',
          width: 20.33,
          height: 22.02,
          title: '(x86-64)',
          link: 'messenger-android-x86_64.apk',
        ),
        const SizedBox(height: 10),
        _button(
          asset: 'google',
          width: 20.33,
          height: 22.02,
          title: '(armeabi-v7a)',
          link: 'messenger-android-armeabi-v7a.apk',
        ),
        const SizedBox(height: 10),
        _button(
          asset: 'google',
          width: 20.33,
          height: 22.02,
          title: '(x86-64)',
          link: 'messenger-arm64-v8a.apk',
        ),
        const SizedBox(height: 20),
      ],
    );

    if (modal) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: Center(child: content),
    );
  }
}
