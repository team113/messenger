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
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/markdown.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget() {
    return MaterialApp(
      theme: Themes.light(),
      home: const Scaffold(
        body: MarkdownWidget('Hello - World #Markdown Test'),
      ),
    );
  }

  group('MarkdownWidget', () {
    testWidgets('Displays Markdown content', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('Hello'), findsOneWidget);
      });
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
