// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:messenger/ui/page/home/widget/scroll_keyboard_handler.dart';

void main() {
  late ScrollController scrollController;

  setUp(() {
    scrollController = ScrollController();
  });

  tearDown(() {
    scrollController.dispose();
  });

  Widget buildTestWidget({bool reverseList = false, double maxHeight = 1000}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: maxHeight,
          child: ScrollKeyboardHandler(
            scrollController: scrollController,
            reversed: reverseList,
            child: ListView.builder(
              controller: scrollController,
              itemCount: 100,
              itemBuilder: (context, index) =>
                  SizedBox(height: 100, child: Text('Item $index')),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendKeyEvent(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  Future<void> sendKeyEventWithAlt(
    WidgetTester tester,
    LogicalKeyboardKey key,
  ) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    await tester.sendKeyDownEvent(key);
    await tester.pump();
    await tester.sendKeyUpEvent(key);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();

    await tester.pumpAndSettle();
  }

  group('ScrollKeyboardHandler', () {
    testWidgets('Builds without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(ScrollKeyboardHandler), findsOneWidget);
    });

    testWidgets('Handles "PageUp" key', (tester) async {
      scrollController = ScrollController(initialScrollOffset: 600);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final initialOffset = scrollController.offset;

      await sendKeyEvent(tester, LogicalKeyboardKey.pageUp);

      expect(scrollController.offset < initialOffset, true);
    });

    testWidgets('Handles "PageDown" key', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final initialOffset = scrollController.offset;

      await sendKeyEvent(tester, LogicalKeyboardKey.pageDown);

      expect(scrollController.offset > initialOffset, true);
    });

    testWidgets('Handles "Alt+ArrowUp" combination', (tester) async {
      scrollController = ScrollController(initialScrollOffset: 500);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final initialOffset = scrollController.offset;

      await sendKeyEventWithAlt(tester, LogicalKeyboardKey.arrowUp);

      expect(scrollController.offset < initialOffset, true);
    });

    testWidgets('Handles "Alt+ArrowDown" combination', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final initialOffset = scrollController.offset;

      await sendKeyEventWithAlt(tester, LogicalKeyboardKey.arrowDown);

      expect(scrollController.offset > initialOffset, true);
    });

    testWidgets('Scrolls to start with alternative `maxHeight`', (
      tester,
    ) async {
      scrollController = ScrollController(initialScrollOffset: 400);
      const maxHeight = 300.0;
      const defaultFactor = 0.95;

      await tester.pumpWidget(buildTestWidget(maxHeight: maxHeight));
      await tester.pumpAndSettle();

      final initialOffset = scrollController.offset;

      await sendKeyEvent(tester, LogicalKeyboardKey.pageUp);

      final expectedScroll = maxHeight * defaultFactor;
      expect(
        scrollController.offset,
        equals(
          (initialOffset - expectedScroll).clamp(
            0,
            scrollController.position.maxScrollExtent,
          ),
        ),
      );
      await sendKeyEvent(tester, LogicalKeyboardKey.pageUp);
      expect(scrollController.offset, equals(0));
    });

    testWidgets('Clamps scroll offset to valid range', (tester) async {
      scrollController = ScrollController(initialScrollOffset: 0);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await sendKeyEvent(tester, LogicalKeyboardKey.pageUp);
      expect(scrollController.offset, equals(0));
    });

    testWidgets('Scrolls to top with long press "PageUp" key', (tester) async {
      scrollController = ScrollController(initialScrollOffset: 1000);

      await tester.pumpWidget(buildTestWidget(maxHeight: 300));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();

      // Experimentally selected number, may require modification when editing
      // the animation.
      for (int i = 0; i < 100; i++) {
        // Waiting for the animation to complete without call pumpAndSettle().
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.pageUp);
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
      }

      await tester.sendKeyUpEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();

      expect(scrollController.offset, equals(0));
    });
  });
}
