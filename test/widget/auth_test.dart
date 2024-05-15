// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/notification.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/account.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/blocklist.dart';
import 'package:messenger/provider/hive/call_credentials.dart';
import 'package:messenger/provider/hive/call_rect.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/monolog.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/model/chat.dart';
import 'package:messenger/store/model/my_user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/view.dart';
import 'package:messenger/util/audio_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/audio_utils.dart';
import '../mock/graphql_provider.dart';
import '../mock/route_information_provider.dart';
import 'auth_test.mocks.dart';

@GenerateMocks([RouterState])
void main() async {
  AudioUtils = AudioUtilsMock();
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.disableInfiniteAnimations = true;
  Config.clsid = 'clsid';
  await L10n.init();

  final DriftProvider database = DriftProvider.memory();

  Hive.init('./test/.temp_hive/auth_widget');

  var credentialsProvider = CredentialsHiveProvider();
  await credentialsProvider.init();
  await credentialsProvider.clear();

  final accountProvider = AccountHiveProvider();
  await accountProvider.init();
  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();

  final graphQlProvider = _FakeGraphQlProvider();

  var contactProvider = ContactHiveProvider();
  await contactProvider.init(userId: const UserId('me'));
  final userProvider = UserDriftProvider(database);
  var chatProvider = ChatHiveProvider();
  await chatProvider.init(userId: const UserId('me'));
  var settingsProvider = MediaSettingsHiveProvider();
  await settingsProvider.init(userId: const UserId('me'));
  var draftProvider = DraftHiveProvider();
  await draftProvider.init(userId: const UserId('me'));
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init(userId: const UserId('me'));
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init(userId: const UserId('me'));
  var callCredentialsProvider = CallCredentialsHiveProvider();
  await callCredentialsProvider.init(userId: const UserId('me'));
  var blockedUsersProvider = BlocklistHiveProvider();
  await blockedUsersProvider.init(userId: const UserId('me'));
  var callRectProvider = CallRectHiveProvider();
  await callRectProvider.init(userId: const UserId('me'));
  var monologProvider = MonologHiveProvider();
  await monologProvider.init(userId: const UserId('me'));

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      theme: Themes.light(),
      home: Builder(
        builder: (BuildContext context) {
          router.context = context;
          return Scaffold(body: child);
        },
      ),
    );
  }

  testWidgets('AuthView logins a user and redirects to HomeView',
      (WidgetTester tester) async {
    Get.put(myUserProvider);
    Get.put(contactProvider);
    Get.put(userProvider);
    Get.put<GraphQlProvider>(graphQlProvider);
    Get.put(credentialsProvider);
    Get.put(chatProvider);
    Get.put(draftProvider);
    Get.put(settingsProvider);
    Get.put(callCredentialsProvider);
    Get.put(NotificationService(graphQlProvider));
    Get.put(monologProvider);

    final AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(
          Get.find(),
          myUserProvider,
          credentialsProvider,
        )),
        credentialsProvider,
        accountProvider,
      ),
    );

    authService.init();

    router = MockRouterState();
    router.provider = MockedPlatformRouteInformationProvider();

    await tester.pumpWidget(createWidgetForTesting(child: const AuthView()));
    await tester.pumpAndSettle();
    final authView = find.byType(AuthView);
    expect(authView, findsOneWidget);

    final goToLoginButton = find.byKey(const Key('SignInButton'));
    expect(goToLoginButton, findsOneWidget);

    await tester.tap(goToLoginButton);
    await tester.pumpAndSettle();

    final passwordButton = find.byKey(const Key('PasswordButton'));
    expect(passwordButton, findsOneWidget);

    await tester.tap(passwordButton);
    await tester.pumpAndSettle();

    final usernameField = find.byKey(const Key('UsernameField'));
    expect(usernameField, findsOneWidget);
    await tester.enterText(usernameField, 'user');
    await tester.pumpAndSettle();

    final loginTile = find.byKey(const Key('LoginButton'));
    expect(loginTile, findsOneWidget);
    await tester.tap(loginTile);

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final passwordField = find.byKey(const Key('PasswordField'));
    expect(passwordField, findsOneWidget);

    await tester.enterText(passwordField, 'password');
    await tester.pumpAndSettle();

    await tester.tap(loginTile);
    await tester.pump(const Duration(seconds: 5));

    // TODO: This waits for lazy [Hive] boxes to finish receiving events, which
    //       should be done in a more strict way.
    for (int i = 0; i < 25; i++) {
      await tester.runAsync(() => Future.delayed(1.milliseconds));
      await tester.pump(const Duration(seconds: 2));
    }

    await tester.pumpAndSettle(const Duration(seconds: 5));

    verify(router.go(Routes.home));

    await Get.deleteAll(force: true);
  });

  tearDown(() async => await database.close());
}

