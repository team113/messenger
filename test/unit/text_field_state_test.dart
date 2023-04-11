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

class MockFunction extends Mock {
  void call(TextFieldState state);
}

void main() {
  group('TextFieldState tests', () {
    test('onChanged called with right timeout', () async {
      final mockFunction = MockFunction();
      final state = TextFieldState(
        onChanged: mockFunction,
      );
      state.controller.text = 'zhorenty';
      verifyNever(mockFunction.call(state));

      await Future.delayed(state.timeout);
      expect(state.changed.value, true);
      expect(state.controller.text, 'zhorenty');
      verify(mockFunction.call(state)).called(1);
    });

    test('onSubmitted called when TextFieldState.submit is called', () {
      final mockFunction = MockFunction();
      final state = TextFieldState(
        onSubmitted: mockFunction,
      );
      state.controller.text = 'zhorenty';
      state.submit();
      verify(mockFunction.call(state)).called(1);
    });
  });
}
