import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/l10n/l10n.dart';

void main() {
  test('formattedFileSize()', () async {
    WidgetsFlutterBinding.ensureInitialized(); // needed to load translations
    await L10n.set(Language.fromTag('en-US'), refresh: false);

    expect(formattedFileSize(null), 'dot'.l10n * 3);
    expect(formattedFileSize(0), 'label_b'.l10nfmt({'amount': '0'}));
    expect(formattedFileSize(1023), 'label_b'.l10nfmt({'amount': '1023'}));
    expect(formattedFileSize(1024), 'label_kb'.l10nfmt({'amount': '1'}));
    expect(formattedFileSize(1024 + 50), 'label_kb'.l10nfmt({'amount': '1'}));
    expect(
      formattedFileSize(1024 + 100),
      'label_kb'.l10nfmt({'amount': '1.1'}),
    );
    expect(
      formattedFileSize(pow(1024, 2).toInt()),
      'label_mb'.l10nfmt({'amount': '1'}),
    );
    expect(
      formattedFileSize(pow(1024, 3).toInt()),
      'label_gb'.l10nfmt({'amount': '1'}),
    );
    expect(
      formattedFileSize(pow(1024, 4).toInt()),
      'label_tb'.l10nfmt({'amount': '1'}),
    );
    expect(
      formattedFileSize(pow(1024, 5).toInt()),
      'label_pb'.l10nfmt({'amount': '1'}),
    );
    expect(
      formattedFileSize(pow(1024, 6).toInt()),
      'label_pb'.l10nfmt({'amount': '1024'}),
    );
  });
}
