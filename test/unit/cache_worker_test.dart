// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:messenger/provider/hive/cache.dart';
import 'package:messenger/ui/worker/cache.dart';
import 'package:messenger/util/platform_utils.dart';

import '../mock/platform_utils.dart';

void main() async {
  PlatformUtils = PlatformUtilsMock();

  final Directory cache = (await PlatformUtils.cacheDirectory)!..create();

  Hive.init('./test/.temp_hive/cache_worker_unit');
  var cacheInfoHiveProvider = CacheInfoHiveProvider();
  await cacheInfoHiveProvider.init();

  tearDownAll(() => cache.listSync().forEach((e) => e.deleteSync()));

  test('CacheWorker adds files to cache', () async {
    final CacheWorker worker = CacheWorker(cacheInfoHiveProvider, null);
    await worker.onInit();

    await worker.add(base64Decode('someData'));
    expect(cache.listSync().length, 1);

    await worker.add(base64Decode('someData1111'));
    expect(cache.listSync().length, 2);

    await worker.clear();
    await cacheInfoHiveProvider.clear();
  });

  test('CacheWorker clears its files', () async {
    final CacheWorker worker = CacheWorker(cacheInfoHiveProvider, null);
    await worker.onInit();

    await worker.add(base64Decode('someData'));
    await worker.add(base64Decode('someData1111'));
    await worker.add(base64Decode('someData2222'));
    await worker.add(base64Decode('someData3333'));

    await worker.ensureOptimized();

    await worker.clear();
    await cacheInfoHiveProvider.clear();
    expect(cache.listSync().length, 0);
  });

  test('CacheWorker finds stored files', () async {
    final CacheWorker worker = CacheWorker(cacheInfoHiveProvider, null);
    await worker.onInit();

    await worker.add(base64Decode('someData'), 'checksum');
    expect(worker.exists('checksum'), true);
    expect(
      (worker.get(checksum: 'checksum') as CacheEntry).bytes,
      base64Decode('someData'),
    );

    await worker.add(base64Decode('someData1111'), 'checksum1');
    expect(worker.exists('checksum1'), true);
    expect(
      (worker.get(checksum: 'checksum1') as CacheEntry).bytes,
      base64Decode('someData1111'),
    );

    FIFOCache.clear();

    expect(worker.exists('checksum'), true);
    expect(
      (await worker.get(checksum: 'checksum')).bytes,
      base64Decode('someData'),
    );

    expect(worker.exists('checksum1'), true);
    expect(
      (await worker.get(checksum: 'checksum1')).bytes,
      base64Decode('someData1111'),
    );

    await worker.clear();
    await cacheInfoHiveProvider.clear();
  });

  test('CacheWorker optimizes its resources correctly', () async {
    await cacheInfoHiveProvider.set(maxSize: 1024 * 1024);

    final CacheWorker worker = CacheWorker(cacheInfoHiveProvider, null);
    await worker.onInit();

    for (int i = 0; i < 100; i++) {
      await worker.add(base64Decode('$i' * 4 * 3000));
    }

    expect(worker.info.value.size >= worker.info.value.maxSize, true);

    await worker.ensureOptimized();

    expect(worker.info.value.size >= worker.info.value.maxSize, false);

    final List<FileSystemEntity> files = cache.listSync();
    expect(files.length < 100, true);
    expect(
      worker.info.value.size,
      files.fold(0, (p, e) => p + e.statSync().size),
    );

    await worker.clear();
    await cacheInfoHiveProvider.clear();
  });
}
