// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:gherkin/gherkin.dart';
import 'package:messenger/l10n/l10n.dart';

import '../world/custom_world.dart';

/// Selects the application language.
///
/// Examples:
/// - `Given I have "English" language set`
final StepDefinitionGeneric selectLanguage = when1<String, CustomWorld>(
  'I have {string} language set',
  (languageName, context) async {
    await L10n.set(Language.fromTag(languageName) ?? L10n.languages.first);
    await context.world.appDriver.waitForAppToSettle();
  },
);
