import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/ui/page/work/page/freelance/helper_function/markdown_selected_text_from_full_text.dart';
import 'package:flutter_test/flutter_test.dart';
// Import the file where your function is located
// import 'package:your_project/utils/string_functions.dart';

void main() {
  group('markdownSelectedTextFromFullText Tests', () {

    test('Should return an empty string if selectedText is empty', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'Hello World',
        selectedText: '',
      );
      expect(result, equals(''));
    });

    test('Should return selectedText directly if it exists perfectly within fullText', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'Flutter is amazing',
        selectedText: 'is amazing',
      );
      expect(result, equals('is amazing'));
    });

    test('Should replace dashes with bullets in fullText', () {
      // The function replaces ' - ' with ' • '
      final result = markdownSelectedTextFromFullText(
        fullText: 'Item - description',
        selectedText: 'Item • description',
      );
      expect(result, equals('Item • description'));
    });

    test('Should strip markdown-like characters (#, [, ], `) from fullText', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'This is a #Header with [link] and `code`',
        selectedText: 'This is a Header with link and code',
      );
      expect(result, equals('This is a Header with link and code'));
    });

    test('Should remove non-ASCII characters (like emojis) based on RegEx', () {
      final result = markdownSelectedTextFromFullText(
        fullText: 'Hello Rocket 🚀',
        selectedText: 'Hello Rocket 🚀',
      );
      // The RegEx [^\x20-\x7E] removes the rocket emoji
      expect(result.trim(), equals('Hello Rocket'));
    });

    test('Should find partial matches using beginning and end search logic', () {
      // If selectedText starts or ends with characters NOT in fullText,
      // the loops should trim them until a match is found.
      final result = markdownSelectedTextFromFullText(
        fullText: 'The quick brown fox',
        selectedText: 'XYZquick brown ABC',
      );

      expect(result, contains('quick brown'));
      expect(result, isNot(contains('XYZ')));
      expect(result, isNot(contains('ABC')));
    });

    test('Should handle cases where endList length is greater than 2', () {
      // This triggers the complex 'if(endList.length > 2)' logic in your function
      final result = markdownSelectedTextFromFullText(
        fullText: 'repeat repeat repeat',
        selectedText: 'repeat repeat',
      );
      expect(result, isNotEmpty);
      expect(result, contains('repeat repeat'));
    });
  });
}
