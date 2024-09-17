import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/l10n/l10n.dart';

void main() {
  test('.asFormattedFileSize()', () async {
    WidgetsFlutterBinding.ensureInitialized(); // needed to load translations
    await L10n.init(L10n.languages.first);

    expect(null.asFormattedFileSize(), 'dot'.l10n * 3);
    expect(0.asFormattedFileSize(), 'label_b'.l10nfmt({'amount': '0'}));
    expect(1023.asFormattedFileSize(), 'label_b'.l10nfmt({'amount': '1023'}));
    expect(1024.asFormattedFileSize(), 'label_kb'.l10nfmt({'amount': '1.0'}));
    expect(
      (1024 + 50).asFormattedFileSize(),
      'label_kb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      (1024 + 100).asFormattedFileSize(),
      'label_kb'.l10nfmt({'amount': '1.1'}),
    );
    expect(
      pow(1024, 2).toInt().asFormattedFileSize(),
      'label_mb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 3).toInt().asFormattedFileSize(),
      'label_gb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 4).toInt().asFormattedFileSize(),
      'label_tb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 5).toInt().asFormattedFileSize(),
      'label_pb'.l10nfmt({'amount': '1.0'}),
    );
    expect(
      pow(1024, 6).toInt().asFormattedFileSize(),
      'label_pb'.l10nfmt({'amount': '1024.0'}),
    );
  });
}
