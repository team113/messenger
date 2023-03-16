import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/ui/widget/text_field.dart';

void main() {
  group('Debouncer tests', () {
    test('the debouncer is triggered after 500 milliseconds', () async {
      final state = TextFieldState(
        onChanged: (s) {
          expect(s.text, 'test');
        },
      );
      state.controller.text = 'test';
      await Future.delayed(const Duration(milliseconds: 400));
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

      await Future.delayed(const Duration(milliseconds: 600));
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
