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

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show mustCallSuper, protected;
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:universal_io/io.dart';

import '/domain/model/user.dart';
import '/util/log.dart';

/// Base class for data providers backed by [Hive].
abstract class HiveBaseProvider<T> extends DisposableInterface {
  /// [Box] that contains all of the data.
  late Box<T> _box;

  /// Indicates whether the underlying [Box] was opened and can be used.
  bool _isReady = false;

  /// [Mutex] that guards [_box] access.
  final Mutex _mutex = Mutex();

  /// Returns the [Box] storing data of this [HiveBaseProvider].
  Box<T> get box => _box;

  /// Indicates whether there are no entries in this [Box].
  bool get isEmpty => box.isEmpty;

  /// Returns a broadcast stream of Hive [Box] change events.
  Stream<BoxEvent> get boxEvents;

  /// Indicates whether the underlying [Box] was opened and can be used.
  bool get isReady => _isReady;

  /// Name of the underlying [Box].
  @protected
  String get boxName;

  /// Exception-safe wrapper for [Box.keys] returning all the keys in the [box].
  Iterable<dynamic> get keysSafe {
    if (_isReady && _box.isOpen) {
      return box.keys;
    }
    return [];
  }

  /// Exception-safe wrapper for [Box.values] returning all the values in the
  /// [box].
  Iterable<T> get valuesSafe {
    if (_isReady && _box.isOpen) {
      return box.values;
    }
    return [];
  }

  @protected
  void registerAdapters();

  /// Opens a [Box] and changes [isReady] to true.
  ///
  /// Should be called before using underlying [Box].
  ///
  /// In order for this box to be linked with a certain [User], [userId] may be
  /// specified.
  Future<void> init({UserId? userId}) async {
    Log.debug('init(userId: $userId)', '$runtimeType');

    registerAdapters();
    await _mutex.protect(() async {
      final String name = userId == null ? boxName : '${userId}_$boxName';
      try {
        _box = await Hive.openBox<T>(name);
      } catch (e) {
        await Future.delayed(Duration.zero);
        // TODO: This will throw if database scheme has changed.
        //       We should perform explicit migrations here.
        await Hive.deleteBoxFromDisk(name);
        _box = await Hive.openBox<T>(name);
      }
      _isReady = true;
    });
  }

  /// Removes all entries from the [Box].
  @mustCallSuper
  Future<void> clear() async {
    Log.debug('clear()', '$runtimeType');

    if (_isReady && _box.isOpen) {
      await box.clear();
    }
  }

  /// Closes the [Box].
  @mustCallSuper
  Future<void> close() {
    Log.debug('close()', '$runtimeType');

    return _mutex.protect(() async {
      if (_isReady && _box.isOpen) {
        _isReady = false;

        try {
          await _box.close();
        } on FileSystemException {
          // No-op.
        }
      }
    });
  }

  @override
  void onClose() async {
    await close();
    super.onClose();
  }

  /// Exception-safe wrapper for [BoxBase.put] saving the [key] - [value] pair.
  Future<void> putSafe(dynamic key, T value) async {
    if (_isReady && _box.isOpen) {
      await _box.put(key, value);
    }
  }

  /// Exception-safe wrapper for [Box.get] returning the value associated with
  /// the given [key], if any.
  T? getSafe(dynamic key, {T? defaultValue}) {
    if (_isReady && _box.isOpen) {
      return box.get(key, defaultValue: defaultValue);
    }
    return null;
  }

  /// Exception-safe wrapper for [BoxBase.delete] deleting the given [key] from
  /// the [box].
  Future<void> deleteSafe(dynamic key, {T? defaultValue}) async {
    if (_isReady && _box.isOpen) {
      await _box.delete(key);
    }
  }

  /// Exception-safe wrapper for [BoxBase.deleteAt] deleting a value by the
  /// given [index] from the [box].
  Future<void> deleteAtSafe(int index) async {
    if (_isReady && _box.isOpen) {
      await box.deleteAt(index);
    }
  }
}

/// Base class for data providers backed by [Hive] using [LazyBox].
abstract class HiveLazyProvider<T extends Object> extends DisposableInterface {
  /// [LazyBox] that contains all of the data.
  late LazyBox<T> _box;

  /// Indicates whether the underlying [Box] was opened and can be used.
  bool _isReady = false;

  /// [Mutex] that guards [_box] access.
  final Mutex _mutex = Mutex();

  /// [Mutex] that guards [_box] access when a transaction is active.
  final Mutex _transaction = Mutex();

  /// Returns the [Box] storing data of this [HiveLazyProvider].
  LazyBox<T> get box => _box;

  /// Indicates whether there are no entries in this [Box].
  bool get isEmpty => _box.isEmpty;

  /// Returns a broadcast stream of Hive [Box] change events.
  Stream<BoxEvent> get boxEvents;

  /// Indicates whether the underlying [Box] was opened and can be used.
  bool get isReady => _isReady;

  /// Name of the underlying [Box].
  @protected
  String get boxName;

  /// Exception-safe wrapper for [Box.keys] returning all the keys in the [box].
  Iterable<dynamic> get keysSafe {
    if (_isReady && _box.isOpen) {
      return box.keys;
    }
    return [];
  }

