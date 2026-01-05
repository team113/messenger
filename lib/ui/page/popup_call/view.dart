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

import '/domain/model/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/call/view.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/scoped_dependencies.dart';
import 'controller.dart';

/// View of the [Routes.call] page.
class PopupCallView extends StatefulWidget {
  const PopupCallView({
    super.key,
    required this.chatId,
    required this.depsFactory,
  });

  /// ID of a [Chat] this call is taking place in.
  final ChatId chatId;

  /// [ScopedDependencies] factory of the [Routes.call] page.
  final Future<ScopedDependencies> Function() depsFactory;

  @override
  State<PopupCallView> createState() => _PopupCallViewState();
}

/// State of a [PopupCallView] maintaining the [_deps].
class _PopupCallViewState extends State<PopupCallView> {
  /// [Routes.call] page dependencies.
  ScopedDependencies? _deps;

  @override
  void initState() {
    super.initState();
    widget.depsFactory().then((v) => setState(() => _deps = v));
  }

  @override
  void dispose() {
    super.dispose();
    _deps?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_deps == null) {
      return const Scaffold(body: Center(child: CustomProgressIndicator()));
    }

    return GetBuilder<PopupCallController>(
      init: PopupCallController(widget.chatId, Get.find(), Get.find()),
      builder: (PopupCallController c) {
        // If call is `null`, this only means that `WebUtils.closeWindow()`
        // didn't succeed, which can be happen only due to browser not allowing
        // it, thus display a message.
        if (c.call == null) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Text('err_popup_call_cant_be_closed'.l10n),
                ),
              ),
            ),
          );
        }

        return CallView(c.call!, key: ValueKey(widget.chatId));
      },
    );
  }
}
