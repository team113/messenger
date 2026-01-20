// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_gherkin/flutter_gherkin_with_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/keys.dart';
import '../world/custom_world.dart';

/// Scrolls the provided [Scrollable] until the specified [WidgetKey] is present
/// within that list.
///
/// Examples:
/// - Then I scroll `Menu` until `LogoutButton` is present
final StepDefinitionGeneric<CustomWorld> scrollUntilPresent =
    then2<WidgetKey, WidgetKey, CustomWorld>(
      RegExp(r'I scroll {key} until {key} is present'),
      (WidgetKey list, WidgetKey key, StepContext<CustomWorld> context) async {
        await context.world.appDriver.waitUntil(() async {
          await context.world.appDriver.nativeDriver.pump(
            const Duration(seconds: 2),
            EnginePhase.sendSemanticsUpdate,
          );

          final scrollable = find.descendant(
            of: find.byKey(Key(list.name)),
            matching: find.byWidgetPredicate((widget) {
              // TODO: Find a proper way to differentiate [Scrollable]s from
              //       [TextField]s:
              //       https://github.com/flutter/flutter/issues/76981
              if (widget is Scrollable) {
                return widget.restorationId == null;
              }
              return false;
            }),
          );

          if (scrollable.evaluate().isEmpty) {
            return false;
          }

          await context.world.appDriver.scrollIntoVisible(
            context.world.appDriver.findByKeySkipOffstage(key.name),
            scrollable.first,
            dy: 50,
          );

          return true;
        }, timeout: const Duration(seconds: 30));

        await context.world.appDriver.nativeDriver.pump(
          const Duration(seconds: 2),
          EnginePhase.sendSemanticsUpdate,
        );
      },
    );

/// Scrolls the provided [Scrollable] to the bottom.
///
/// Examples:
/// - Then I scroll `Menu` to bottom
final StepDefinitionGeneric<CustomWorld> scrollToBottom =
    then1<WidgetKey, CustomWorld>(RegExp(r'I scroll {key} to bottom'), (
      WidgetKey key,
      StepContext<CustomWorld> context,
    ) async {
      await _scrollScrollableTo(key, context, (p) => p.maxScrollExtent);
    });

/// Scrolls the provided [Scrollable] to the top.
///
/// Examples:
/// - Then I scroll `Menu` to top
final StepDefinitionGeneric<CustomWorld> scrollToTop =
    then1<WidgetKey, CustomWorld>(RegExp(r'I scroll {key} to top'), (
      WidgetKey key,
      StepContext<CustomWorld> context,
    ) async {
      await _scrollScrollableTo(key, context, (_) => 0);
    });

/// Scrolls the [Scrollable] identified by its [key] to the specified in the
/// [getPosition] position.
Future<void> _scrollScrollableTo(
  WidgetKey key,
  StepContext<CustomWorld> context,
  double Function(ScrollPosition) getPosition,
) async {
  await context.world.appDriver.waitUntil(() async {
    await context.world.appDriver.waitForAppToSettle();

    final Finder scrollable = find.descendant(
      of: find.byKey(Key(key.name)),
      matching: find.byWidgetPredicate((widget) {
        // TODO: Find a proper way to differentiate [Scrollable]s from
        //       [TextField]s:
        //       https://github.com/flutter/flutter/issues/76981
        if (widget is Scrollable) {
          return widget.restorationId == null;
        }
        return false;
      }),
    );

    if (!scrollable.tryEvaluate()) {
      return false;
    }

    final ScrollableState state =
        context.world.appDriver.nativeDriver.state(scrollable)
            as ScrollableState;
    final ScrollPosition position = state.position;

    position.jumpTo(getPosition(position));

    await context.world.appDriver.waitForAppToSettle();

    return true;
  });
}

/// Extension fixing the [AppDriverAdapter.scrollUntilVisible] by adding its
/// replacement.
extension ScrollAppDriverAdapter<TNativeAdapter, TFinderType, TWidgetBaseType>
    on AppDriverAdapter {
  /// Scrolls the [scrollable] by [dy] until the [finder] is visible.
  Future<void> scrollIntoVisible(
    Finder finder,
    Finder scrollable, {
    double dy = 100,
  }) async {
    final WidgetTester tester = (nativeDriver as WidgetTester);

    final double height =
        (tester.view.physicalSize / tester.view.devicePixelRatio).height;

    for (int i = 0; i < 500; ++i) {
      final ScrollableState state = tester.state(scrollable) as ScrollableState;
      final ScrollPosition position = state.position;

      if (await isPresent(finder)) {
        await Scrollable.ensureVisible(finder.evaluate().first, alignment: 0.5);

        // If [finder] is present and it's within our view, then break the loop.
        if (tester.getCenter(finder.first).dy <= height - dy ||
            position.pixels >= position.maxScrollExtent) {
          break;
        }
      }

      // Or otherwise keep on scrolling the [scrollable].
      position.jumpTo(min(position.pixels + dy, position.maxScrollExtent));

      await tester.pump();
    }
  }
}
