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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/account.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/login/controller.dart';
import 'package:messenger/ui/page/login/view.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/platform_utils.dart';
import 'password_recovery_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  PlatformUtils = PlatformUtilsMock();
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.disableInfiniteAnimations = true;

  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  Hive.init('./test/.temp_hive/password_recovery');

  await L10n.init();

  var credentialsProvider = CredentialsHiveProvider();
  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  await credentialsProvider.init();
  await credentialsProvider.clear();
  final accountProvider = AccountHiveProvider();
  await accountProvider.init();
  var contactProvider = ContactHiveProvider();
  await contactProvider.init();
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final userProvider = UserDriftProvider(common, scoped);
  var chatProvider = ChatHiveProvider();
  await chatProvider.init();

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      theme: Themes.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('LoginView successfully recovers account access',
      (WidgetTester tester) async {
    Get.put(myUserProvider);
    Get.put(contactProvider);
    Get.put(userProvider);
    Get.put<GraphQlProvider>(graphQlProvider);
    Get.put(credentialsProvider);
    Get.put(chatProvider);

    AuthService authService = Get.put(
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

    router = RouterState(authService);
    router.provider = MockPlatformRouteInformationProvider();

    when(
      graphQlProvider.validateUserPasswordRecoveryCode(
          UserLogin('login'), null, null, null, ConfirmationCode('1234')),
    ).thenAnswer((_) => Future.value());
    when(
      graphQlProvider.resetUserPassword(UserLogin('login'), null, null, null,
          ConfirmationCode('1234'), UserPassword('test123')),
    ).thenAnswer((_) => Future.value());

    await tester.pumpWidget(
      createWidgetForTesting(
        child: const LoginView(initial: LoginViewStage.signInWithPassword),
      ),
    );
    await tester.pumpAndSettle();

    final accessRecoveryTile = find.text('btn_forgot_password'.l10n);
    expect(accessRecoveryTile, findsOneWidget);

    await tester.tap(accessRecoveryTile);
    await tester.pumpAndSettle();

    final usernameField = find.byKey(const Key('RecoveryField'));
    expect(usernameField, findsOneWidget);

    await tester.enterText(usernameField, 'login');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('Proceed')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final codeField = find.byKey(const ValueKey('RecoveryCodeField'));
    expect(codeField, findsOneWidget);

    await tester.enterText(codeField, '1234');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('Proceed')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final password1 = find.byKey(const ValueKey('PasswordField'));
    expect(password1, findsOneWidget);
    final password2 = find.byKey(const ValueKey('RepeatPasswordField'));
    expect(password2, findsOneWidget);

    await tester.enterText(password1, 'test123');
    await tester.enterText(password2, 'test123');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('Proceed')));
    await tester.pumpAndSettle();

    verifyInOrder([
      graphQlProvider.recoverUserPassword(UserLogin('login'), null, null, null),
      graphQlProvider.validateUserPasswordRecoveryCode(
          UserLogin('login'), null, null, null, ConfirmationCode('1234')),
      graphQlProvider.resetUserPassword(UserLogin('login'), null, null, null,
          ConfirmationCode('1234'), UserPassword('test123')),
    ]);

    await Future.wait([common.close(), scoped.close()]);
    await Get.deleteAll(force: true);
  });
}