class _FakeGraphQlProvider extends MockedGraphQlProvider {
  @override
  AccessTokenSecret? token;

  @override
  Future<void> Function(AuthorizationException)? authExceptionHandler;

  @override
  Future<void> reconnect() async {}

  var userData = {
    'id': 'me',
    'num': '1234567890123456',
    'login': 'login',
    'name': 'name',
    'emails': {'confirmed': [], 'unconfirmed': null},
    'phones': {'confirmed': []},
    'hasPassword': true,
    'unreadChatsCount': 0,
    'ver': '0',
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
  };

  var blocklist = {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    }
  };

  @override
  Future<SignIn$Mutation$CreateSession$CreateSessionOk> signIn(
    UserPassword password,
    UserLogin? username,
    UserNum? num,
    UserEmail? email,
    UserPhone? phone,
  ) async {
    if (username == null && num == null && email == null && phone == null) {
      throw Exception('Username or num or email or phone must not be null');
    }

    return SignIn$Mutation$CreateSession$CreateSessionOk.fromJson(
      {
        'session': {
          '__typename': 'Session',
          'id': '1ba588ce-d084-486d-9087-3999c8f56596',
          'userAgent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
          'isCurrent': true,
          'lastActivatedAt': DateTime.now().toString(),
          'ver': '031592915314290362597742826064324903711'
        },
        'accessToken': {
          '__typename': 'AccessToken',
          'secret': 'token',
          'expiresAt': DateTime.now().add(const Duration(days: 1)).toString(),
        },
        'refreshToken': {
          '__typename': 'RefreshToken',
          'secret': 'token',
          'expiresAt': DateTime.now().add(const Duration(days: 1)).toString(),
        },
        'user': userData,
      },
    );
  }

  @override
  Stream<QueryResult> recentChatsTopEvents(
    int count, {
    bool noFavorite = false,
    bool? withOngoingCalls,
  }) {
    return Stream.value(
      QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'recentChatsTopEvents': {
            '__typename': 'SubscriptionInitialized',
            'ok': true
          }
        },
        parserFn: (_) => null,
      ),
    );
  }

  @override
  Stream<QueryResult<Object?>> keepOnline() {
    return const Stream.empty();
  }

  @override
  Future<GetBlocklist$Query$Blocklist> getBlocklist({
    BlocklistCursor? after,
    BlocklistCursor? before,
    int? first,
    int? last,
  }) {
    return Future.value(GetBlocklist$Query$Blocklist.fromJson(blocklist));
  }

  @override
  Future<ChatMixin?> getMonolog() async {
    return GetMonolog$Query.fromJson({'monolog': null}).monolog;
  }

  @override
  Future<GetUser$Query> getUser(UserId id) async {
    return GetUser$Query.fromJson({'user': null});
  }

  @override
  Stream<QueryResult> chatEvents(
    ChatId id,
    ChatVersion? ver,
    FutureOr<ChatVersion?> Function() onVer,
  ) {
    Future.delayed(
      Duration.zero,
      () => chatEventsStream.add(QueryResult.internal(
        source: QueryResultSource.network,
        data: {
          'chatEvents': {
            '__typename': 'SubscriptionInitialized',
            'ok': true,
          }
        },
        parserFn: (_) => null,
      )),
    );
    return chatEventsStream.stream;
  }
}
