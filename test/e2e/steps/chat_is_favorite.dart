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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../world/custom_world.dart';

/// Adds a [Chat] with the provided name to the favorites.
///
/// Examples:
/// - Given "Name" chat is favorite.
final StepDefinitionGeneric chatIsFavorite = given1<String, CustomWorld>(
  '{string} chat is favorite',
  (String name, context) async {
    final provider = GraphQlProvider();
    final AuthService authService = Get.find();
    provider.token = authService.credentials.value!.session.token;

    await provider.favoriteChat(
      context.world.groups[name]!,
      const ChatFavoritePosition(10),
    );

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
