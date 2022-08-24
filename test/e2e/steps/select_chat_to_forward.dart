import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';

import '../configuration.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Selects the chats to forward messages inside the [ChatForwardView].
///
/// Examples:
/// - Then I select chat with Bob to forward
/// - Then I select chat with Charlie to forward
final StepDefinitionGeneric selectChatToForward = then1<TestUser, CustomWorld>(
  'I select chat with {user} to forward',
  (user, context) async {
    await context.world.appDriver.waitForAppToSettle();

    RxChat? chat = await Get.find<ChatService>()
        .get(context.world.sessions[user.name]!.dialog!);

    Finder finder = context.world.appDriver
        .findByKeySkipOffstage('ChatForwardTile_${chat!.chat.value.id}');

    await context.world.appDriver.tap(finder);
    await context.world.appDriver.waitForAppToSettle();
  },
);
