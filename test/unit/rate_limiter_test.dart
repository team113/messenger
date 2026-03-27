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

import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/util/backoff.dart';
import 'package:messenger/util/rate_limiter.dart';

void main() async {
  test('RateLimiter correctly limits its requests', () async {
    const Duration per = Duration(milliseconds: 300);
    const int requests = 5;

    final RateLimiter limiter = RateLimiter(requests: requests, per: per);
    expect(limiter.queue.length, 0);

    final Set<int> finished = {};
    final List<Future> futures = [];

    for (var i = 0; i < requests * 5; ++i) {
      futures.add(limiter.execute(() async => i)..then((v) => finished.add(v)));
    }

    DateTime startedAt = DateTime.now();

    // Wait for [RateLimiter.execute]s to process.
    await Future.wait(futures.take(requests));

    expect(limiter.queue.length, requests * 5);
    expect(finished.length, requests);
    expect(finished, List.generate(requests, (i) => i));

    // First bunch should be available almost immediately.
    expect(
      startedAt.difference(DateTime.now()) < const Duration(milliseconds: 16),
      true,
    );
    startedAt = DateTime.now();

    await Future.wait(futures.skip(requests).take(requests));
    expect(finished.length, requests * 2);
    expect(startedAt.difference(DateTime.now()) <= per, true);
    startedAt = DateTime.now();

    await Future.wait(futures.skip(requests * 2).take(requests));
    expect(finished.length, requests * 3);
    expect(startedAt.difference(DateTime.now()) <= per, true);
    startedAt = DateTime.now();

    await Future.wait(futures.skip(requests * 3).take(requests));
    expect(finished.length, requests * 4);
    expect(startedAt.difference(DateTime.now()) <= per, true);

    await Future.wait(futures.skip(requests * 4).take(requests));
    expect(finished.length, requests * 5);
    startedAt = DateTime.now();

    expect(limiter.queue.where((e) => e.isLocked).length, 0);

    await Future.delayed(per);
    expect(limiter.queue.length, 0);

    // Next bunch should be executed immediately.
    finished.clear();
    futures.clear();
    for (var i = 0; i < requests; ++i) {
      futures.add(limiter.execute(() async => i)..then((v) => finished.add(v)));
    }

    startedAt = DateTime.now();

    // Wait for [RateLimiter.execute]s to process.
    await Future.wait(futures.take(requests));

    expect(limiter.queue.length, requests);
    expect(finished.length, requests);
    expect(finished, List.generate(requests, (i) => i));

    // First bunch should be available almost immediately.
    expect(
      startedAt.difference(DateTime.now()) < const Duration(milliseconds: 16),
      true,
    );

    expect(limiter.queue.where((e) => e.isLocked).length, 0);

    await Future.delayed(per);
    expect(limiter.queue.length, 0);

    // Next bunch should be executing a long period of time.
    finished.clear();
    futures.clear();
    for (var i = 0; i < requests * 2; ++i) {
      futures.add(
        limiter.execute(() async {
          await Future.delayed(per * 5);
          return i;
        })..then((v) => finished.add(v)),
      );
    }

    // Wait for [RateLimiter.execute]s to process.
    await Future.wait(futures.take(requests));

    // Every request should be completed, despite multiple [per] being awaited.
    expect(limiter.queue.length, 0);
    expect(finished.length, 5);
    expect(finished, List.generate(requests, (i) => i));
  });

  test('RateLimiter correctly clears itself', () async {
    const Duration per = Duration(milliseconds: 300);
    const int requests = 5;

    final RateLimiter limiter = RateLimiter(requests: requests, per: per);
    expect(limiter.queue.length, 0);

    int exceptions = 0;
    final List<Future> futures = [];

    for (var i = 0; i < requests * 2; ++i) {
      futures.add(
        limiter
            .execute(() async => i)
            .onError<OperationCanceledException>((_, _) => ++exceptions),
      );
    }

    limiter.clear();

    await Future.wait(futures);
    expect(exceptions, requests * 2);

    // Once again.
    exceptions = 0;
    futures.clear();
    for (var i = 0; i < requests * 2; ++i) {
      futures.add(
        limiter
            .execute(() async => i)
            .onError<OperationCanceledException>((_, _) => ++exceptions),
      );
    }

    limiter.clear();

    await Future.wait(futures);
    expect(exceptions, requests * 2);
  });
}
