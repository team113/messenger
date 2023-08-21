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
      welcome: '''Добрый день.
Пожалуйста, отправьте Ваше резюме в формате PDF. В течение 24 часов Вам будет отправлена дата и время интервью.''',
    );
  }
}
