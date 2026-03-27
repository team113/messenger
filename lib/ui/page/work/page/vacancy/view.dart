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

import '/routes.dart';
import '/ui/page/work/page/backend/view.dart';
import '/ui/page/work/page/freelance/view.dart';
import '/ui/page/work/page/frontend/view.dart';

/// View displaying page, corresponding to the provided [work].
class VacancyWorkView extends StatelessWidget {
  const VacancyWorkView(this.work, {super.key});

  /// [WorkTab] to display a page of.
  final WorkTab work;

  @override
  Widget build(BuildContext context) {
    switch (work) {
      case WorkTab.backend:
        return const BackendWorkView();

      case WorkTab.freelance:
        return const FreelanceWorkView();

      case WorkTab.frontend:
        return const FrontendWorkView();
    }
  }
}
