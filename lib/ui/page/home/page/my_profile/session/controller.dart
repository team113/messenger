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

import 'dart:async';
import 'dart:math';

import 'package:apple_product_name/apple_product_name.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart';
import '/config.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/session.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/widget/text_field.dart';
import 'view.dart';

export 'view.dart';

/// Possible screen of a [DeleteSessionView].
enum DeleteSessionStage { info, confirm, done }

/// Controller of a [DeleteSessionView].
class DeleteSessionController extends GetxController {
  DeleteSessionController(
    this._authService,
    this._myUserService, {
    this.pop,
    this.sessions = const [],
  });

  /// [TextFieldState] of the [MyUser]'s password.
  late final TextFieldState password;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// [RxSession]s to delete.
  final List<RxSession> sessions;

  /// Callback, called when an [DeleteSessionView] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function()? pop;

  /// Current [DeleteSessionStage] being displayed.
  final Rx<DeleteSessionStage> stage = Rx(DeleteSessionStage.info);

  /// Timeout of a [sendConfirmationCode] next invoke attempt.
  final RxInt resendEmailTimeout = RxInt(0);

  /// [AuthService] used to delete a [Session].
  final AuthService _authService;

  /// [MyUserService] maintaining the [MyUser].
  final MyUserService _myUserService;

  /// [Timer] used to disable resend code button [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    password = TextFieldState(
      onSubmitted: (s) async {
        if (s.error.value != null || s.status.value.isLoading) {
          return;
        }

        s.editable.value = false;
        s.status.value = RxStatus.loading();

        final bool hasEmail = myUser.value?.emails.confirmed.isNotEmpty == true;

        try {
          final List<Future> futures = [
            ...sessions.map((e) {
              final code = ConfirmationCode.tryParse(s.text);

              if (code == null || !hasEmail) {
                return _authService.deleteSession(
                  id: e.id,
                  password: s.text.isEmpty ? null : UserPassword(s.text),
                );
              }

              // Otherwise first try the parsed [ConfirmationCode].
              return Future(() async {
                try {
                  await _authService.deleteSession(id: e.id, code: code);
                } on DeleteSessionException catch (ex) {
                  switch (ex.code) {
                    // If wrong, then perhaps it may be a password instead?
                    case DeleteSessionErrorCode.wrongCode:
                      await _authService.deleteSession(
                        id: e.id,
                        password: s.text.isEmpty ? null : UserPassword(s.text),
                      );
                      break;

                    default:
                      rethrow;
                  }
                }
              });
            }),
          ];

          await Future.wait(futures);

          stage.value = DeleteSessionStage.done;
        } on DeleteSessionException catch (e) {
          s.error.value = e.toMessage();
        } catch (e) {
          s.error.value = 'err_data_transfer'.l10n;
          rethrow;
        } finally {
          s.status.value = RxStatus.empty();
          s.editable.value = true;
        }
      },
    );

    if (myUser.value?.emails.confirmed.isNotEmpty == true) {
      sendConfirmationCode();
    }

    super.onInit();
  }

  /// Sends a [ConfirmationCode] to confirm the [AuthService.deleteSession].
  Future<void> sendConfirmationCode() async {
    _setResendEmailTimer();

    try {
      await _authService.createConfirmationCode();
    } catch (e) {
      password.resubmitOnError.value = true;
      password.error.value = 'err_data_transfer'.l10n;
      _setResendEmailTimer(false);
      rethrow;
    }
  }

  /// Starts or stops the [_resendEmailTimer] based on [enabled] value.
  void _setResendEmailTimer([bool enabled = true]) {
    if (enabled) {
      resendEmailTimeout.value = 30;
      _resendEmailTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        resendEmailTimeout.value--;
        if (resendEmailTimeout.value <= 0) {
          resendEmailTimeout.value = 0;
          _resendEmailTimer?.cancel();
          _resendEmailTimer = null;
        }
      });
    } else {
      resendEmailTimeout.value = 0;
      _resendEmailTimer?.cancel();
      _resendEmailTimer = null;
    }
  }
}

/// Extension adding ability to get the human readable name from a [UserAgent].
extension UserAgentExtension on UserAgent {
  /// List of [BrowserRule]s to look for in this [UserAgent].
  static final List<BrowserRule> _rules = [
    const BrowserRule(rule: 'Firefox'),
    const BrowserRule(rule: 'Edg', name: 'Microsoft Edge', versionDepth: 1),
    const BrowserRule(rule: r'OPR|Opera', name: 'Opera'),
    const BrowserRule(rule: 'SamsungBrowser', name: 'Samsung Browser'),
    const BrowserRule(rule: 'YaBrowser', name: 'Yandex Browser'),
    const BrowserRule(rule: 'Chrome', versionDepth: 1),
    const BrowserRule(rule: 'Safari'),
  ];

