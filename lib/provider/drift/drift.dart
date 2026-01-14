// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '/config.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/service/disposable_service.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'account.dart';
import 'background.dart';
import 'blocklist.dart';
import 'cache.dart';
import 'call_credentials.dart';
import 'call_rect.dart';
import 'callkit_calls.dart';
import 'chat.dart';
import 'chat_credentials.dart';
import 'chat_item.dart';
import 'chat_member.dart';
import 'common.dart';
import 'connection/connection.dart';
import 'credentials.dart';
import 'download.dart';
import 'draft.dart';
import 'geolocation.dart';
import 'locks.dart';
import 'monolog.dart';
import 'my_user.dart';
import 'secret.dart';
import 'session.dart';
import 'settings.dart';
import 'skipped_version.dart';
import 'slugs.dart';
import 'user.dart';
import 'version.dart';
import 'window.dart';

part 'drift.g.dart';

/// [DriftDatabase] storing common and shared between multiple [MyUser]s data.
@DriftDatabase(
  tables: [
    Accounts,
    Background,
    Cache,
    CacheSummary,
    CallKitCalls,
    Downloads,
    GeoLocations,
    Locks,
    MyUsers,
    RefreshSecrets,
    Settings,
    SkippedVersions,
    Slugs,
    Tokens,
    Versions,
    WindowRectangles,
  ],
)
class CommonDatabase extends _$CommonDatabase {
  CommonDatabase([QueryExecutor? e]) : super(e ?? connect());

  /// Indicator whether this database has been already closed.
  bool _closed = false;

  @override
  int get schemaVersion => Config.commonVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        Log.info('MigrationStrategy.onUpgrade($from, $to)', '$runtimeType');

        if (_closed) {
          return;
        }

        if (from != to) {
          bool migrated = false;

          try {
            if (to >= 7 && from <= 6) {
              await m.addColumn(settings, settings.videoVolume);
              migrated = true;
            }

            if (to >= 6 && from <= 5) {
              await m.addColumn(settings, settings.noiseSuppression);
              await m.addColumn(settings, settings.noiseSuppressionLevel);
              await m.addColumn(settings, settings.echoCancellation);
              await m.addColumn(settings, settings.autoGainControl);
              await m.addColumn(settings, settings.highPassFilter);
              migrated = true;
            }

            if (to >= 5 && from <= 4) {
              await m.addColumn(settings, settings.muteKeys);
              migrated = true;
            }

            if (to >= 4 && from <= 3) {
              await m.addColumn(versions, versions.blocklistVersion);
              await m.addColumn(versions, versions.blocklistCount);
              migrated = true;
            }

            if (to >= 3 && from <= 2) {
              await m.addColumn(myUsers, myUsers.welcomeMessage);
              migrated = true;
            }

            if (to >= 2 && from <= 1) {
              await m.addColumn(versions, versions.sessionsListVersion);
              migrated = true;
            }
          } catch (e) {
            // Should log the error, but proceed with initialization, as
            // otherwise `drift` won't allow application to run at all.
            Log.error(
              'Unable to perform migrations due to: $e',
              '$runtimeType',
            );
          }

          if (!migrated) {
            Log.info(
              'MigrationStrategy.onUpgrade($from, $to) -> migration did not succeed, thus deleting the tables',
              '$runtimeType',
            );

            for (var e in m.database.allTables) {
              await m.deleteTable(e.actualTableName);
            }
          } else {
            Log.info(
              'MigrationStrategy.onUpgrade($from, $to) -> migration did succeed',
              '$runtimeType',
            );
          }
        }

