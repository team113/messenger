// import 'dart:convert';
//
// import 'package:file_picker/file_picker.dart';
// import 'package:get/get.dart';
// import 'package:gherkin/gherkin.dart';
// import 'package:messenger/routes.dart';
// import 'package:messenger/ui/page/home/page/user/controller.dart';
//
// import '../world/custom_world.dart';
//
// /// Uploads a new image for [User.avatar] in the currently opened [UserView].
// ///
// /// Examples:
// /// - Then Bob update his avatar with "file.jpg"
// final StepDefinitionGeneric changeUserAvatar = then1<String, CustomWorld>(
//   '{string} update his avatar with {string}',
//       (fileName, context) async {
//     final PlatformFile image = PlatformFile(
//       name: fileName,
//       size: 2,
//       bytes: base64Decode(
//         'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
//       ),
//     );
//
//     final controller = Get.find<UserController>(
//       tag: router.route.split('/')[2],
//     );
//     await controller.updateAvatar(image);
//   },
// );
