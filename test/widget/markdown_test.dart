import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/markdown.dart';

void main() {
  // Required to handle clipboard and plugin mocks
  TestWidgetsFlutterBinding.ensureInitialized();
  const testText = '''
Hello world
Second line
Third line
''';

  Widget buildTestWidget() {
    return  MaterialApp(theme: Themes.light(),
      home: Scaffold(
        body: MarkdownWidget(testText),
      ),
    );
  }

  group('MarkdownWidget Selection and Copy Tests', () {
    const String testBody = 'Hello - World #Markdown Test';

    testWidgets('Should process and copy text when selection changes', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // 1. Render the widget
        await tester.pumpWidget(
          MaterialApp(theme: Themes.light(),
            home: Scaffold(
              body: MarkdownWidget(testBody),
            ),
          ),
        );
        final Map<String, dynamic> clipboardData = <String, dynamic>{
          'text': ''
        };

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
              (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              clipboardData['text'] = methodCall.arguments['text'];
              return null;
            }
            if (methodCall.method == 'Clipboard.getData') {
              return clipboardData;
            }
            return null;
          },
        );
        // 2. Handle the FutureBuilder (initial state is CircularProgressIndicator)
        await tester.pump(Duration.zero); // Start future
        await tester.pumpAndSettle(); // Wait for _disableContextMenu()

        // 3. Find the SelectableRegion
        final selectableRegionFinder = find.byType(SelectableRegion);
        expect(selectableRegionFinder, findsOneWidget);

        // 4. Simulate selection change
        // We manually trigger the onSelectionChanged callback since
        // simulating platform-level text selection gestures in tests is complex.
        final SelectableRegion state = tester.widget(selectableRegionFinder);

        // Simulate selecting "World #Markdown"
        // Note: your function should strip '#' and convert ' - ' to ' • '
        state.onSelectionChanged!(
          SelectedContent(
            plainText: 'World #Markdown',
          ),
        );

        // 5. Trigger the clipboard copy logic
        // In code, when selectedContent is blank/null, you call Clipboard.setData
        state.onSelectionChanged!(null);

        // 6. Verify Clipboard content
        // Based on markdownSelectedTextFromFullText logic:
        // "#" is removed, so "World #Markdown" becomes "World Markdown"
        final ClipboardData? data = await Clipboard.getData('text/plain');

        expect(data?.text, contains('World Markdown'));
        expect(data?.text, isNot(contains('#')));
      });
    });

    testWidgets('Should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
         MaterialApp(theme: Themes.light(),
          home: Scaffold(
            body: MarkdownWidget(testBody),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'Context menu appears after second tap and contains Copy button',
            (WidgetTester tester) async {
              await tester.runAsync(() async {

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          // Find rendered text
          final textFinder = find.textContaining('Hello');

          expect(textFinder, findsOneWidget);

          // First tap (start selection)
          await tester.tap(textFinder);
          await tester.pumpAndSettle();

          // Long press to create selection
          await tester.longPress(textFinder);
          await tester.pumpAndSettle();


          // Expect Copy button
          expect(find.text('Copy'), findsOneWidget);});
        });

    testWidgets(
        'Context menu disappears after tapping outside',
            (WidgetTester tester) async {
              await tester.runAsync(() async {
                await tester.pumpWidget(buildTestWidget());
                await tester.pumpAndSettle();

                final textFinder = find.textContaining('Hello');

                expect(textFinder, findsOneWidget);
                // First tap (start selection)
                await tester.tap(textFinder);
                await tester.pumpAndSettle();

                await tester.longPress(textFinder);
                await tester.pumpAndSettle();


                // Verify Copy exists
                expect(find.text('Copy'), findsOneWidget);

                // Tap outside (top-left corner)
                await tester.tapAt(const Offset(5, 5));
                await tester.pumpAndSettle();

                // Context menu should disappear
                expect(find.text('Copy'), findsNothing);
              });
            });

  });
}
