// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:universal_io/io.dart';

import '/domain/model/user.dart';

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
    registerAdapters();
    await _mutex.protect(() async {
      String name = userId == null ? boxName : '${userId}_$boxName';
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
  Future<void> clear() => _mutex.protect(() async {
        if (_isReady) {
          await box.clear();
        }
      });

  /// Closes the [Box].
  @mustCallSuper
  Future<void> close() => _mutex.protect(() async {
        if (_isReady && _box.isOpen) {
          _isReady = false;

          try {
            await _box.close();
          } on FileSystemException {
            // No-op.
          }
        }
      });

  @override
  void onClose() async {
    await close();
    super.onClose();
  }

  /// Exception-safe wrapper for [BoxBase.put] saving the [key] - [value] pair.
  Future<void> putSafe(dynamic key, T value) {
    if (_isReady && _box.isOpen) {
      return box.put(key, value);
    }
    return Future.value();
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
  Future<void> deleteSafe(dynamic key, {T? defaultValue}) {
    if (_isReady && _box.isOpen) {
      return box.delete(key);
    }
    return Future.value();
  }
}

extension HiveRegisterAdapter on HiveInterface {
  /// Tries to register the given [adapter].
  void maybeRegisterAdapter<A>(TypeAdapter<A> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<A>(adapter);
    }
  }
}
