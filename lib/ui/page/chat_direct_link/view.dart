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
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/system_info_prompt.dart';
import 'controller.dart';

/// View of the [Routes.chatDirectLink] page.
class ChatDirectLinkView extends StatelessWidget {
  const ChatDirectLinkView(this._slug, {super.key});

  /// [String] to be parsed as a [ChatDirectLinkSlug] of this page.
  final String _slug;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ChatDirectLinkController(_slug, Get.find()),
      builder: (ChatDirectLinkController c) {
        return Scaffold(
          appBar: ModalRoute.of(context)?.canPop == true
              ? const CustomAppBar(leading: [StyledBackButton()])
              : null,
          body: Center(
            child: Obx(() {
              if (c.slug.value == null) {
                return Center(
                  child: SystemInfoPrompt(
                    'label_unknown_chat_direct_link'.l10n,
                  ),
                );
              }

              return const CustomProgressIndicator.primary();
            }),
          ),
        );
      },
    );
  }
}
