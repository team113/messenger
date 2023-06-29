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
  static const _desc = '''Обязанности:

- разработка, тестирование и поддержка проекта на Flutter.

Требования:

- опыт разработки приложений на Flutter под Android и iOS;
- понимание принципов UX дизайна для мобильных устройств;
- знание GraphQL и понимание как использовать его через WebSocket;
- понимание принципов работы WebRTC (желательно);
- трепетное отношение к коду и умение качественно его документировать;
- понимание необходимости автоматического тестирования и опыт его применения;
- умение читать и понимать техническую литературу на английском языке;
- наличие широкого Интернет-канала и настроенной программы Skype, позволяющих поддерживать качественную видеосвязь.


Условия:

- полная занятость;
- ставка заработной платы от 2000 EUR в месяц;
- удаленное сотрудничество;

Дополнительно:

- Предоставляется возможность ПЕРЕЕЗДА в одну из штаб-квартир компании (на постоянной или временной основе). Оплачиваем перелет и проживание.
''';

  static const List<Vacancy> all = [
    Vacancy(
      id: 'parner',
      title: 'Партнёрская программа',
      description: _desc,
    ),
    Vacancy(
      id: 'frontend',
      title: 'Frontend Developer',
      description: _desc,
    ),
    Vacancy(
      id: 'backend',
      title: 'Backend Developer',
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
