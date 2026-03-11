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

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// View displaying a provided [String] in a QR code format.
class QrCodeView extends StatelessWidget {
  const QrCodeView(this.data, {super.key});

  /// [String] to encode in a QR code.
  final String data;

  /// Displays a [QrCodeView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {required String data}) {
    return ModalPopup.show(context: context, child: QrCodeView(data));
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalPopupHeader(text: 'label_qr_code'.l10n),
        Flexible(
          child: ListView(
            padding: ModalPopup.padding(context),
            shrinkWrap: true,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: style.colors.onPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: QrImageView(data: data),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: style.colors.onPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: WidgetButton(
                  onPressed: () {},
                  onPressedWithDetails: (u) {
                    PlatformUtils.copy(text: data);
                    MessagePopup.success(
                      'label_copied'.l10n,
                      at: u.globalPosition,
                    );
                  },
                  child: Text(data, style: style.fonts.normal.regular.primary),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                title: 'btn_download_as_png'.l10n,
                onPressed: () async {
                  final recorder = ui.PictureRecorder();
                  final canvas = Canvas(
                    recorder,
                    const Rect.fromLTWH(0, 0, 512, 512),
                  );

                  canvas.drawRect(
                    const Rect.fromLTWH(0, 0, 512, 512),
                    Paint()..color = Colors.white,
                  );

                  canvas.drawImage(
                    await QrPainter.withQr(
                      qr: QrCode.fromData(data: data, errorCorrectLevel: 1),
                      gapless: true,
                    ).toImage(500),
                    Offset(12 / 2, 12 / 2),
                    Paint(),
                  );

                  final picture = recorder.endRecording();
                  final image = await picture.toImage(512, 512);
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );

                  if (bytes == null) {
                    return MessagePopup.error('err_data_transfer'.l10n);
                  }

                  final file = await PlatformUtils.createAndDownload(
                    'qr_${DateTime.now().millisecondsSinceEpoch}.png',
                    bytes.buffer.asUint8List(),
                  );

                  if (file != null && PlatformUtils.isMobile) {
                    await SharePlus.instance.share(
                      ShareParams(files: [XFile(file.path)]),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
