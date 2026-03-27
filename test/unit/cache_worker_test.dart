// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/domain/model/cache_info.dart';
import 'package:messenger/provider/drift/cache.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/ui/worker/cache.dart';
import 'package:messenger/util/platform_utils.dart';

import '../mock/platform_utils.dart';

void main() async {
  PlatformUtils = PlatformUtilsMock();

  final CommonDriftProvider common = CommonDriftProvider.memory();

  final Directory cache = (await PlatformUtils.cacheDirectory)!..create();

  final cacheProvider = CacheDriftProvider(common);

  tearDownAll(() => cache.listSync().forEach((e) => e.deleteSync()));

  test('CacheWorker adds files to cache', () async {
    final CacheWorker worker = CacheWorker(cacheProvider, null);
    await worker.onInit();

    await worker.add(base64Decode('someData'));
    expect(cache.listSync().length, 1);

    await worker.add(base64Decode('someData1111'));
    expect(cache.listSync().length, 2);

    await worker.clear();
    await cacheProvider.clear();
  });

  test('CacheWorker clears its files', () async {
    final CacheWorker worker = CacheWorker(cacheProvider, null);
    await worker.onInit();

    await worker.add(base64Decode('someData'));
    await worker.add(base64Decode('someData1111'));
    await worker.add(base64Decode('someData2222'));
    await worker.add(base64Decode('someData3333'));

    await worker.ensureOptimized();

    await worker.clear();
    await cacheProvider.clear();
    expect(cache.listSync().length, 0);
  });

  test('CacheWorker finds stored files', () async {
    final CacheWorker worker = CacheWorker(cacheProvider, null);
    await worker.onInit();

    await worker.add(base64Decode('someData'), 'checksum');
    expect(worker.exists('checksum'), true);
    expect(
      (await worker.get(checksum: 'checksum')).bytes,
      base64Decode('someData'),
    );

    await worker.add(base64Decode('someData1111'), 'checksum1');
    expect(worker.exists('checksum1'), true);
    expect(
      (await worker.get(checksum: 'checksum1')).bytes,
      base64Decode('someData1111'),
    );

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
    await cacheProvider.clear();
  });

  test('CacheWorker optimizes its resources correctly', () async {
    await cacheProvider.upsert(CacheInfo(maxSize: 1024 * 1024));

    final CacheWorker worker = CacheWorker(cacheProvider, null);
    await worker.onInit();

    for (int i = 0; i < 100; i++) {
      await worker.add(base64Decode('$i' * 4 * 3000));
    }

    expect(worker.info.value.size >= worker.info.value.maxSize!, true);

    await worker.ensureOptimized();

    expect(worker.info.value.size >= worker.info.value.maxSize!, false);

    final List<FileSystemEntity> files = cache.listSync();
    expect(files.length < 100, true);
    expect(
      worker.info.value.size,
      files.fold(0, (p, e) => p + e.statSync().size),
    );

    await worker.clear();
    await cacheProvider.clear();
  });

  test('CacheWorker updates max size according to slider', () async {
    final CacheWorker worker = CacheWorker(cacheProvider, null);
    await worker.onInit();

    void applySlider(double value) {
      if (value == 64 * GB) {
        CacheWorker.instance.setMaxSize(null);
      } else {
        CacheWorker.instance.setMaxSize(value.round());
      }
    }

    applySlider(4.0 * GB);
    expect(worker.info.value.maxSize, 4 * GB);

    applySlider(64.0 * GB);
    expect(worker.info.value.maxSize, null);

    await worker.clear();
    await cacheProvider.clear();
  });
}
