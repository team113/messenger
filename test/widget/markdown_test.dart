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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/markdown.dart';

/// Widget tests for [MarkdownWidget].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String testBody = 'Hello - World #Markdown Test';

  Widget buildTestWidget() {
    return MaterialApp(
      theme: Themes.light(),
      home: const Scaffold(body: MarkdownWidget(testBody)),
    );
  }

  group('MarkdownWidget Selection and Copy Tests', () {
    L10n.init();

    testWidgets('Displays markdown content', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('Hello'), findsOneWidget);
      });
    });

    testWidgets('Reconstructs selected text and copies via context menu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      String? clipboardText;

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardText = methodCall.arguments['text'];
          }
          return null;
        },
      );

      final selectionAreaFinder = find.byType(SelectionArea);
      expect(selectionAreaFinder, findsOneWidget);

      final SelectionArea selectionArea = tester.widget(selectionAreaFinder);

      final textFinder = find.textContaining('World #Markdown');
      await tester.longPress(textFinder);
      await tester.pumpAndSettle();

      selectionArea.onSelectionChanged?.call(
        const SelectedContent(plainText: 'World #Markdown'),
      );

      final copyButtonFinder = find.text('btn_copy_text'.l10n);
      expect(copyButtonFinder, findsOneWidget);

      await tester.tap(copyButtonFinder);
      await tester.pumpAndSettle();

      expect(clipboardText, isNotNull);
      expect(clipboardText, contains('World Markdown'));
      expect(clipboardText, isNot(contains('#')));
    });

    testWidgets('Context menu appears and disappears correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFinder = find.textContaining('Hello');

      await tester.longPress(textFinder);
      await tester.pumpAndSettle();

      final copyButtonFinder = find.byType(AdaptiveTextSelectionToolbar);
      expect(copyButtonFinder, findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      final copyButtonFinder1 = find.byType(AdaptiveTextSelectionToolbar);
      expect(copyButtonFinder1, findsNothing);
    });
  });
}
