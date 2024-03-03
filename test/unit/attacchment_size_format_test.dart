import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/l10n/l10n.dart';

void main() {
  group('IntExtension', () {
    test('asBytes IntExtension returns correct string for various sizes', () {
      expect(0.asBytes, '0${'label_b'.l10n}');
      expect(512.asBytes, '512${'label_b'.l10n}');
      expect(1024.asBytes, '1.0${'label_kb'.l10n}');
      expect(2048.asBytes, '2.0${'label_kb'.l10n}');
      expect(1048576.asBytes, '1.0${'label_mb'.l10n}');
      expect(1073741824.asBytes, '1.0${'label_gb'.l10n}');
      expect(1099511627776.asBytes, '1.0${'label_tb'.l10n}');
      expect(1125899906842624.asBytes, '1.0${'label_pb'.l10n}');
      expect(() => (-1).asBytes, throwsArgumentError);
    });
  });
}
