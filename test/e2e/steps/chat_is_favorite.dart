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
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/obs/obs.dart';

import '../parameters/favorite_status.dart';
import '../world/custom_world.dart';

/// Adds or removes a [Chat] with the provided name to or from the favorites
/// depending on the specified [FavoriteStatus].
///
/// Examples:
/// - Given "Name" chat is favorite.
final StepDefinitionGeneric chatIsFavorite =
    given2<String, FavoriteStatus, CustomWorld>(
  '{string} chat is {favorite}',
  (String name, status, context) async {
    final ChatId chatId = context.world.groups[name]!;
    final provider = GraphQlProvider();
    final AuthService authService = Get.find();
    provider.token = authService.credentials.value!.session.token;

    if (status == FavoriteStatus.favorite) {
      final RxObsMap<ChatId, RxChat> chats = Get.find<ChatService>().chats;

      final List<RxChat> favorites = chats.values
          .where((e) => e.chat.value.favoritePosition != null)
          .toList();

      favorites.sort(
        (a, b) => a.chat.value.favoritePosition!
            .compareTo(b.chat.value.favoritePosition!),
      );

      final double? lowest = favorites.isEmpty
          ? null
          : favorites.first.chat.value.favoritePosition!.val;

      final position =
          ChatFavoritePosition(lowest == null ? 9007199254740991 : lowest / 2);

      await provider.favoriteChat(chatId, position);
    } else {
      await provider.unfavoriteChat(chatId);
    }

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
