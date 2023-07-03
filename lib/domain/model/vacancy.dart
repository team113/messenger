class Vacancy {
  const Vacancy({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

class Vacancies {
  static const _desc = '''О проекте:

- мессенджер Gapopa;
- фронтэнд часть с открытым исходным кодом;
- используется GetX в качестве DI и State Management;
- используется Navigator 2.0 (Router) в качестве навигации;
- используется Hive в качестве локальной базы данных;
- используется Firebase для push уведомлений;
- используется GraphQL и Artemis для общения с бэкэндом;
- используется Gherkin для написания E2E тестов;
- подробнее: https://github.com/team113/messenger


Обязанности:

- разработка, тестирование и поддержка проекта на Flutter.


Требования:

- понимание принципов UX дизайна для мобильных устройств;
- знание GraphQL и понимание как использовать его через WebSocket;
- понимание принципов работы WebRTC (желательно);
- трепетное отношение к коду и умение качественно его документировать;
- понимание необходимости автоматического тестирования и опыт его применения;
- умение читать и понимать техническую литературу на английском языке;
- наличие широкого Интернет-канала и настроенной программы Skype, позволяющих поддерживать качественную видеосвязь.


Условия:

- полная занятость;
- начальная ставка заработной платы от 2000 EUR в месяц;
- ежедневное зачисление заработной платы;
- удалённое сотрудничество;
- предусмотрен учёт рабочего времени;
- рабочее время: с 11:30 по 13:00 UTC находиться онлайн обязательно, остальное время выбирается самостоятельно по согласованию с тимлидом.


Дополнительно:

- оказывается помощь при переезде в одну из штаб-квартир компании.
''';

  static const List<Vacancy> all = [
    Vacancy(
      id: 'parner',
      title: 'Партнёрская программа',
      description: _desc,
    ),
    Vacancy(
      id: 'dart',
      title: 'Flutter/Dart Developer',
      description: _desc,
    ),
    Vacancy(
      id: 'rust',
      title: 'Rust Developer',
      description: _desc,
    ),
    Vacancy(
      id: 'ui',
      title: 'UI/UX Designer',
      description: _desc,
    ),
    Vacancy(
      id: 'ai',
      title: 'AI Specialist',
      description: _desc,
    ),
  ];
}
