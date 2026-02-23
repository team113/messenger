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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/markdown.dart';

/// Widget tests for [MarkdownWidget].
///
/// These tests validate:
/// - Cross-platform text selection behavior.
/// - Clipboard copy integration.
/// - Context menu appearance and dismissal.
/// - Proper handling of asynchronous initialization.
///
/// The widget internally:
/// - Disables the browser context menu on web.
/// - Wraps content in a [SelectableRegion].
/// - Reconstructs selected markdown text before copying.
///
/// Clipboard interactions are mocked to verify copied content
/// without requiring platform-level clipboard access.
void main() {
  // Required to handle clipboard and platform channel mocking.
  TestWidgetsFlutterBinding.ensureInitialized();

  const testText = '''
Hello world
Second line
Third line
''';

  /// Builds a test instance of [MarkdownWidget] wrapped
  /// in a minimal [MaterialApp] + [Scaffold].
  Widget buildTestWidget() {
    return MaterialApp(
      theme: Themes.light(),
      home: Scaffold(
        body: MarkdownWidget(testText),
      ),
    );
  }

  group('MarkdownWidget Selection and Copy Tests', () {
    const String testBody = 'Hello - World #Markdown Test';

    /// Verifies that text selection triggers reconstruction logic
    /// and that processed text is copied to the clipboard.
    ///
    /// Since simulating real platform-level selection gestures
    /// in widget tests is complex, the [SelectableRegion.onSelectionChanged]
    /// callback is triggered manually.
    testWidgets(
      'Processes and copies text when selection changes',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: Themes.light(),
              home: Scaffold(
                body: MarkdownWidget(testBody),
              ),
            ),
          );

          // Mock clipboard storage.
          final Map<String, dynamic> clipboardData = <String, dynamic>{
            'text': ''
          };

          tester.binding.defaultBinaryMessenger
              .setMockMethodCallHandler(
            SystemChannels.platform,
                (MethodCall methodCall) async {
              if (methodCall.method == 'Clipboard.setData') {
                clipboardData['text'] =
                methodCall.arguments['text'];
                return null;
              }
              if (methodCall.method == 'Clipboard.getData') {
                return clipboardData;
              }
              return null;
            },
          );

          // Allow FutureBuilder to complete (_disableContextMenu).
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();

          final selectableRegionFinder =
          find.byType(SelectableRegion);

          expect(selectableRegionFinder, findsOneWidget);

          final SelectableRegion selectableRegion =
          tester.widget(selectableRegionFinder);

          // Simulate selecting text containing markdown characters.
          selectableRegion.onSelectionChanged!(
            SelectedContent(
              plainText: 'World #Markdown',
            ),
          );

          // Simulate clearing selection to trigger clipboard copy.
          selectableRegion.onSelectionChanged!(null);

          final ClipboardData? data =
          await Clipboard.getData('text/plain');

          // '#' should be removed during normalization.
          expect(data?.text, contains('World Markdown'));
          expect(data?.text, isNot(contains('#')));
        });
      },
    );

    /// Ensures that the loading indicator is displayed
    /// before asynchronous initialization completes.
    testWidgets(
      'Displays loading indicator initially',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: Themes.light(),
            home: Scaffold(
              body: MarkdownWidget(testBody),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator),
            findsOneWidget);
      },
    );

    /// Verifies that the context menu appears after text selection
    /// and contains a "Copy" action.
    ///
    /// This test simulates tap and long-press gestures to trigger
    /// Flutter's selection overlay.
    testWidgets(
      'Context menu appears and contains Copy button',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          final textFinder =
          find.textContaining('Hello');

          expect(textFinder, findsOneWidget);

          await tester.tap(textFinder);
          await tester.pumpAndSettle();

          await tester.longPress(textFinder);
          await tester.pumpAndSettle();

          expect(find.text('Copy'), findsOneWidget);
        });
      },
    );

    /// Ensures that tapping outside the selected region
    /// dismisses the context menu.
    testWidgets(
      'Context menu disappears after tapping outside',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          final textFinder =
          find.textContaining('Hello');

          expect(textFinder, findsOneWidget);

          await tester.tap(textFinder);
          await tester.pumpAndSettle();

          await tester.longPress(textFinder);
          await tester.pumpAndSettle();

          expect(find.text('Copy'), findsOneWidget);

          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();

          expect(find.text('Copy'), findsNothing);
        });
      },
    );
  });
}
