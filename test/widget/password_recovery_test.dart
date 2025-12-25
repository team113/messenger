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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/provider/drift/account.dart';
import 'package:messenger/provider/drift/credentials.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/locks.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/secret.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
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

@GenerateNiceMocks([
  MockSpec<GraphQlProvider>(),
  MockSpec<PlatformRouteInformationProvider>(),
])
void main() async {
  PlatformUtils = PlatformUtilsMock();
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.disableInfiniteAnimations = true;

  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  await L10n.init();

  var graphQlProvider = MockGraphQlProvider();
  when(
    graphQlProvider.onStart,
  ).thenReturn(InternalFinalCallback(callback: () {}));
  when(
    graphQlProvider.onDelete,
  ).thenReturn(InternalFinalCallback(callback: () {}));
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});

  final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final userProvider = UserDriftProvider(common, scoped);
  final locksProvider = Get.put(LockDriftProvider(common));
  final secretsProvider = Get.put(RefreshSecretDriftProvider(common));

  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      theme: Themes.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('LoginView successfully recovers account access', (
    WidgetTester tester,
  ) async {
    Get.put(myUserProvider);
    Get.put(userProvider);
    Get.put<GraphQlProvider>(graphQlProvider);
    Get.put(credentialsProvider);

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(
          AuthRepository(Get.find(), myUserProvider, credentialsProvider),
        ),
        credentialsProvider,
        accountProvider,
        locksProvider,
        secretsProvider,
      ),
    );

    router = RouterState(authService);
    router.provider = MockPlatformRouteInformationProvider();

    authService.init();

    when(
      graphQlProvider.createConfirmationCode(
        MyUserIdentifier(login: UserLogin('login')),
        locale: 'en-US',
      ),
    ).thenAnswer((_) => Future.value());

    when(
      graphQlProvider.validateConfirmationCode(
        identifier: MyUserIdentifier(login: UserLogin('login')),
        code: ConfirmationCode('1234'),
      ),
    ).thenAnswer((_) => Future.value());

    when(
      graphQlProvider.updateUserPassword(
        identifier: MyUserIdentifier(login: UserLogin('login')),
        confirmation: MyUserCredentials(code: ConfirmationCode('1234')),
        newPassword: UserPassword('test123'),
      ),
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
      graphQlProvider.createConfirmationCode(
        MyUserIdentifier(login: UserLogin('login')),
        locale: 'en-US',
      ),
      graphQlProvider.validateConfirmationCode(
        identifier: MyUserIdentifier(login: UserLogin('login')),
        code: ConfirmationCode('1234'),
      ),
      graphQlProvider.updateUserPassword(
        identifier: MyUserIdentifier(login: UserLogin('login')),
        confirmation: MyUserCredentials(code: ConfirmationCode('1234')),
        newPassword: UserPassword('test123'),
      ),
    ]);

    common.close();
    scoped.close();

    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(() => Future.delayed(1.milliseconds));
    }

    await Get.deleteAll(force: true);
  });
}
