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
import 'package:messenger/ui/worker/cache.dart';
import 'package:messenger/util/platform_utils.dart';

import '../mock/cache_hive_provider.dart';
import '../mock/platform_utils.dart';

void main() async {
  PlatformUtils = PlatformUtilsMock();
  final Directory cache = await PlatformUtils.cacheDirectory;
  cache.create();

  test('CacheWorker adds files', () async {
    final CacheWorker worker = CacheWorker(CacheInfoHiveProviderMock());
    await worker.onInit();

    await worker.add(base64Decode('someData'));
    expect(cache.listSync().length, 1);

    await worker.add(base64Decode('someData1111'));
    expect(cache.listSync().length, 2);

    cache.listSync().forEach((e) => e.deleteSync());
  });

  test('CacheWorker clears files', () async {
    final CacheWorker worker = CacheWorker(CacheInfoHiveProviderMock());
    await worker.onInit();

    await worker.add(base64Decode('someData'));
    await worker.add(base64Decode('someData1111'));
    await worker.add(base64Decode('someData2222'));
    await worker.add(base64Decode('someData3333'));

    await Future.delayed(Duration.zero);

    await worker.clear();
    expect(cache.listSync().length, 0);

    cache.listSync().forEach((e) => e.deleteSync());
  });

  test('CacheWorker finds stored files', () async {
    final CacheWorker worker = CacheWorker(CacheInfoHiveProviderMock());
    await worker.onInit();

    await worker.add(base64Decode('someData'), 'checksum');
    expect(worker.exists('checksum'), true);
    expect(worker.get(checksum: 'checksum'), base64Decode('someData'));

    await worker.add(base64Decode('someData1111'), 'checksum1');
    expect(worker.exists('checksum1'), true);
    expect(worker.get(checksum: 'checksum1'), base64Decode('someData1111'));

    FIFOCache.clear();

    expect(worker.exists('checksum'), true);
    expect(await worker.get(checksum: 'checksum'), base64Decode('someData'));

    expect(worker.exists('checksum1'), true);
    expect(
      await worker.get(checksum: 'checksum1'),
      base64Decode('someData1111'),
    );

    cache.listSync().forEach((e) => e.deleteSync());
  });

  test('CacheWorker optimizes cache', () async {
    final CacheWorker worker = CacheWorker(CacheInfoHiveProviderMock());
    await worker.onInit();

    for (int i = 0; i < 100; i++) {
      await worker.add(base64Decode('$i' * 4 * 3000));
    }

    await Future.delayed(const Duration(seconds: 1));

    List<FileSystemEntity> files = cache.listSync();

    int cacheSize = 0;
    for (var e in files) {
      cacheSize += e.statSync().size;
    }

    expect(cacheSize < worker.info.value.maxSize, true);
    expect(files.length < 100, true);

    cache.listSync().forEach((e) => e.deleteSync());
  });
}