  /// Returns the human readable name of this [UserAgent], if any, or otherwise
  /// returns the whole [UserAgent].
  ///
  /// The retrieved value depends on the operating system:
  /// 1) For Android it outputs the device manufacturer and identifier:
  /// - `Xiaomi M2101K7BNY`
  /// 2) For iOS it outputs the device name and model:
  /// - `iPad Pro (12.9-inch) (5th generation)`
  /// - `iPhone 14 Pro`
  /// 3) For macOS it outputs the device name and model:
  /// - `MacBook Air (M2, 2022)`
  /// 4) For Linux/Windows it outputs the OS name and version:
  /// - `Ubuntu 22.04 LTS`
  /// - `Windows 11 Home`
  /// 5) For browsers it returns the browser name and version:
  /// - `Safari 17.4.1`
  /// - `Chrome 124`
  /// - `Microsoft Edge 111`
  String get localized {
    // If [UserAgent] starts with "Mozilla", then it's probably a browser's
    // `User-Agent` header.
    if (val.startsWith('Mozilla')) {
      // Header values are separated by spaces.
      final List<String> parts = val.split(' ');

      // Browser's `User-Agent` may contain the `Version` tag.
      final String? versionPart = parts.firstWhereOrNull(
        (e) => e.startsWith('Version/'),
      );

      for (final BrowserRule e in _rules) {
        // Lookup the part that is identifiable by any [BrowserRule] out there.
        final int i = parts.indexWhere((p) => p.startsWith(e.rule));

        if (i != -1) {
          // `User-Agent` tag should be something like `Label/1.0.0`, and we
          // need the number part, so try to retrieve it.
          final List<String> tag = (versionPart ?? parts[i]).split('/');

          if (tag.length > 1) {
            String version = tag[1];

            // If the [BrowserRule] requests the version to contain only
            // specified depth, then trim it.
            if (e.versionDepth != null) {
              version = version = version
                  .split('.')
                  .take(e.versionDepth!)
                  .join('.');
            }

            return '${e.name} $version';
          } else {
            return e.name;
          }
        }
      }
    }
    // Otherwise it's probably a one generated via [WebUtils.userAgent] method.
    else {
      // Retrieve `.../... (this part)` from the header.
      final String meta = val.substring(
        max(val.indexOf('(') + 1, 0),
        val.endsWith(')') ? val.length - 1 : val.length,
      );

      // Header values are separated by semicolons.
      final List<String> parts = meta.split(';');

      // First part should have the name of operating system.
      final String system = parts.first.trim();

      // If there's no second part at all, return the first one right away.
      if (parts.length < 2) {
        return system;
      }

      // Android devices have an identifier that should be embedded into the
      // second part of the header, thus should return it.
      if (system.startsWith('Android')) {
        return parts.elementAt(1).trim();
      }

      // The following systems have a device identifier that should be embedded
      // into the second part of the header, thus should parse it with
      // [AppleProductName] and return it.
      if (system.startsWith('macOS') ||
          system.startsWith('iOS') ||
          system.startsWith('iPadOS') ||
          system.startsWith('visionOS') ||
          system.startsWith('watchOS') ||
          system.startsWith('tvOS')) {
        return AppleProductName().lookup(parts.elementAt(1).trim());
      }

      return system;
    }

    return val;
  }

  /// Returns the operating system of this [UserAgent].
  String get system {
    // If [UserAgent] starts with "Mozilla", then it's probably a browser's
    // `User-Agent` header.
    if (val.startsWith('Mozilla')) {
      if (val.contains('Windows NT')) {
        return 'Windows';
      } else if (val.contains('iPad')) {
        return 'iPadOS';
      } else if (val.contains('iPhone')) {
        return 'iOS';
      } else if (val.contains('Macintosh')) {
        return 'macOS';
      } else if (val.contains('Android')) {
        return 'Android';
      } else if (val.contains('X11') || val.contains('Linux')) {
        return 'Linux';
      } else {
        return 'Unknown';
      }
    }
    // Otherwise it's probably a one generated via [WebUtils.userAgent] method.
    else {
      final String meta = val.substring(
        max(val.indexOf('(') + 1, 0),
        val.endsWith(')') ? val.length - 1 : val.length,
      );

      // First part should have the name of operating system.
      final List<String> parts = meta.split(';');
      final String system = parts.first.trim();

      if (system.startsWith('Android')) {
        return 'Android';
      } else if (system.startsWith('macOS')) {
        return 'macOS';
      } else if (system.startsWith('iOS')) {
        return 'iOS';
      } else if (system.startsWith('iPadOS')) {
        return 'iPadOS';
      } else if (system.startsWith('visionOS')) {
        return 'visionOS';
      } else if (system.startsWith('watchOS')) {
        return 'watchOS';
      } else if (system.startsWith('tvOS')) {
        return 'tvOS';
      } else if (system.startsWith('Windows')) {
        return 'Windows';
      } else {
        return system;
      }
    }
  }

  /// Returns the [Config.userAgentProduct] with the version parsed from this
  /// [UserAgent].
  String get application {
    // If [UserAgent] starts with "Mozilla", then it's probably a browser's
    // `User-Agent` header.
    if (val.startsWith('Mozilla')) {
      return localized;
    }
    // Otherwise it's probably a one generated via [WebUtils.userAgent] method.
    else {
      // Header values are separated by semicolons.
      final List<String> parts = val.split(' ');

      // Values are separated by spaces.
      final List<String> versions = parts.first.split('/');

      if (versions.length == 2) {
        return '${versions[0]} ${versions[1]}';
      }

      // First part should have the name of operating system.
      return parts.first.trim();
    }
  }
}

/// Data for parsing a browser from a [UserAgent].
class BrowserRule {
  const BrowserRule({required this.rule, String? name, this.versionDepth})
    : _name = name;

  /// [Pattern] of the browser.
  final Pattern rule;

  /// Depth of the browser version to display.
  ///
  /// If `null`, then version should be fully shown.
  final int? versionDepth;

  /// Name of the browser.
  final String? _name;

  /// Returns name of the browser.
  String get name => _name ?? rule.toString();
}
