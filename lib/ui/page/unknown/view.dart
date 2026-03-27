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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/widget/system_info_prompt.dart';

/// View for displaying not found page routes.
class UnknownView extends StatelessWidget {
  const UnknownView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Scaffold(
      appBar: ModalRoute.of(context)?.canPop == true
          ? const CustomAppBar(leading: [StyledBackButton()])
          : null,
      backgroundColor: style.colors.background,
      body: Center(child: SystemInfoPrompt('label_unknown_page'.l10n)),
    );
  }
}
