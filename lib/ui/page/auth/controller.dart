// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'dart:async';

import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:get/get.dart';
import 'package:rive/rive.dart';

import '/domain/service/auth.dart';
import '/l10n/_l10n.dart';
import '/routes.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// [Routes.auth] page controller.
class AuthController extends GetxController {
  AuthController(this._auth);

  /// Authorization service used for signing up.
  final AuthService _auth;

  /// Current logo's animation frame.
  RxInt logoFrame = RxInt(0);

  /// Index number of selected language.
  late final RxInt selectedLanguage;

  /// A trigger of blink logo animation.
  SMITrigger? blink;

  /// [GlobalKey] of an animated button used to share it between overlays.
  final GlobalKey languageKey = GlobalKey();

  /// Prevents instant language change after the user has set
  ///  [selectedLanguage].
  late final Worker _languageDebounce;

  /// Timer that periodically increases [logoFrame].
  Timer? _animationTimer;

  /// Returns user authentication status.
  Rx<RxStatus> get authStatus => _auth.status;

  @override
  void onInit() {
    selectedLanguage = RxInt(L10n.languages.keys.toList().indexOf(L10n.chosen));
    _languageDebounce = debounce(
      selectedLanguage,
      (int i) {
        L10n.chosen = L10n.languages.keys.elementAt(i);
        Get.updateLocale(L10n.locales[L10n.chosen]!);
      },
      time: 500.milliseconds,
    );

    super.onInit();
  }

  @override
  void onClose() {
    _animationTimer?.cancel();
    blink?.controller.dispose();
    _languageDebounce.dispose();
    super.onClose();
  }

  @override
  void onReady() => Future.delayed(const Duration(milliseconds: 500), animate);

  /// Registers and redirects to the [Routes.home] page.
  Future<void> register() async {
    try {
      await _auth.register();
      router.home();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Resets the [logoFrame] and starts the animation.
  void animate() {
    blink?.fire();

    logoFrame.value = 1;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 45), (t) {
      ++logoFrame.value;
      if (logoFrame >= 9) t.cancel();
    });
  }
}
