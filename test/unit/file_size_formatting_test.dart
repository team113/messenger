import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/l10n/l10n.dart';

void main() {
  test('L10nSizeInBytesExtension.asBytes() properly formats the sizes',
      () async {
    WidgetsFlutterBinding.ensureInitialized(); // Required to load translations.

    await L10n.init(L10n.languages.first);

    expect(null.asBytes(), 'dot'.l10n * 3);
    expect(0.asBytes(), 'label_b'.l10nfmt({'amount': '0'}));
    expect(1023.asBytes(), 'label_b'.l10nfmt({'amount': '1023'}));
    expect(1024.asBytes(), 'label_kb'.l10nfmt({'amount': '1.0'}));
    expect(
      (1024 + 50).asBytes(),
      'label_kb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      (1024 + 100).asBytes(),
      'label_kb'.l10nfmt({'amount': '1.1'}),
    );
    expect(
      pow(1024, 2).toInt().asBytes(),
      'label_mb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 3).toInt().asBytes(),
      'label_gb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 4).toInt().asBytes(),
      'label_tb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 5).toInt().asBytes(),
      'label_pb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 6).toInt().asBytes(),
      'label_pb'.l10nfmt({'amount': '1024.0'}),
    );
  });
}
