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

void main() {
  group('Debouncer tests', () {
    test('the debouncer is triggered after 500 milliseconds', () async {
      final state = TextFieldState(
        onChanged: (s) {
          expect(s.text, 'zhorenty');
        },
      );
      state.controller.text = 'zhorenty';
      await Future.delayed(const Duration(milliseconds: 900));
      expect(state.changed.value, false);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(state.changed.value, true);
    });
  });

  group('TextFieldState tests', () {
    test('TextFieldState onChanged called for valid input', () {
      final state = TextFieldState(
        onChanged: (state) {
          expect(state.changed.value, true);
        },
      );
      state.controller.text = 'zhorenty';
      state.controller.addListener(() => state.onChanged!(state));
    });

    test('TextFieldState onChanged not called for invalid input', () async {
      final state = TextFieldState(
        onChanged: (state) {
          expect(state.changed.value, true);
        },
      );
      state.controller.text = 'zhorenty#';
      state.controller.addListener(() => state.onChanged!(state));
      expect(state.changed.value, false);

      await Future.delayed(const Duration(milliseconds: 1100));
      state.controller.text = 'zhorenty';
      state.controller.addListener(() => state.onChanged!(state));
      expect(state.changed.value, true);
    });

    test('TextFieldState onSubmitted called when submit() is called', () {
      final state = TextFieldState(
        onSubmitted: (state) {
          expect(state.text, 'zhorenty');
        },
      );
      state.controller.text = 'zhorenty';
      state.submit();
    });

    test(
        'TextFieldState clear() clears the field and sets changed and isEmpty to false',
        () {
      final state = TextFieldState(
        onChanged: (state) {
          expect(state.changed.value, true);
        },
      );
      state.controller.text = 'zhorenty';
      state.controller.addListener(() => state.onChanged!(state));
      state.clear();
      expect(state.controller.text, '');
      expect(state.changed.value, false);
      expect(state.isEmpty.value, true);
    });
  });
}
