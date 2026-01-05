// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:get/get.dart';

import '/domain/model/country.dart';
import '/l10n/l10n.dart';
import '/ui/page/call/search/view.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// View for choosing an [IsoCode].
class SelectCountryView extends StatelessWidget {
  const SelectCountryView({
    super.key,
    this.available = const {},
    this.restricted = const {},
  });

  /// [IsoCode] available.
  ///
  /// If empty, then this parameter is ignored.
  final Set<IsoCode> available;

  /// [IsoCode]s restricted.
  ///
  /// If empty, then this parameter is ignored.
  final Set<IsoCode> restricted;

  /// Displays a [SelectCountryView] wrapped in a [ModalPopup].
  static Future<IsoCode?> show<T>(
    BuildContext context, {
    Set<IsoCode> available = const {},
    Set<IsoCode> restricted = const {},
  }) {
    return ModalPopup.show(
      context: context,
      child: SelectCountryView(available: available, restricted: restricted),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: SelectCountryController(),
      builder: (SelectCountryController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(text: 'label_country_selection'.l10n),
            Padding(
              padding: ModalPopup.padding(
                context,
              ).add(const EdgeInsets.fromLTRB(0, 8, 0, 0)),
              child: SearchField(
                c.search,
                onChanged: () => c.query.value = c.search.text,
              ),
            ),
            Expanded(
              child: Obx(() {
                final codes = IsoCode.values.where((e) {
                  if (available.isNotEmpty) {
                    if (!available.contains(e)) {
                      return false;
                    }
                  }

                  final name = 'country_${e.name.toLowerCase()}'.l10n
                      .toLowerCase();
                  final query = c.query.value?.toLowerCase();

                  return query == null ||
                      name.contains(query) ||
                      (e == IsoCode.US && (query == 'usa' || query == 'сша')) ||
                      (e == IsoCode.AE && (query == 'uae' || query == 'оаэ')) ||
                      (e == IsoCode.GB && (query == 'uk'));
                });

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: ListView(
                    key: Key('${codes.length}'),
                    padding: ModalPopup.padding(context),
                    children: [
                      const SizedBox(height: 8),
                      ...codes.map((e) {
                        final bool notAllowed = restricted.contains(e);

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 1.5, 0, 1.5),
                          child: RectangleButton(
                            label: 'country_${e.name.toLowerCase()}'.l10n,
                            leading: ClipOval(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: SvgImage.asset(
                                  'assets/images/country/${e.name.toLowerCase()}.svg',
                                  width: 26,
                                  height: 26,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            subtitle: notAllowed
                                ? 'label_paypal_is_not_available_in_this_country'
                                      .l10n
                                : null,
                            onPressed: notAllowed
                                ? null
                                : () => Navigator.of(context).pop(e),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
