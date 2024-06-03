// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart' show DisposableInterface;
import 'package:log_me/log_me.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'background.dart';
import 'blocklist.dart';
import 'chat.dart';
import 'chat_item.dart';
import 'chat_member.dart';
import 'common.dart';
import 'connection/connection.dart';
import 'my_user.dart';
import 'settings.dart';
import 'user.dart';

part 'drift.g.dart';

/// [DriftDatabase] storing common and shared between multiple [MyUser]s data.
@DriftDatabase(tables: [Background, Settings, MyUsers])
class CommonDatabase extends _$CommonDatabase {
  CommonDatabase([QueryExecutor? e]) : super(e ?? connect());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, a, b) async {
        Log.info('MigrationStrategy.onUpgrade($a, $b)', '$runtimeType');

        // TODO: Implement proper migrations.
        if (a != b) {
          for (var e in m.database.allTables) {
            await m.deleteTable(e.actualTableName);
          }
        }

        await m.createAll();
      },
      beforeOpen: (_) async {
        Log.debug('MigrationStrategy.beforeOpen()', '$runtimeType');

        await customStatement('PRAGMA foreign_keys = ON;');

        // Note, that WAL doesn't work in Web:
        // https://github.com/simolus3/sqlite3.dart/issues/200
        await customStatement('PRAGMA journal_mode = WAL;');
      },
    );
  }

  /// Creates all tables, triggers, views, indexes and everything else defined
  /// in the database, if they don't exist.
  Future<void> create() async {
    await createMigrator().createAll();
  }

  /// Resets everything, meaning dropping and re-creating every table.
  Future<void> reset() async {
    Log.debug('reset()', '$runtimeType');

    for (var e in allSchemaEntities) {
      if (e is TableInfo) {
        await e.deleteAll();
      } else {
        await createMigrator().drop(e);
      }
    }

    await createMigrator().createAll();
  }
}

/// [DriftDatabase] storing [MyUser] scoped data.
@DriftDatabase(
  tables: [Blocklist, Chats, ChatItems, ChatItemViews, ChatMembers, Users],
  queries: {
    'chatItemsAround': ''
        'SELECT * FROM '
        '(SELECT * FROM chat_item_views '
        'INNER JOIN chat_items ON chat_items.id = chat_item_views.chat_item_id '
        'WHERE chat_item_views.chat_id = :chat_id AND at <= :at '
        'ORDER BY at DESC LIMIT :before + 1) as a '
        'UNION '
        'SELECT * FROM '
        '(SELECT * FROM chat_item_views '
        'INNER JOIN chat_items ON chat_items.id = chat_item_views.chat_item_id '
        'WHERE chat_item_views.chat_id = :chat_id AND at > :at '
        'ORDER BY at ASC LIMIT :after) as b '
        'ORDER BY at ASC;',
  },
)
class ScopedDatabase extends _$ScopedDatabase {
  ScopedDatabase(this.userId, [QueryExecutor? e]) : super(e ?? connect(userId));

  /// [UserId] this [ScopedDatabase] is linked to.
  final UserId userId;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, a, b) async {
        Log.info('MigrationStrategy.onUpgrade($a, $b)', '$runtimeType');

        // TODO: Implement proper migrations.
        if (a != b) {
          for (var e in m.database.allTables) {
            await m.deleteTable(e.actualTableName);
          }
        }

        await m.createAll();
      },
      beforeOpen: (_) async {
        Log.debug('MigrationStrategy.beforeOpen()', '$runtimeType');

        await customStatement('PRAGMA foreign_keys = ON;');

        // Note, that WAL doesn't work in Web:
        // https://github.com/simolus3/sqlite3.dart/issues/200
        await customStatement('PRAGMA journal_mode = WAL;');
      },
    );
  }

  /// Creates all tables, triggers, views, indexes and everything else defined
  /// in the database, if they don't exist.
  Future<void> create() async {
    await createMigrator().createAll();
  }

  /// Resets everything, meaning dropping and re-creating every table.
  Future<void> reset() async {
    Log.debug('reset()', '$runtimeType');

    for (var e in allSchemaEntities) {
      if (e is TableInfo) {
        await e.deleteAll();
      } else {
        await createMigrator().drop(e);
      }
    }

    await createMigrator().createAll();
  }
}

/// [CommonDatabase] provider.
final class CommonDriftProvider extends DisposableInterface {
  /// Constructs a [CommonDriftProvider] with the in-memory database.
  CommonDriftProvider.memory() : db = CommonDatabase(inMemory());

  /// Constructs a [CommonDriftProvider] with the provided [db].
  CommonDriftProvider.from(this.db);

  /// [CommonDatabase] itself.
  ///
  /// `null` here means the database is closed.
  CommonDatabase? db;

  @override
  void onInit() async {
    Log.debug('onInit()', '$runtimeType');
    await db?.create();
    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');
    db = null;
    super.onClose();
  }

  /// Closes this [CommonDriftProvider].
  @visibleForTesting
  Future<void> close() async {
    final Future<void>? future = db?.close();
    db = null;
    await future;
  }

  /// Resets the [CommonDatabase] and closes this [CommonDriftProvider].
  Future<void> reset() async {
    final Future<void>? future = db?.reset();
    db = null;
    await future;
  }
}

/// [ScopedDatabase] provider.
final class ScopedDriftProvider extends DisposableInterface {
  /// Constructs a [ScopedDriftProvider] with the in-memory database.
  ScopedDriftProvider.memory()
      : db = ScopedDatabase(const UserId('me'), inMemory());

