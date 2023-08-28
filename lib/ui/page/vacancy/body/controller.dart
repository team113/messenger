import 'dart:ui';

import 'package:get/get.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mutex/mutex.dart';

class VacancyBodyController extends GetxController {
  VacancyBodyController(this._authService);

  final RxList<GitHubIssue> issues = RxList();
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  final RxnInt expanded = RxnInt(null);

  final AuthService _authService;

  bool get authorized => _authService.status.value.isSuccess;

  final Mutex _issuesGuard = Mutex();

  @override
  void onInit() {
    fetchIssues();
    super.onInit();
  }

  Future<void> useLink(String? welcome) async {
    router.useLink(
      'HR-Gapopa',
      welcome: welcome ??
          '''Добрый день.
Пожалуйста, отправьте Ваше резюме в формате PDF. В течение 24 часов Вам будет отправлена дата и время интервью.''',
    );
  }

  void fetchIssues() async {
    await _issuesGuard.protect(() async {
      status.value = RxStatus.loading();

      if (issues.isNotEmpty) {
        return;
      }

      final response = await (await PlatformUtils.dio).get(
        'https://api.github.com/repos/team113/messenger/issues?labels=help wanted',
      );

      if (response.statusCode == 200) {
        issues.value = (response.data as List<dynamic>).map((e) {
          return GitHubIssue(
            title: e['title'],
            description: e['body'],
            url: e['html_url'],
            labels: (e['labels'] as List<dynamic>)
                .map(
                  (e) =>
                      (e['name'] as String, (e['color'] as String).toColor()),
                )
                .toList(),
          );
        }).toList();

        status.value = RxStatus.success();
      } else {
        status.value = RxStatus.error(response.statusMessage);
      }
    });
  }
}

class GitHubIssue {
  const GitHubIssue({
    required this.title,
    this.description,
    this.status = GitHubStatus.todo,
    this.url = '',
    this.labels = const [],
  });

  final String title;
  final String? description;
  final GitHubStatus status;
  final String url;
  final List<(String, Color)> labels;
}

enum GitHubStatus { todo, wip, done }

extension ColorExtension on String {
  Color toColor() {
    var hexColor = replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }

    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    }

    return const Color(0xFF888888);
  }
}
