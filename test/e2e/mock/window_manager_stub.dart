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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Register no-op handler for each method from window manager.
/// 
/// It must be used when mocking Desktop platform on Web.
void registerWindowManagerStub() {
  const channel = MethodChannel('window_manager');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        final String m = call.method;
        if (m.startsWith('is')) return false; // any boolean getters
        switch (m) {
          case 'getSize':
            return const <double>[800, 600];
          case 'getPosition':
            return const <double>[0, 0];
          default:
            return null;
        }
      });
}
