// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('TextFieldState works correctly', () {
    // Dummy callback to ensure it's being called.
    final _Mock mock = _Mock();

    test('TextFieldState.onChanged has correct debounce', () async {
      final TextFieldState state = TextFieldState(onChanged: mock.dummy)
        ..controller.text = 'zhorenty';

      verifyNever(mock.dummy.call(state));

      await Future.delayed(TextFieldState.debounce);

      expect(state.changed.value, true);
      expect(state.controller.text, 'zhorenty');

      verify(mock.dummy.call(state)).called(1);
    });

    test('TextFieldState.onSubmitted is called', () {
      final TextFieldState state = TextFieldState(onSubmitted: mock.dummy)
        ..controller.text = 'zhorenty'
        ..submit();

      verify(mock.dummy.call(state)).called(1);
    });
  });
}

/// [Mock] for verifying its [dummy] method being called or not.
class _Mock extends Mock {
  /// Dummy method to ensure it's being called.
  void dummy(TextFieldState state);
}
