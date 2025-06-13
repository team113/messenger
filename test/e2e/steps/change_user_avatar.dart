import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Uploads a new image for [User.avatar] in the currently opened [UserView].
///
/// Examples:
/// - Then Bob update his avatar with "file.jpg"
final StepDefinitionGeneric
changeUserAvatar = and2<TestUser, String, CustomWorld>(
  '{user} update his avatar with {string}',
  (TestUser user, String fileName, context) async {

    final PlatformFile image = PlatformFile(
      name: fileName,
      size: 2,
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );

    final file = NativeFile.fromPlatformFile(image);

    dio.MultipartFile? upload;


    await file.ensureCorrectMediaType();

    if (file.stream != null) {
      upload = dio.MultipartFile.fromStream(
            () => file.stream!,
        file.size,
        filename: file.name,
        contentType: file.mime,
      );
    } else if (file.bytes.value != null) {
      upload = dio.MultipartFile.fromBytes(
        file.bytes.value!,
        filename: file.name,
        contentType: file.mime,
      );
    } else if (file.path != null) {
      upload = await dio.MultipartFile.fromFile(
        file.path!,
        filename: file.name,
        contentType: file.mime,
      );
    }

    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.token;
    await provider.updateUserAvatar(upload, null);
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
