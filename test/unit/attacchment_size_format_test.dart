import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/util/attachment_size_utils.dart';

void main() {
  group('FileUtils', () {
    test('getFileSizeString returns correct string for various sizes', () {
      const formatSize = FileUtils.formatSize;

      expect(formatSize(bytes: 0), '0 ${'label_b'.l10n}');
      expect(formatSize(bytes: 512), '512 ${'label_b'.l10n}');
      expect(formatSize(bytes: 1024), '1.0 ${'label_kb'.l10n}');
      expect(formatSize(bytes: 2048), '2.0 ${'label_kb'.l10n}');
      expect(formatSize(bytes: 1048576), '1.0 ${'label_mb'.l10n}');
      expect(formatSize(bytes: 1073741824), '1.0 ${'label_gb'.l10n}');
      expect(formatSize(bytes: 1099511627776), '1.0 ${'label_tb'.l10n}');
      expect(formatSize(bytes: 1125899906842624), '1.0 ${'label_pb'.l10n}');
      expect(() => formatSize(bytes: -1), throwsArgumentError);
    });
  });
}
