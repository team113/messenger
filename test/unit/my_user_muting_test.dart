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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/my_user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/drift/account.dart';
import 'package:messenger/provider/drift/blocklist.dart';
import 'package:messenger/provider/drift/credentials.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/locks.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/drift/version.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_user_muting_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GraphQlProvider>()])
void main() async {
  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(
    graphQlProvider.onStart,
  ).thenReturn(InternalFinalCallback(callback: () {}));

  final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final userProvider = UserDriftProvider(common, scoped);
  final blocklistProvider = Get.put(BlocklistDriftProvider(common, scoped));
  final versionProvider = Get.put(VersionDriftProvider(common));
  final locksProvider = Get.put(LockDriftProvider(common));

  setUp(() async {
    await myUserProvider.clear();
  });

  Get.put(myUserProvider);
  Get.put<GraphQlProvider>(graphQlProvider);
  Get.put(credentialsProvider);

  test('MyUserService successfully mutes and unmutes MyUser', () async {
    when(graphQlProvider.myUserEvents(any)).thenAnswer(
      (_) async => Stream.fromIterable([
        QueryResult.internal(
          parserFn: (_) => null,
          source: null,
          data: {
            'myUserEvents': {'__typename': 'MyUser', ...myUserData},
          },
        ),
      ]),
    );

    when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());
    when(
      graphQlProvider.favoriteChatsEvents(any),
    ).thenAnswer((_) => const Stream.empty());
    when(
      graphQlProvider.sessionsEvents(any),
    ).thenAnswer((_) => const Stream.empty());
    when(
      graphQlProvider.blocklistEvents(any),
    ).thenAnswer((_) => const Stream.empty());

    when(graphQlProvider.toggleMyUserMute(null)).thenAnswer(
      (_) => Future.value(
        ToggleMyUserMute$Mutation.fromJson({
              'toggleMyUserMute': {
                '__typename': 'MyUserEventsVersioned',
                'events': [
                  {'__typename': 'EventUserUnmuted', 'userId': '12345'},
                ],
                'myUser': myUserData,
                'ver': '2',
              },
            }).toggleMyUserMute
            as ToggleMyUserMute$Mutation$ToggleMyUserMute$MyUserEventsVersioned,
      ),
    );

    when(
      graphQlProvider.getBlocklist(
        first: anyNamed('first'),
        after: null,
        last: null,
        before: null,
      ),
    ).thenAnswer(
      (_) => Future.value(GetBlocklist$Query$Blocklist.fromJson(blacklist)),
    );

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(
          AuthRepository(Get.find(), myUserProvider, credentialsProvider),
        ),
        credentialsProvider,
        accountProvider,
        locksProvider,
      ),
    );
    UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider),
    );

    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blocklistProvider,
        userRepository,
        versionProvider,
        me: const UserId('me'),
      ),
    );

    AbstractMyUserRepository myUserRepository = MyUserRepository(
      graphQlProvider,
      myUserProvider,
      blocklistRepository,
      userRepository,
      accountProvider,
    );
    myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
    await Future.delayed(Duration.zero);

    MyUserService myUserService = MyUserService(authService, myUserRepository);

    await myUserService.toggleMute(null);

    verify(graphQlProvider.toggleMyUserMute(null));
  });

  test(
    'MyUserService throws ToggleMyUserMuteException when muting MyUser',
    () async {
      when(graphQlProvider.myUserEvents(any)).thenAnswer(
        (_) async => Stream.fromIterable([
          QueryResult.internal(
            parserFn: (_) => null,
            source: null,
            data: {
              'myUserEvents': {'__typename': 'MyUser', ...myUserData},
            },
          ),
        ]),
      );
      when(
        graphQlProvider.sessionsEvents(any),
      ).thenAnswer((_) => const Stream.empty());

      when(graphQlProvider.toggleMyUserMute(null)).thenThrow(
        const ToggleMyUserMuteException(
          ToggleMyUserMuteErrorCode.artemisUnknown,
        ),
      );

      AuthService authService = Get.put(
        AuthService(
          Get.put<AbstractAuthRepository>(
            AuthRepository(Get.find(), myUserProvider, credentialsProvider),
          ),
          credentialsProvider,
          accountProvider,
          locksProvider,
        ),
      );
      UserRepository userRepository = Get.put(
        UserRepository(graphQlProvider, userProvider),
      );

      BlocklistRepository blocklistRepository = Get.put(
        BlocklistRepository(
          graphQlProvider,
          blocklistProvider,
          userRepository,
          versionProvider,
          me: const UserId('me'),
        ),
      );

      AbstractMyUserRepository myUserRepository = MyUserRepository(
        graphQlProvider,
        myUserProvider,
        blocklistRepository,
        userRepository,
        accountProvider,
      );
      myUserRepository.init(onUserDeleted: () {}, onPasswordUpdated: () {});
      MyUserService myUserService = MyUserService(
        authService,
        myUserRepository,
      );

      await expectLater(
        () async => await myUserService.toggleMute(null),
        throwsA(isA<ToggleMyUserMuteException>()),
      );

      verify(graphQlProvider.toggleMyUserMute(null));
    },
  );

  tearDown(() async => await Future.wait([common.close(), scoped.close()]));
}

final myUserData = {
  'id': '12345',
  'num': '1234567890123456',
  'login': 'login',
  'name': 'name',
  'emails': {'confirmed': [], 'unconfirmed': null},
  'phones': {'confirmed': [], 'unconfirmed': null},
  'hasPassword': true,
  'unreadChatsCount': 0,
  'ver': '0',
  'presence': 'AWAY',
  'online': {'__typename': 'UserOnline'},
  'blocklist': {'totalCount': 0},
};

final blacklist = {
  'edges': [],
  'pageInfo': {
    'endCursor': 'endCursor',
    'hasNextPage': false,
    'startCursor': 'startCursor',
    'hasPreviousPage': false,
  },
};
