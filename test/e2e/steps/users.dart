import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Creates a new [MyUser] and signs him in.
///
/// Examples:
/// - Given I am Alice
final StepDefinitionGeneric iAm = given1<TestUser, CustomWorld>(
  'I am {user}',
  (TestUser user, context) async {
    var password = UserPassword('123');

    await createUser(
      user,
      context.world,
      password: password,
    );

    await Get.find<AuthService>().signIn(
      password,
      num: context.world.sessions[user.name]?.userNum,
    );

    router.home();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Signs in as the provided [TestUser] created earlier in the [iAm] step.
///
/// Examples:
/// - `I sign in as Alice`
final StepDefinitionGeneric signInAs = then1<TestUser, CustomWorld>(
  'I sign in as {user}',
  (TestUser user, context) async {
    var password = UserPassword('123');

    await Get.find<AuthService>()
        .signIn(password, num: context.world.sessions[user.name]!.userNum);

    router.home();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates a new [User] identified by the provided name.
///
/// Examples:
/// - `Given user Bob`
final StepDefinitionGeneric user = given1<TestUser, CustomWorld>(
  'user {user}',
  (TestUser name, context) => createUser(name, context.world),
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Creates two new [User]s identified by the provided names.
///
/// Examples:
/// - `Given users Bob and Charlie`
final twoUsers = given2<TestUser, TestUser, CustomWorld>(
  'users {user} and {user}',
  (TestUser user1, TestUser user2, context) async {
    await createUser(user1, context.world);
    await createUser(user2, context.world);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Route to provided [TestUser] page
final StepDefinitionGeneric goToUserPage = then1<TestUser, CustomWorld>(
  'I go to {user} page',
  (TestUser user, context) async {
    router.user(context.world.sessions[user.name]!.userId);
    await context.world.appDriver.waitForAppToSettle();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
