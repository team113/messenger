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
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/obs/obs.dart';

import '../parameters/favorite_status.dart';
import '../world/custom_world.dart';

/// Adds or removes a [ChatContact] with the provided name to or from the favorites
/// depending on the specified [FavoriteStatus].
///
/// Examples:
/// - Given "Name" contact is favorite
final StepDefinitionGeneric contactIsFavorite =
    given2<String, FavoriteStatus, CustomWorld>(
  '{string} contact is {favorite}',
  (String name, status, context) async {
    final ChatContactId contactId = context.world.contacts[name]!;
    final AuthService authService = Get.find();

    final provider = GraphQlProvider();
    provider.token = authService.credentials.value!.session.token;

    if (status == FavoriteStatus.favorite) {
      final RxObsMap<ChatContactId, RxChatContact> favorites =
          Get.find<ContactService>().favorites;

      final sortFavorites = favorites.values.toList()
        ..sort(
          (a, b) => a.contact.value.favoritePosition!
              .compareTo(b.contact.value.favoritePosition!),
        );

      final double? lowest = sortFavorites.isEmpty
          ? null
          : sortFavorites.first.contact.value.favoritePosition!.val;

      final position =
          ChatContactPosition(lowest == null ? 9007199254740991 : lowest / 2);

      await provider.favoriteChatContact(contactId, position);
    } else {
      await provider.unfavoriteChatContact(contactId);
    }

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