  /// Constructs a [ScopedDriftProvider] with the provided [db].
  ScopedDriftProvider.from(this.db);

  /// [ScopedDatabase] itself.
  ///
  /// `null` here means the database is closed.
  ScopedDatabase? db;

  /// [Completer]s of [wrapped] operations to await in [onClose].
  final List<Completer> _completers = [];

  /// [StreamController]s of [stream]s to cancel in [onClose].
  final List<StreamController> _controllers = [];

  /// [StreamSubscription]s to executors of [stream]s to cancel in [onClose].
  final List<StreamSubscription> _subscriptions = [];

  @override
  void onInit() async {
    Log.debug('onInit()', '$runtimeType');
    await db?.create();
    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    final ScopedDatabase? connection = db;
    db = null;

    // Close all the active streams.
    for (var e in _subscriptions) {
      e.cancel();
    }
    for (var e in _controllers) {
      e.close();
    }

    // Wait for all operations to complete, disallowing new ones.
    Future.wait(_completers.map((e) => e.future)).then((_) async {
      await connection?.close();
    });

    super.onClose();
  }

  /// Closes this [ScopedDriftProvider].
  @visibleForTesting
  Future<void> close() async {
    final Future<void>? future = db?.close();
    db = null;
    await future;
  }

  /// Resets the [ScopedDatabase] and closes this [ScopedDriftProvider].
  Future<void> reset() async {
    final Future<void>? future = db?.reset();
    db = null;
    await future;
  }

  /// Completes the provided [action] in a wrapped safe environment.
  Future<T?> wrapped<T>(Future<T?> Function(ScopedDatabase) action) async {
    if (isClosed || db == null) {
      return null;
    }

    final Completer completer = Completer();
    _completers.add(completer);

    try {
      return await action(db!);
    } finally {
      completer.complete();
      _completers.remove(completer);
    }
  }

  /// Returns the [Stream] executed in a wrapped safe environment.
  Stream<T> stream<T>(Stream<T> Function(ScopedDatabase db) executor) {
    if (isClosed || db == null) {
      return const Stream.empty();
    }

    StreamSubscription? subscription;
    StreamController<T>? controller;

    controller = StreamController(
      onListen: () {
        if (isClosed || db == null) {
          return;
        }

        if (subscription != null) {
          subscription?.cancel();
          _subscriptions.remove(subscription);
        }

        subscription = executor(db!).listen(
          controller?.add,
          onError: controller?.addError,
          onDone: () => controller?.close(),
        );

        _subscriptions.add(subscription!);
      },
      onCancel: () {
        if (subscription != null) {
          subscription?.cancel();
          _subscriptions.remove(subscription);
        }
      },
    );
    _controllers.add(controller);

    return controller.stream;
  }
}

/// [CommonDriftProvider] with common helper and utility methods over it.
abstract class DriftProviderBase extends DisposableInterface {
  DriftProviderBase(this._provider);

  /// [CommonDriftProvider] itself.
  final CommonDriftProvider _provider;

  /// Returns the [CommonDatabase].
  ///
  /// `null` here means the database is closed.
  CommonDatabase? get db => _provider.db;

  /// Completes the provided [action] as a [db] transaction.
  Future<void> txn<T>(Future<T> Function() action) async {
    if (isClosed || db == null) {
      return;
    }

    await db?.transaction(action);
  }

  /// Runs the [callback] through a non-closed [CommonDatabase], or returns
  /// `null`.
  ///
  /// [CommonDatabase] may be closed, for example, between E2E tests.
  Future<T?> safe<T>(Future<T> Function(CommonDatabase db) callback) async {
    if (isClosed || db == null) {
      return null;
    }

    return await callback(db!);
  }
}

/// [ScopedDriftProvider] with common helper and utility methods over it.
abstract class DriftProviderBaseWithScope extends DisposableInterface {
  DriftProviderBaseWithScope(this._common, this._scoped);

  /// [CommonDriftProvider] itself.
  final CommonDriftProvider _common;

  /// [ScopedDriftProvider] itself.
  final ScopedDriftProvider _scoped;

  /// Returns the [CommonDatabase].
  ///
  /// `null` here means the database is closed.
  CommonDatabase? get common => _common.db;

  /// Completes the provided [action] as a [ScopedDriftProvider] transaction.
  Future<void> txn<T>(Future<T> Function() action) async {
    await _scoped.wrapped((db) async {
      await db.transaction(action);
    });
  }

  /// Runs the [callback] through a non-closed [ScopedDatabase], or returns
  /// `null`.
  ///
  /// [ScopedDatabase] may be closed, for example, between E2E tests.
  Future<T?> safe<T>(Future<T> Function(ScopedDatabase db) callback) async {
    if (PlatformUtils.isWeb) {
      // WAL doesn't work in Web, thus guard all the writes/reads with Web Locks
      // API: https://github.com/simolus3/sqlite3.dart/issues/200
      return await WebUtils.protect(
        tag: '${_scoped.db?.userId}',
        () async => await _scoped.wrapped(callback),
      );
    }

    return await _scoped.wrapped(callback);
  }

  /// Listens to the [executor] through a non-closed [ScopedDatabase].
  ///
  /// [ScopedDatabase] may be closed, for example, between E2E tests.
  Stream<T> stream<T>(Stream<T> Function(ScopedDatabase db) executor) {
    return _scoped.stream(executor);
  }
}