        await m.createAll();
      },
      beforeOpen: (_) async {
        Log.debug('MigrationStrategy.beforeOpen()', '$runtimeType');

        if (_closed) {
          return;
        }

        try {
          await customStatement('PRAGMA foreign_keys = ON;');

          // Note, that WAL doesn't work in Web:
          // https://github.com/simolus3/sqlite3.dart/issues/200
          await customStatement('PRAGMA journal_mode = WAL;');
        } catch (e) {
          Log.error('Custom SQL statement has failed: $e', '$runtimeType');
        }
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
  tables: [
    Blocklist,
    CallCredentials,
    CallRectangles,
    ChatCredentials,
    ChatItems,
    ChatItemViews,
    ChatMembers,
    Chats,
    Drafts,
    Monologs,
    Sessions,
    Users,
  ],
  queries: {
    'chatItemsAround':
        ''
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
    'chatItemsAroundBottomless':
        ''
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
        'ORDER BY at ASC) as b '
        'ORDER BY at ASC;',
    'chatItemsAroundTopless':
        ''
        'SELECT * FROM '
        '(SELECT * FROM chat_item_views '
        'INNER JOIN chat_items ON chat_items.id = chat_item_views.chat_item_id '
        'WHERE chat_item_views.chat_id = :chat_id AND at <= :at '
        'ORDER BY at DESC) as a '
        'UNION '
        'SELECT * FROM '
        '(SELECT * FROM chat_item_views '
        'INNER JOIN chat_items ON chat_items.id = chat_item_views.chat_item_id '
        'WHERE chat_item_views.chat_id = :chat_id AND at > :at '
        'ORDER BY at ASC LIMIT :after) as b '
        'ORDER BY at ASC;',
    'attachmentsAround':
        ''
        'SELECT * FROM '
        '(SELECT * FROM chat_item_views '
        'INNER JOIN chat_items ON chat_items.id = chat_item_views.chat_item_id '
        'WHERE chat_item_views.chat_id = :chat_id AND at <= :at AND chat_items.data LIKE \'%"attachments":[{%\' '
        'ORDER BY at DESC LIMIT :before + 1) as a '
        'UNION '
        'SELECT * FROM '
        '(SELECT * FROM chat_item_views '
        'INNER JOIN chat_items ON chat_items.id = chat_item_views.chat_item_id '
        'WHERE chat_item_views.chat_id = :chat_id AND at > :at AND chat_items.data LIKE \'%"attachments":[{%\' '
        'ORDER BY at ASC LIMIT :after) as b '
        'ORDER BY at ASC;',
  },
)
class ScopedDatabase extends _$ScopedDatabase {
  ScopedDatabase(this.userId, [QueryExecutor? e]) : super(e ?? connect(userId));

  /// [UserId] this [ScopedDatabase] is linked to.
  final UserId userId;

  /// Indicator whether this database has been already closed.
  bool _closed = false;

  @override
  int get schemaVersion => Config.scopedVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        Log.info('MigrationStrategy.onUpgrade($from, $to)', '$runtimeType');

        if (_closed) {
          return;
        }

        if (from != to) {
          bool migrated = false;

          try {
            if (to >= 4 && from <= 3) {
              await m.alterTable(
                TableMigration(
                  sessions,
                  columnTransformer: {sessions.siteDomain: Constant('')},
                  newColumns: [sessions.siteDomain],
                ),
              );
              migrated = true;
            }

            if (to >= 3 && from <= 2) {
              await m.addColumn(chats, chats.isArchived);
              migrated = true;
            }

            if (to >= 2 && from <= 1) {
              await m.addColumn(users, users.welcomeMessage);
              migrated = true;
            }
          } catch (e) {
            // Should log the error, but proceed with initialization, as
            // otherwise `drift` won't allow application to run at all.
            Log.error(
              'Unable to perform migrations due to: $e',
              '$runtimeType',
            );
          }

          if (!migrated) {
            Log.info(
              'MigrationStrategy.onUpgrade($from, $to) -> migration did not succeed, thus deleting the tables',
              '$runtimeType',
            );

            for (var e in m.database.allTables) {
              await m.deleteTable(e.actualTableName);
            }
          } else {
            Log.info(
              'MigrationStrategy.onUpgrade($from, $to) -> migration did succeed',
              '$runtimeType',
            );
          }
        }

