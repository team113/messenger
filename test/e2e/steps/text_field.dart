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
import 'package:flutter/services.dart' show ClipboardData;
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/page/home/widget/num.dart';
import 'package:messenger/ui/widget/text_field.dart';

import '../configuration.dart';
import '../parameters/credentials.dart';
import '../parameters/keys.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Enters the given text into the widget with the provided [WidgetKey].
///
/// Examples:
/// - Then I fill `EmailField` field with "bob@gmail.com"
/// - Then I fill `NameField` field with "Woody Johnson"
StepDefinitionGeneric fillField = when2<WidgetKey, String, FlutterWorld>(
  'I fill {key} field with {string}',
  _fillField,
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

/// Enters the credential of the given [User] into the widget with the provided
/// [WidgetKey].
///
/// Examples:
/// - When I fill `SearchField` field with Bob's num
/// - When I fill `LoginField` field with Alice's login
/// - When I fill `SearchField` field with Bob's direct link
StepDefinitionGeneric fillFieldWithUserCredential =
    when3<WidgetKey, TestUser, TestCredential, CustomWorld>(
      'I fill {key} field with {user}\'s {credential}',
      (key, user, credential, context) async {
        final CustomUser? customUser =
            context.world.sessions[user.name]?.firstOrNull;

        if (customUser == null) {
          throw ArgumentError(
            '`${user.name}` is not found in `CustomWorld.sessions`.',
          );
        }

        final String text = _getCredential(customUser, credential);
        await _fillField(key, text, context);
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(seconds: 30),
    );

/// Enters the credential of [me] into the widget with the provided [WidgetKey].
///
/// Examples:
/// - When I fill `SearchField` field with my num
/// - When I fill `LoginField` field with my login
StepDefinitionGeneric fillFieldWithMyCredential =
    when2<WidgetKey, TestCredential, CustomWorld>(
      'I fill {key} field with my {credential}',
      (key, credential, context) async {
        final CustomUser? me = context.world.sessions.values
            .where((user) => user.userId == context.world.me)
            .firstOrNull
            ?.firstOrNull;

        if (me == null) {
          throw ArgumentError(
            '`MyUser` is not found in `CustomWorld.sessions`.',
          );
        }

        final String text = _getCredential(me, credential);
        await _fillField(key, text, context);
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(seconds: 30),
    );

/// Enters the given text into the widget with the provided [WidgetKey].
///
/// Examples:
/// - Then I fill `MessageField` field with 8192 "A" symbols
StepDefinitionGeneric fillFieldN = when3<WidgetKey, int, String, FlutterWorld>(
  'I fill {key} field with {int} {string} symbol(s)?',
  (key, quantity, text, context) => _fillField(key, text * quantity, context),
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

/// Pastes the [CustomWorld.clipboard] into the widget with the provided
/// [WidgetKey].
///
/// Examples:
/// - Then I paste to `EmailField` field
StepDefinitionGeneric pasteToField = when1<WidgetKey, CustomWorld>(
  'I paste to {key} field',
  (key, context) async {
    if (context.world.clipboard?.text == null) {
      throw ArgumentError('Nothing to fill, clipboard contains no text.');
    }

    await _fillField(key, context.world.clipboard!.text!, context);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

/// Enters the random [UserLogin] to the widget with the provided [WidgetKey].
///
/// Examples:
/// - When I fill `LoginField` field with random login
StepDefinitionGeneric fillFieldWithRandomLogin = when1<WidgetKey, CustomWorld>(
  'I fill {key} field with random login',
  (key, context) async {
    if (context.world.randomLogin == null) {
      UserLogin? random;

      do {
        random = UserLogin.tryParse(
          ChatDirectLinkSlug.generate(18).val.toLowerCase(),
        );
      } while (random == null);

      context.world.randomLogin = random;
    }

    await _fillField(key, '${context.world.randomLogin}', context);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 18),
);

/// Copies the value of the widget with the provided [WidgetKey] to the
/// [CustomWorld.clipboard].
///
/// Examples:
/// - Then I copy from `EmailField` field
StepDefinitionGeneric copyFromField = when1<WidgetKey, CustomWorld>(
  'I copy from {key} field',
  (key, context) async {
    await context.world.appDriver.waitForAppToSettle();
    final finder = context.world.appDriver.findBy(key.name, FindType.key);
    final Widget widget = finder.evaluate().single.widget;

    await context.world.appDriver.scrollIntoView(finder);
    await context.world.appDriver.waitForAppToSettle();

    final String? text;

    switch (widget.runtimeType) {
      case const (ReactiveTextField):
        text = (widget as ReactiveTextField).state.controller.text;
        break;

      case const (CopyableTextField):
        text = (widget as CopyableTextField).state.controller.text;
        break;

      case const (UserNumCopyable):
        text = (widget as UserNumCopyable).num.toString();
        break;

      default:
        throw ArgumentError('Nothing to copy from ${widget.runtimeType}.');
    }

    context.world.clipboard = ClipboardData(text: text);
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 30),
);

/// Enters the given [text] into the widget with the provided [WidgetKey].
Future<void> _fillField(
  WidgetKey key,
  String text,
  StepContext<FlutterWorld> context,
) async {
  await context.world.appDriver.waitUntil(() async {
    final finder = context.world.appDriver.findByKeySkipOffstage(key.name);

    if (await context.world.appDriver.isPresent(finder) &&
        finder.tryEvaluate()) {
      await context.world.appDriver.tap(
        finder,
        timeout: const Duration(seconds: 30),
      );

      await context.world.appDriver.waitForAppToSettle();

      await context.world.appDriver.enterText(
        finder,

        // TODO: Implement more strict way to localize some phrases.
        switch (text) {
          'Notes' => 'label_chat_monolog'.l10n,
          (_) => text,
        },
      );

      await context.world.appDriver.waitForAppToSettle();

      FocusManager.instance.primaryFocus?.unfocus();

      return true;
    }

    return false;
  }, timeout: const Duration(seconds: 30));
}

/// Returns [String] representation of the [CustomUser]'s [TestCredential].
String _getCredential(CustomUser customUser, TestCredential credential) {
  switch (credential) {
    case TestCredential.num:
      return customUser.userNum.val;

    // TODO: Throw [Exception], if [UserLogin] is not set, when `User.login`
    //       becomes available.
    case TestCredential.login:
      return 'lgn_${customUser.userNum.val}';

    case TestCredential.directLink:
      return '${customUser.slug}';
  }
}
