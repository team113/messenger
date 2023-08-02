// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/style/page/multimedia/widget/info_stack.dart';

import '../../../../../../util/message_popup.dart';
import '../../../../../widget/widget_button.dart';
import '/ui/page/home/tab/chats/widget/unread_counter.dart';
import '/ui/widget/svg/svg.dart';

/// [Column] with [Container]s which represents application images.
class ImagesColumn extends StatelessWidget {
  const ImagesColumn({super.key, this.inverted = false, this.dense = false});

  /// Indicator whether this [ImagesColumn] should have its colors inverted.
  final bool inverted;

  /// Indicator whether this [ImagesColumn] should be compact, meaning
  /// minimal [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DefaultTextStyle(
          style: fonts.headlineSmall!.copyWith(
            color: const Color(0xFF1F3C5D),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoStackWidget(
                inverted: inverted,
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SvgImage.asset(
                    'assets/images/background_${inverted ? 'dark' : 'light'}.svg',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              WidgetButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          'assets/images/background_${inverted ? 'dark' : 'light'}.svg',
                    ),
                  );
                  MessagePopup.success('Path is copied');
                },
                child: const Text('background image'),
              ),
              const SizedBox(height: 16),
              InfoStackWidget(
                inverted: inverted,
                height: 300,
                width: 200,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SvgImage.asset('assets/images/logo/logo0000.svg'),
                ),
              ),
              WidgetButton(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(
                      text: 'assets/images/logo/logo0000.svg',
                    ),
                  );
                  MessagePopup.success('Path is copied');
                },
                child: const Text('Full-length logo'),
              ),
              const SizedBox(height: 16),
              InfoStackWidget(
                inverted: inverted,
                height: 150,
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SvgImage.asset('assets/images/logo/head0000.svg'),
                ),
              ),
              WidgetButton(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(
                      text: 'assets/images/logo/head0000.svg',
                    ),
                  );
                  MessagePopup.success('Path is copied');
                },
                child: const Text('Logo head'),
              ),
              const SizedBox(height: 16),
              InfoStackWidget(
                inverted: inverted,
                padding: const EdgeInsets.all(16),
                width: 190,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(24, (index) {
                    final int number = index + 1;

                    return UnreadCounter(number);
                  }),
                ),
              ),
              WidgetButton(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(
                      text: 'assets/images/logo/head0000.svg',
                    ),
                  );
                  MessagePopup.success('Technical name is copied');
                },
                child: const Text('UnreadCounter'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
