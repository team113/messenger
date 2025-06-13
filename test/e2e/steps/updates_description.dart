import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Updates the [UserBio] of the provided [TestUser].
final StepDefinitionGeneric updateDescription = then2<TestUser, String, CustomWorld>(
  RegExp(r'{user} updates (?:his|her) description with {string}$'),
      (TestUser user, String newBio, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.token;
    await provider.updateUserBio(UserBio(newBio));
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

