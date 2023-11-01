import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/store/chat.dart';

import '../parameters/availability_status.dart';
import '../world/custom_world.dart';

/// Indicates whether the [ChatRepository] contains the chats with the provided
/// [AvailabilityStatus].
///
/// Examples:
/// - Then chats fetched are indeed remote
/// - Then chats fetched are indeed local
final StepDefinitionGeneric chatsAvailability =
    then1<AvailabilityStatus, CustomWorld>(
  'chats fetched are indeed {availability}',
  (status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        final chatRepository = Get.find<AbstractChatRepository>();
        if (chatRepository is ChatRepository) {
          return switch (status) {
            AvailabilityStatus.local => !chatRepository.isRemote,
            AvailabilityStatus.remote => chatRepository.isRemote,
          };
        } else {
          return false;
        }
      },
      timeout: const Duration(seconds: 30),
    );
  },
);
