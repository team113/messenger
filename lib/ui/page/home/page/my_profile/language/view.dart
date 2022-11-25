// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'dart:io';
import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';
import 'package:messenger/ui/page/call/widget/round_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/init_callback.dart';
import 'package:messenger/ui/page/home/page/chat/widget/my_dismissible.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/chat/forward/controller.dart';
import '/ui/page/home/page/chat/widget/animated_fab.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class LanguageSelectionView extends StatelessWidget {
  const LanguageSelectionView({Key? key}) : super(key: key);

  /// Displays a [LinkDetailsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: const LanguageSelectionView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: LanguageSelectionController(),
      builder: (LanguageSelectionController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16 - 12),
              ModalPopupHeader(
                header: Center(
                  child: Text(
                    'label_language'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 25 - 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: ModalPopup.padding(context),
                  itemBuilder: (context, i) {
                    final Language e = L10n.languages[i];
                    // final bool selected = L10n.chosen.value == e;

                    return Obx(() {
                      final bool selected = c.selected.value == e;
                      return SizedBox(
                        height: 48,
                        child: Material(
                          borderRadius: BorderRadius.circular(10),
                          color: selected
                              ? const Color(0xFFD7ECFF).withOpacity(0.8)
                              : Colors.white.darken(0.05),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            // onTap: () => L10n.set(e),
                            onTap: () => c.selected.value = e,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Text(
                                    '${e.locale.languageCode.toUpperCase()}, ${e.name}',
                                  ),
                                  const Spacer(),
                                  AnimatedSwitcher(
                                    duration: 200.milliseconds,
                                    child: selected
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  Color(0xFF63B4FF),
                                              radius: 12,
                                              child: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                          )
                                        : const SizedBox(key: Key('0')),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 5),
                  itemCount: L10n.languages.length,
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: ModalPopup.padding(context),
                child: OutlinedRoundedButton(
                  key: const Key('Proceed'),
                  maxWidth: null,
                  title: Text(
                    'btn_proceed'.l10n,
                    style: thin?.copyWith(color: Colors.white),
                  ),
                  onPressed: () {
                    if (c.selected.value != L10n.chosen.value) {
                      L10n.set(c.selected.value);
                    }

                    Navigator.of(context).pop();
                  },
                  color: const Color(0xFF63B4FF),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
