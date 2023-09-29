import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';

void main() {
  group('getDelay returns correct results', () {
    test('returns a delay when online', () {
      final User user1 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
            DateTime.now().subtract(const Duration(seconds: 1))),
        online: false,
      );
      final result1 = user1.getDelay();
      const expected1 = Duration(seconds: 0);
      expect(result1, expected1);
    });

    test('returns a delay when presence is away and offline', () {
      final User user1 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(seconds: 1))),
          online: false,
          presenceIndex: 0);
      final delay1 = user1.getDelay();
      const expected1 = Duration(seconds: 59);
      expect(delay1, expected1);

      final User user2 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(seconds: 61))),
          online: false,
          presenceIndex: 0);
      final delay2 = user2.getDelay();
      const expected2 = Duration(seconds: 59);
      expect(delay2, expected2);

      final User user3 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(hours: 1, seconds: 1))),
          online: false,
          presenceIndex: 0);
      final delay3 = user3.getDelay();
      const expected3 = Duration(minutes: 59, seconds: 59);
      expect(delay3, expected3);

      final User user4 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(days: 1, seconds: 1))),
          online: false,
          presenceIndex: 0);
      final delay4 = user4.getDelay();
      const expected4 = Duration(hours: 23, minutes: 59, seconds: 59);
      expect(delay4, expected4);

      final User user5 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(seconds: 60))),
          online: false,
          presenceIndex: 0);
      final delay5 = user5.getDelay();
      const expected5 = Duration(seconds: 0);
      expect(delay5, expected5);

      final User user6 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(minutes: 60))),
          online: false,
          presenceIndex: 0);
      final delay6 = user6.getDelay();
      const expected6 = Duration(seconds: 0);
      expect(delay6, expected6);

      final User user7 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(hours: 24))),
          online: false,
          presenceIndex: 0);
      final delay7 = user7.getDelay();
      const expected7 = Duration(seconds: 0);
      expect(delay7, expected7);
    });

    test('returns a delay when presence is present and offline', () {
      final User user1 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(seconds: 1))),
          online: false,
          presenceIndex: 1);
      final delay1 = user1.getDelay();
      const expected1 = Duration(seconds: 59);
      expect(delay1, expected1);

      final User user2 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(seconds: 61))),
          online: false,
          presenceIndex: 1);
      final delay2 = user2.getDelay();
      const expected2 = Duration(seconds: 59);
      expect(delay2, expected2);

      final User user3 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(hours: 1, seconds: 1))),
          online: false,
          presenceIndex: 1);
      final delay3 = user3.getDelay();
      const expected3 = Duration(minutes: 59, seconds: 59);
      expect(delay3, expected3);

      final User user4 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(days: 1, seconds: 1))),
          online: false,
          presenceIndex: 1);
      final delay4 = user4.getDelay();
      const expected4 = Duration(hours: 23, minutes: 59, seconds: 59);
      expect(delay4, expected4);

      final User user5 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(seconds: 60))),
          online: false,
          presenceIndex: 1);
      final delay5 = user5.getDelay();
      const expected5 = Duration(seconds: 0);
      expect(delay5, expected5);

      final User user6 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(minutes: 60))),
          online: false,
          presenceIndex: 1);
      final delay6 = user6.getDelay();
      const expected6 = Duration(seconds: 0);
      expect(delay6, expected6);

      final User user7 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(hours: 24))),
          online: false,
          presenceIndex: 1);
      final delay7 = user7.getDelay();
      const expected7 = Duration(seconds: 0);
      expect(delay7, expected7);
    });

    test('returns a delay when presence is artemisUnknown and offline', () {
      final User user1 = User(
          const UserId('12345'), UserNum('1234567890123456'),
          lastSeenAt: PreciseDateTime(
              DateTime.now().subtract(const Duration(seconds: 1))),
          online: false,
          presenceIndex: 2);
      final delay = user1.getDelay();
      const expected1 = Duration(seconds: 0);
      expect(delay, expected1);
    });
  });
}
