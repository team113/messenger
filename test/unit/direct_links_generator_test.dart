import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/domain/model/user.dart';

void main() {
  group('ChatDirectLinkSlug', () {
    test('Should generate a slug of given length', () {
      final slug = ChatDirectLinkSlug.generate(10);
      expect(slug.val.length, equals(10));
    });

    test('Should generate a slug with valid characters', () {
      final slug = ChatDirectLinkSlug.generate(10);
      final validChars = RegExp(r'^[A-Za-z0-9_-]+$');
      expect(validChars.hasMatch(slug.val), isTrue);
    });

    test('Should not end with a hyphen', () {
      final slug = ChatDirectLinkSlug.generate();
      expect(slug.val.endsWith('-'), isFalse);
    });
  });
}