        await m.createAll();
      },
      beforeOpen: (_) async {
        Log.debug('MigrationStrategy.beforeOpen()', '$runtimeType');

        if (_closed) {
          return;
        }

        try {
          await customStatement('PRAGMA foreign_keys = ON;');

          // Note, that WAL doesn't work in Web:
          // https://github.com/simolus3/sqlite3.dart/issues/200
          await customStatement('PRAGMA journal_mode = WAL;');
        } catch (e) {
          Log.error('Custom SQL statement has failed: $e', '$runtimeType');
        }
      },
    );
  }

  /// Creates all tables, triggers, views, indexes and everything else defined
  /// in the database, if they don't exist.
  Future<void> create() async {
    // Don't warn about multiple [ScopedDatabase]s being created, as this is the
    // expected behaviour: we open a new one for each authorized [UserId] to
    // separate data of different [MyUser]s from each other.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    await createMigrator().createAll();
  }

  /// Resets everything, meaning dropping and re-creating every table.
  Future<void> reset([bool recreate = true]) async {
    Log.debug('reset()', '$runtimeType');

    for (var e in allSchemaEntities) {
      if (e is TableInfo) {
        await e.deleteAll();
      } else {
        await createMigrator().drop(e);
      }
    }

    if (recreate) {
      await createMigrator().createAll();
    }
  }

  @override
  Future<void> close() async {
    Log.debug('close()', '$runtimeType');

    _closed = true;
    await super.close();
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

  /// [Completer]s of [wrapped] operations to await in [onClose].
  final List<Completer> _completers = [];

  /// [StreamController]s of [stream]s to cancel in [onClose].
  final List<StreamController> _controllers = [];

  /// [StreamSubscription]s to executors of [stream]s to cancel in [onClose].
  final List<StreamSubscription> _subscriptions = [];

  @override
  void onInit() async {
    super.onInit();

    Log.debug('onInit()', '$runtimeType');
    await _caught(db?.create());
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    close();

    super.onClose();
  }

  /// Closes this [CommonDriftProvider].
  @visibleForTesting
  Future<void> close() async {
    db?._closed = true;
    await _completeAllOperations((db) async {
      await _caught(db?.close());
    });
  }

  /// Resets the [CommonDatabase] and closes this [CommonDriftProvider].
  Future<void> reset() async {
    await _completeAllOperations((db) async {
      await _caught(db?.reset());
      this.db = db;
    });
  }

  /// Completes the provided [action] in a wrapped safe environment.
  Future<T?> wrapped<T>(Future<T?> Function(CommonDatabase) action) async {
    if (isClosed || db == null) {
      return null;
    }

    final Completer completer = Completer();
    _completers.add(completer);

    try {
      return await _caught(action(db!));
    } finally {
      completer.complete();
      _completers.remove(completer);
    }
  }

  /// Returns the [Stream] executed in a wrapped safe environment.
  Stream<T> stream<T>(Stream<T> Function(CommonDatabase db) executor) {
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
          (e) {
            if (controller?.isClosed != true) {
              controller?.add(e);
            }
          },
          onError: (e) {
            if (e is! StateError &&
                e is! CouldNotRollBackException &&
                !_isConnectionClosedException(e)) {
              controller?.addError(e);
            }
          },
          onDone: () => controller?.close(),
        );

        _subscriptions.add(subscription!);
      },
      onCancel: () {
        if (subscription != null) {
          subscription?.cancel();
          _subscriptions.remove(subscription);
          _controllers.remove(controller);
        }
      },
    );
    _controllers.add(controller);

    return controller.stream;
  }

  /// Closes all the [_subscriptions] and awaits all [_completers].
  Future<void> _completeAllOperations(
    Future<void> Function(CommonDatabase?) process,
  ) async {
    final Future<void> future = process(db);
    db = null;

    // Close all the active streams.
    for (var e in _controllers.toList()) {
      await e.close();
    }

    for (var e in _subscriptions.toList()) {
      await e.cancel();
    }

    // Wait for all operations to complete, disallowing new ones.
    await Future.wait(_completers.map((e) => e.future));

    await future;
  }
}

/// [ScopedDatabase] provider.
final class ScopedDriftProvider extends IdentityDependency {
  /// Constructs a [ScopedDriftProvider] with the in-memory database.
  ScopedDriftProvider.memory()
    : db = ScopedDatabase(const UserId('me'), inMemory()),
      _memory = true,
      super(me: const UserId('me'));

  /// Constructs a [ScopedDriftProvider] with the provided [db].
  ScopedDriftProvider.from(this.db, {required super.me}) : _memory = false;

  /// [ScopedDatabase] itself.
  ///
  /// `null` here means the database is closed.
  ScopedDatabase? db;

  /// Indicator whether [db] is a memory-only database.
  final bool _memory;

  /// [Completer]s of [wrapped] operations to await in [onClose].
  final List<Completer> _completers = [];

  /// [StreamController]s of [stream]s to cancel in [onClose].
  final List<StreamController> _controllers = [];

  /// [StreamSubscription]s to executors of [stream]s to cancel in [onClose].
  final List<StreamSubscription> _subscriptions = [];

  @override
  void onInit() async {
    super.onInit();

    Log.debug('onInit()', '$runtimeType');
    await _caught(db?.create());
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    close();

    super.onClose();
  }

  @override
  void onIdentityChanged(UserId me) {
    super.onIdentityChanged(me);

    Log.debug('onIdentityChanged($me)', '$runtimeType');

    close();

    if (_memory) {
      db = ScopedDatabase(me, inMemory());
    } else {
      db = ScopedDatabase(me);
    }

    _caught(db?.create());
  }

  /// Closes this [ScopedDriftProvider].
  @visibleForTesting
  Future<void> close() async {
    db?._closed = true;
    await _completeAllOperations((db) async {
      await _caught(db?.close());
    });
  }

  /// Resets the [ScopedDatabase] and closes this [ScopedDriftProvider].
  Future<void> reset([bool recreate = true]) async {
    await _completeAllOperations((db) async {
      await _caught(db?.reset(recreate));
      this.db = db;
    });
  }

