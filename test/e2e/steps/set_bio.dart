import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Sets [UserBio] of provided [TestUser]
final StepDefinitionGeneric setBio = then2<TestUser, String, CustomWorld>(
  '{user} set bio as {string}',
  (TestUser user, String newBio, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.session.token;
    await provider.updateUserBio(UserBio(newBio));
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
