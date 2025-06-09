// import 'package:flutter_gherkin/flutter_gherkin.dart';
// import 'package:get/get.dart';
// import 'package:gherkin/gherkin.dart';
// import 'package:messenger/domain/model/avatar.dart';
// import 'package:messenger/domain/model/chat.dart';
// import 'package:messenger/domain/model/user.dart';
// import 'package:messenger/domain/repository/chat.dart';
// import 'package:messenger/domain/repository/user.dart';
// import 'package:messenger/domain/service/chat.dart';
// import 'package:messenger/domain/service/user.dart';
// import 'package:messenger/routes.dart';
//
// import '../world/custom_world.dart';
//
// /// Waits until the [UserAvatar] being displayed is indeed the provided image.
// ///
// /// Examples:
// /// - Then I see Bob's avatar as "test.jpg"
// final StepDefinitionGeneric seeUserAvatarAs = then1<String, CustomWorld>(
//   RegExp(r'I see {string} avatar as {string}'),
//   // TODO: [filename] should be used.
//       (String filename, context) async {
//     await context.world.appDriver.waitUntil(() async {
//       await context.world.appDriver.waitForAppToSettle();
//
//       final RxUser? user =
//       Get.find<UserService>().users[UserId(router.route.split('/')[2])];
//
//       final finder = context.world.appDriver.findByDescendant(
//         context.world.appDriver.findBy('UserAvatar_${user?.id}', FindType.key),
//         context.world.appDriver.findBy(
//           'Image_${user?.user.value.avatar}',
//           FindType.key,
//         ),
//         firstMatchOnly: true,
//       );
//
//       return context.world.appDriver.isPresent(finder);
//     }, timeout: const Duration(seconds: 30));
//   },
//   configuration: StepDefinitionConfiguration()
//     ..timeout = const Duration(minutes: 5),
// );
//
//
// /// Waits until the [ChatAvatar] being displayed has no image in it.
// ///
// /// Examples:
// /// - Then I see chat avatar as none
// final StepDefinitionGeneric seeChatAvatarAsNone = then<CustomWorld>(
//   RegExp(r'I see chat avatar as none'),
//       (context) async {
//     await context.world.appDriver.waitUntil(() async {
//       await context.world.appDriver.waitForAppToSettle();
//
//       final RxChat? chat =
//       Get.find<ChatService>().chats[ChatId(router.route.split('/')[2])];
//
//       if (chat?.avatar.value == null) {
//         final finder = context.world.appDriver.findBy(
//           'ChatAvatar_${chat?.id}',
//           FindType.key,
//         );
//         return context.world.appDriver.isPresent(finder);
//       }
//
//       return false;
//     });
//   },
//   configuration: StepDefinitionConfiguration()
//     ..timeout = const Duration(minutes: 5),
// );
//
