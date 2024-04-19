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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/ui/widget/modal_popup.dart';

/// Privacy policy page.
class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  /// Displays a [PrivacyPolicy] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const PrivacyPolicy());
  }

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

/// State of a [PrivacyPolicy] loading the [_text] of the privacy policy itself.
class _PrivacyPolicyState extends State<PrivacyPolicy> {
  /// Text of the privacy policy itself.
  String? _text;

  @override
  void initState() {
    rootBundle.loadString('assets/privacy.html').then(
      (value) {
        if (mounted) {
          setState(() => _text = value);
        }
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_text == null) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        const ModalPopupHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: ModalPopup.padding(context).add(
              const EdgeInsets.only(bottom: 16),
            ),
            child: HtmlWidget(
              _text!,
              onTapUrl: launchUrlString,
              customWidgetBuilder: (element) {
                // Don't display `<title>` tag, as body already contains header.
                if (element.localName == 'title') {
                  return const SizedBox();
                }

                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}
