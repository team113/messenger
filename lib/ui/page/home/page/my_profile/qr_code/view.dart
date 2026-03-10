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

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '/ui/widget/modal_popup.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalPopupHeader(),
        Padding(
          padding: ModalPopup.padding(context),
          child: AspectRatio(
            aspectRatio: 1,
            child: SizedBox(
              width: 300,
              height: 300,
              child: QrImageView(data: data),
            ),
          ),
        ),
      ],
    );
  }
}
