import 'package:get/get.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/routes.dart';

class VacancyBodyController extends GetxController {
  VacancyBodyController(this._authService);

  final AuthService _authService;

  bool get authorized => _authService.status.value.isSuccess;

  Future<void> useLink() async {
    router.useLink(
      'HR-Gapopa',
//       welcome: '''

// Собеседования проводятся с 00:00 по 00:00.

// ''',
      welcome: '''Здравствуйте, уважаемый соискатель.

Для более предметного диалога просим Вас выслать резюме.

С уважением,
Роман
HR-менеджер Gapopa
''',
    );
  }
}
