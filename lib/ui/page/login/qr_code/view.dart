import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/login/widget/sign_button.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'controller.dart';

class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    this.onBack,
    this.scanning,
    this.title,
    this.path,
  });

  final void Function()? onBack;
  final bool? scanning;
  final String? title;
  final String? path;

  /// Displays a [QrCodeView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    void Function()? onBack,
    bool? scanning,
    String? title,
    String? path,
  }) {
    return ModalPopup.show(
      context: context,
      child: QrCodeView(
        onBack: onBack,
        scanning: scanning,
        title: title,
        path: path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: QrCodeController(scanning: scanning),
      builder: (QrCodeController c) {
        final Widget header = ModalPopupHeader(
          onBack: onBack,
          text: title ?? 'label_sign_in_with_qr_code'.l10n,
        );

        return Obx(() {
          final List<Widget> children = [
            if (c.scanning.value) ...[
              Text(
                'label_scan_qr_code_to_sign_in1'.l10n,
                style: style.fonts.medium.regular.onBackground,
              ),
              const SizedBox(height: 8),
              Text(
                path ?? 'label_scan_qr_code_to_sign_in2'.l10n,
                style: style.fonts.small.regular.secondary,
              ),
            ] else ...[
              Text(
                'label_show_qr_code_to_sign_in1'.l10n,
                style: style.fonts.medium.regular.onBackground,
              ),
              const SizedBox(height: 8),
              Text(
                path ?? 'label_show_qr_code_to_sign_in2'.l10n,
                style: style.fonts.small.regular.secondary,
              ),
            ],
            const SizedBox(height: 25),
            if (c.scanning.value)
              Center(
                child: QrImageView(
                  data: 'https://flutter.dev/',
                  version: QrVersions.auto,
                  size: 300.0,
                ),
              )
            else ...[
              Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: MobileScanner(
                    key: c.scannerKey,
                    controller: MobileScannerController(
                      formats: [BarcodeFormat.qrCode],
                    ),
                    onDetect: (capture) {
                      c.barcodes.value = capture.barcodes;
                    },
                  ),
                ),
              ),
              Obx(() {
                return Column(
                  children: [
                    ...c.barcodes.map(
                      (e) => Text('${e.type}: ${e.rawValue}'),
                    ),
                  ],
                );
              }),
            ],
            const SizedBox(height: 25 / 2),
            Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: style.colors.secondaryHighlight,
                  ),
                ),
                const SizedBox(width: 8),
                Text('label_or'.l10n,
                    style: style.fonts.small.regular.onBackground),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: style.colors.secondaryHighlight,
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
            const SizedBox(height: 25 / 2),
            SignButton(
              title: c.scanning.value
                  ? 'btn_scan_qr_code'.l10n
                  : 'btn_show_qr_code'.l10n,
              icon: const SvgIcon(SvgIcons.qrCode),
              onPressed: c.scanning.toggle,
            ),
            // const SizedBox(height: 16),
          ];

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            fadeInCurve: Curves.easeOut,
            fadeOutCurve: Curves.easeOut,
            sizeCurve: Curves.easeOut,
            child: Scrollbar(
              key: Key('${c.scanning.value}'),
              controller: c.scrollController,
              child: ListView(
                controller: c.scrollController,
                shrinkWrap: true,
                children: [
                  header,
                  const SizedBox(height: 12),
                  ...children.map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: e,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