  /// Exception-safe wrapper for [Box.values] returning all the values in the
  /// [_box].
  Future<Iterable<T>> get valuesSafe async {
    if (_isReady && _box.isOpen) {
      return (await Future.wait(_box.keys.map((e) => getSafe(e))))
          .whereNotNull();
    }

    return [];
  }

  @protected
  void registerAdapters();

  /// Opens a [Box] and changes [isReady] to true.
  ///
  /// Should be called before using underlying [Box].
  ///
  /// In order for this box to be linked with a certain [User], [userId] may be
  /// specified.
  Future<void> init({UserId? userId}) async {
    Log.debug('init(userId: $userId)', '$runtimeType');

    await _mutex.protect(() async {
      if (_isReady && _box.isOpen) {
        return;
      }

      registerAdapters();

      final String name = userId == null ? boxName : '${userId}_$boxName';
      try {
        _box = await Hive.openLazyBox(name);
      } catch (e) {
        await Future.delayed(Duration.zero);
        // TODO: This will throw if database scheme has changed.
        //       We should perform explicit migrations here.
        await Hive.deleteBoxFromDisk(name);
        _box = await Hive.openLazyBox(name);
      }
      _isReady = true;
    });
  }

  /// Removes all entries from the [Box].
  @mustCallSuper
  Future<void> clear() {
    Log.debug('clear()', '$runtimeType');

    return _transaction.protect(
      () => _mutex.protect(() async {
        if (_isReady && keysSafe.isNotEmpty) {
          await _box.clear();
        }
      }),
    );
  }

  /// Closes the [Box].
  @mustCallSuper
  Future<void> close() {
    Log.debug('close()', '$runtimeType');

    return _mutex.protect(() async {
      if (_isReady && _box.isOpen) {
        _isReady = false;

        try {
          await _box.close();
        } on FileSystemException {
          // No-op.
        }
      }
    });
  }

  @override
  void onClose() async {
    await close();
    super.onClose();
  }

  /// Exception-safe wrapper for [BoxBase.put] saving the [key] - [value] pair.
  Future<void> putSafe(dynamic key, T value) {
    return _transaction.protect(() => _putSafe(key, value));
  }

  /// Exception-safe wrapper for [Box.get] returning the value associated with
  /// the given [key], if any.
  Future<T?> getSafe(dynamic key, {T? defaultValue}) {
    return _transaction.protect(
      () => _getSafe(key, defaultValue: defaultValue),
    );
  }

  /// Exception-safe wrapper for [BoxBase.delete] deleting the given [key] from
  /// the [box].
  Future<void> deleteSafe(dynamic key, {T? defaultValue}) {
    return _transaction.protect(
      () => _mutex.protect(() async {
        if (_isReady && _box.isOpen) {
          await _box.delete(key);
        }

        return Future.value();
      }),
    );
  }

  /// Runs a transaction in this [HiveLazyProvider].
  ///
  /// __Note__, that [putSafe], [getSafe] and [deleteSafe] get locked, thus use
  /// [HiveTransaction] provided in the [callback] to access those methods.
  Future<void> txn(Future<void> Function(HiveTransaction<T>) callback) {
    return _transaction.protect(
      () => callback(HiveTransaction(_putSafe, _getSafe)),
    );
  }

  /// Exception-safe wrapper for [BoxBase.put] saving the [key] - [value] pair.
  Future<void> _putSafe(dynamic key, T value) {
    return _mutex.protect(() async {
      if (_isReady && _box.isOpen) {
        await _box.put(key, value);
      }
    });
  }

  /// Exception-safe wrapper for [Box.get] returning the value associated with
  /// the given [key], if any.
  Future<T?> _getSafe(dynamic key, {T? defaultValue}) {
    return _mutex.protect(() async {
      if (_isReady && _box.isOpen) {
        return _box.get(key, defaultValue: defaultValue);
      }

      return null;
    });
  }
}

/// [Hive] provider with [Iterable] functionality support.
///
/// Intended to be used as a source for [Pagination] items persisted.
abstract class IterableHiveProvider<T extends Object, K> {
  /// Returns a list of [K] keys stored in the [Hive].
  Iterable<K> get keys;

  /// Returns a list of [T] items from [Hive].
  Future<Iterable<T>> get values;

  /// Puts the provided [item] to [Hive].
  Future<void> put(T item);

  /// Returns a [T] item from [Hive] by its [key].
  Future<T?> get(K key);

  /// Removes a [T] item from [Hive] by the provided [key].
  Future<void> remove(K key);

  /// Removes all entries from [Hive].
  Future<void> clear();
}

/// Extension adding an ability to register [TypeAdapter]s for [Hive].
extension HiveRegisterAdapter on HiveInterface {
  /// Tries to register the given [adapter].
  void maybeRegisterAdapter<A>(TypeAdapter<A> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<A>(adapter);
    }
  }
}

/// Entity accessing [put] and [get] throughout the transaction.
///
/// Intended to be used for [HiveBaseProvider] transactions.
class HiveTransaction<T> {
  const HiveTransaction(this.put, this.get);

  /// Puts the provided value.
  final Future<void> Function(dynamic key, T value) put;

  /// Returns a [T] item by its key.
  final Future<T?> Function(dynamic key) get;
}
