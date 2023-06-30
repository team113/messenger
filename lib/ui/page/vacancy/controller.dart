import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/model/vacancy.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/text_field.dart';

class VacancyController extends GetxController {
  VacancyController(this._authService);

  final AuthService _authService;

  final Rx<Vacancy?> vacancy = Rx(null);

  late final TextFieldState email = TextFieldState(
    onChanged: (s) {
      try {
        if (s.text.isNotEmpty) {
          UserEmail(s.text.toLowerCase());
        }

        s.error.value = null;
      } on FormatException {
        s.error.value = 'err_incorrect_email'.l10n;
      }
    },
  );
  late final Rx<NativeFile?> resume = Rx(null);
  late final TextFieldState text = TextFieldState();

  Future<void> pick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'doc',
        'rtf',
        'docx',
        'pdf',
        'jpeg',
        'jpg',
        'png',
      ],
      allowMultiple: false,
      withReadStream: true,
    );

    if (result != null && result.files.isNotEmpty) {
      resume.value = NativeFile.fromPlatformFile(result.files.first);
    }
  }

  Future<void> send() async {
    if (_authService.status.value.isEmpty) {
      await _authService.register();
      router.home();

      while (!Get.isRegistered<ChatService>()) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final ChatService chatService = Get.find();

      final chat = await chatService.get(
        ChatId.local(const UserId('a3f14328-c844-4666-887f-d70127c3cb31')),
      );

      if (chat != null) {
        router.chat(chat.id, push: true);

        final attachment = LocalAttachment(
          resume.value!,
          status: SendingStatus.sending,
        );
        chatService.uploadAttachment(attachment);

        await chatService.sendChatMessage(
          chat.id,
          attachments: [attachment],
          text: ChatMessageText('''Vacancy: ${vacancy.value!.title}
E-mail: ${email.text}
Message: ${text.text.isEmpty ? '-' : text.text}
'''),
        );
      }
    }
  }
}
