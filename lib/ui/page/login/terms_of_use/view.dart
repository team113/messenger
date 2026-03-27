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
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/ui/widget/modal_popup.dart';
import '/util/platform_utils.dart';

/// Terms and conditions page.
class TermsOfUseView extends StatefulWidget {
  const TermsOfUseView({super.key});

  /// Displays a [TermsOfUseView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const TermsOfUseView());
  }

  @override
  State<TermsOfUseView> createState() => _TermsOfUseViewState();
}

/// State of a [TermsOfUseView] loading the [_text] of the terms and conditions
/// itself.
class _TermsOfUseViewState extends State<TermsOfUseView> {
  /// Text of the terms and conditions itself.
  String? _terms;

  /// Text of the privacy policy itself.
  String? _privacy;

  @override
  void initState() {
    PlatformUtils.loadString('assets/terms.html').then((value) {
      if (mounted) {
        setState(() => _terms = value);
      }
    });

    PlatformUtils.loadString('assets/privacy.html').then((value) {
      if (mounted) {
        setState(() => _privacy = value);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_terms == null && _privacy == null) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        const ModalPopupHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: ModalPopup.padding(
              context,
            ).add(const EdgeInsets.only(bottom: 16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HtmlWidget(
                  _terms!,
                  onTapUrl: launchUrlString,
                  customWidgetBuilder: (element) {
                    // Don't display `<title>` tag, as body already contains header.
                    if (element.localName == 'title') {
                      return const SizedBox();
                    }

                    return null;
                  },
                ),
                SizedBox(height: 64),
                HtmlWidget(
                  _privacy!,
                  onTapUrl: launchUrlString,
                  customWidgetBuilder: (element) {
                    // Don't display `<title>` tag, as body already contains header.
                    if (element.localName == 'title') {
                      return const SizedBox();
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
