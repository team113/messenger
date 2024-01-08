import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/chat_call.dart';
import '/domain/model/chat.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] temporary storage for [ChatCallCredentials].
class TemporaryChatCallCredentialsHiveProvider
    extends HiveBaseProvider<ChatCallCredentials> {
  TemporaryChatCallCredentialsHiveProvider();

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'temporary_chat_call_credentials';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');
    Hive.maybeRegisterAdapter(ChatCallCredentialsAdapter());
  }

  /// Puts the provided [ChatCallCredentials] to [Hive].
  Future<void> put(ChatId chatId, ChatCallCredentials creds) async {
    Log.debug('put($chatId, $creds)', '$runtimeType');
    await putSafe(chatId.val, creds);
  }

  /// Returns a [ChatCallCredentials] from [Hive] by the provided [ChatId].
  ChatCallCredentials? get(ChatId chatId) {
    Log.debug('get($chatId)', '$runtimeType');
    return getSafe(chatId.val);
  }

  /// Removes a [ChatCallCredentials] from [Hive] by the provided [ChatId].
  Future<void> remove(ChatId chatId) async {
    Log.debug('remove($chatId)', '$runtimeType');
    await deleteSafe(chatId.val);
  }
}
