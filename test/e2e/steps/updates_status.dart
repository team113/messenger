import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Updates the [UserTextStatus] of the provided [TestUser].
final StepDefinitionGeneric updateStatus = then2<TestUser, String, CustomWorld>(
  RegExp(r'{user} updates (?:his|her) status with {string}$'),
      (TestUser user, String newStatus, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.token;
    await provider.updateUserStatus(UserTextStatus(newStatus));

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
