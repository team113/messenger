import 'package:drift/drift.dart';

import 'drift.dart';

@DataClassName('ChatDraftRow')
class ChatDrafts extends Table {
  @override
  Set<Column> get primaryKey => {chatId, authorId};

  TextColumn get chatId => text()();
  TextColumn get authorId => text()();
  TextColumn get data => text()();
}

class ChatDraftDriftProvider extends DriftProviderBase {
  ChatDraftDriftProvider(super.database);
}
