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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import 'controller.dart';

/// View of the [Routes.chatDirectLink] page.
class ChatDirectLinkView extends StatelessWidget {
  const ChatDirectLinkView(this._slug, {Key? key}) : super(key: key);

  /// [String] to be parsed as a [ChatDirectLinkSlug] of this page.
  final String _slug;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ChatDirectLinkController(_slug, Get.find()),
      builder: (ChatDirectLinkController c) => Scaffold(
        body: Center(
          child: Obx(
            () => c.slug.value == null
                ? Text('label_unknown_page'.td)
                : const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