  /// Completes the provided [action] in a wrapped safe environment.
  Future<T?> wrapped<T>(Future<T?> Function(ScopedDatabase) action) async {
    if (isClosed || db == null) {
      return null;
    }

    final Completer completer = Completer();
    _completers.add(completer);

    try {
      return await _caught(action(db!));
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
          onError: (e) {
            if (e is! StateError &&
                e is! CouldNotRollBackException &&
                !_isConnectionClosedException(e)) {
              controller?.addError(e);
            }
          },
          onDone: () {
            controller?.close();
            subscription?.cancel();
          },
        );

        _subscriptions.add(subscription!);
      },
      onCancel: () {
        if (subscription != null) {
          subscription?.cancel();
          _subscriptions.remove(subscription);
          _controllers.remove(controller);
        }
      },
    );

    _controllers.add(controller);

    return controller.stream;
  }

  /// Closes all the [_subscriptions] and awaits all [_completers].
  Future<void> _completeAllOperations(
    Future<void> Function(ScopedDatabase?) process,
  ) async {
    final Future<void> future = process(db);
    db = null;

    // Close all the active streams.
    for (var e in _controllers.toList()) {
      await e.close();
    }

    for (var e in _subscriptions.toList()) {
      await e.cancel();
    }

    // Wait for all operations to complete, disallowing new ones.
    await Future.wait(_completers.map((e) => e.future));

    await future;
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

    await _caught(db?.transaction(action));
  }

  /// Runs the [callback] through a non-closed [CommonDatabase], or returns
  /// `null`.
  ///
  /// [CommonDatabase] may be closed, for example, between E2E tests.
  Future<T?> safe<T>(
    Future<T> Function(CommonDatabase db) callback, {
    bool exclusive = true,
    String? tag,
  }) async {
    if (isClosed || db == null) {
      return null;
    }

    return await _provider.wrapped(callback);
  }

  /// Listens to the [executor] through a non-closed [CommonDatabase].
  ///
  /// [CommonDatabase] may be closed, for example, between E2E tests.
  Stream<T> stream<T>(Stream<T> Function(CommonDatabase db) executor) {
    return _provider.stream(executor);
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
    await _caught(
      _scoped.wrapped((db) async {
        return await WebUtils.protect(tag: '${_scoped.db?.userId}', () async {
          if (isClosed || _scoped.isClosed) {
            return null;
          }

          return await _caught(db.transaction(action));
        });
      }),
    );
  }

  /// Runs the [callback] through a non-closed [ScopedDatabase], or returns
  /// `null`.
  ///
  /// [ScopedDatabase] may be closed, for example, between E2E tests.
  Future<T?> safe<T>(
    Future<T> Function(ScopedDatabase db) callback, {
    String? tag,
    bool exclusive = true,
    bool force = false,
  }) async {
    if (_scoped.db == null) {
      Log.debug(
        'safe(tag: $tag) -> await WebUtils.protect(tag: ${_scoped.db?.userId}, exclusive: $exclusive) returns `null` due to `_scoped.db` being `null`',
        '$runtimeType',
      );

      return null;
    }

    if (PlatformUtils.isWeb && !force) {
      Log.debug(
        'safe(tag: $tag) -> await WebUtils.protect(tag: ${_scoped.db?.userId}, exclusive: $exclusive)...',
        '$runtimeType',
      );

      // WAL doesn't work in Web, thus guard all the writes/reads with Web Locks
      // API: https://github.com/simolus3/sqlite3.dart/issues/200
      return await WebUtils.protect(
        tag: '${_scoped.db?.userId}',
        exclusive: exclusive,
        () async {
          if (isClosed) {
            return null;
          }

          Log.debug(
            'safe(tag: $tag) -> await WebUtils.protect(tag: ${_scoped.db?.userId}, exclusive: $exclusive)... done! ',
            '$runtimeType',
          );

          final result = await _scoped.wrapped(callback);

          Log.debug(
            'safe(tag: $tag) -> await WebUtils.protect(tag: ${_scoped.db?.userId}, exclusive: $exclusive)... done! and released!',
            '$runtimeType',
          );

          return result;
        },
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

/// Returns the [function] awaited with [StateError] and
/// [CouldNotRollBackException] exceptions handled.
Future<T?> _caught<T>(Future<T?>? function) async {
  try {
    return await function;
  } on StateError {
    // No-op.
  } on CouldNotRollBackException {
    // No-op.
  } catch (e) {
    if (!_isConnectionClosedException(e)) {
      rethrow;
    }
  }

  return null;
}

/// Indicates  whether this error is a `drift` race related one.
bool _isConnectionClosedException(dynamic e) {
  try {
    return e.toString().contains('ConnectionClosedException') ||
        e.toString().contains('Channel was closed before receiving a response');
  } catch (_) {
    // Happens if `toString()` isn't defined on that dynamic.
    return false;
  }
}
