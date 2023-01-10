// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/blacklist.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_profile_phones_test.mocks.dart';

@GenerateMocks([GraphQlProvider])
void main() async {
  Hive.init('./test/.temp_hive/my_user_muting_unit');
  var userData = {
    'id': '12345',
    'num': '1234567890123456',
    'login': 'login',
    'name': 'name',
    'bio': 'bio',
    'emails': {'confirmed': [], 'unconfirmed': null},
    'phones': {'confirmed': [], 'unconfirmed': null},
    'gallery': {'nodes': []},
    'hasPassword': true,
    'unreadChatsCount': 0,
    'ver': '0',
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
  };

  var blacklist = {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    }
  };

  var sessionProvider = SessionDataHiveProvider();
  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  await sessionProvider.init();

  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();
  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  var blacklistedUsersProvider = BlacklistHiveProvider();
  await blacklistedUsersProvider.init();

  setUp(() async {
    await myUserProvider.clear();
  });

  Get.put(myUserProvider);
  Get.put(galleryItemProvider);
  Get.put<GraphQlProvider>(graphQlProvider);
  Get.put(sessionProvider);

  test('MyUserService successfully mutes and unmutes MyUser', () async {
    when(graphQlProvider.myUserEvents(null)).thenAnswer(
      (_) => Future.value(Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'myUserEvents': {'__typename': 'MyUser', ...userData},
          },
        )
      ])),
    );

    when(graphQlProvider.keepOnline())
        .thenAnswer((_) => Future.value(const Stream.empty()));

    when(graphQlProvider.toggleMyUserMute(null)).thenAnswer(
      (_) => Future.value(ToggleMyUserMute$Mutation.fromJson({
        'toggleMyUserMute': {
          '__typename': 'MyUserEventsVersioned',
          'events': [
            {'__typename': 'EventUserUnmuted', 'userId': '12345'}
          ],
          'myUser': userData,
          'ver': '2'
        }
      }).toggleMyUserMute
          as ToggleMyUserMute$Mutation$ToggleMyUserMute$MyUserEventsVersioned),
    );

    when(graphQlProvider.getBlacklist(
      first: 120,
      after: null,
      last: null,
      before: null,
    )).thenAnswer(
      (_) => Future.value(GetBlacklist$Query$Blacklist.fromJson(blacklist)),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      blacklistedUsersProvider,
      galleryItemProvider,
      userRepository,
    );
    myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    await Future.delayed(Duration.zero);

    MyUserService myUserService = MyUserService(authService, myUserRepository);

    await myUserService.toggleMute(null);

    verify(graphQlProvider.toggleMyUserMute(null));
  });

  test('MyUserService throws ToggleMyUserMuteException when muting MyUser',
      () async {
    when(graphQlProvider.myUserEvents(null)).thenAnswer(
      (_) => Future.value(Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'myUserEvents': {'__typename': 'MyUser', ...userData},
          },
        ),
      ])),
    );

    when(graphQlProvider.toggleMyUserMute(null)).thenThrow(
      const ToggleMyUserMuteException(ToggleMyUserMuteErrorCode.artemisUnknown),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider, galleryItemProvider));
    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      blacklistedUsersProvider,
      galleryItemProvider,
      userRepository,
    );
    myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    MyUserService myUserService = MyUserService(authService, myUserRepository);

    expect(
      () async => await myUserService.toggleMute(null),
      throwsA(isA<ToggleMyUserMuteException>()),
    );

    verify(graphQlProvider.toggleMyUserMute(null));
  });
}
