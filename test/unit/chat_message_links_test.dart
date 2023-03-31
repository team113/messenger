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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

void main() async {
  test(
    'detectLinksAndEmails correctly separates plain text from links and emails',
    () async {
      final List<TapGestureRecognizer> linkGestureRecognizers = [];

      const String text1 =
          'The first set of Holmes stories was published between 1887 and 1893';
      final TextSpan textSpan1 =
          text1.detectLinksAndEmails(linkGestureRecognizers);
      expect(
        textSpan1.toPlainText(),
        'The first set of Holmes stories was published between 1887 and 1893',
      );

      const String text2 = 'I visited the site https://www.google.ru.';
      final TextSpan textSpan2 =
          text2.detectLinksAndEmails(linkGestureRecognizers);
      expect(textSpan2.children!.length, 3);
      expect(textSpan2.children![0].toPlainText(), 'I visited the site ');
      expect(textSpan2.children![1].toPlainText(), 'https://www.google.ru');
      expect(textSpan2.children![2].toPlainText(), '.');

      const String text3 =
          'Then clicked on the link www.yandex.com, looked into bing.com';
      final TextSpan textSpan3 =
          text3.detectLinksAndEmails(linkGestureRecognizers);
      expect(textSpan3.children!.length, 4);
      expect(textSpan3.children![0].toPlainText(), 'Then clicked on the link ');
      expect(textSpan3.children![1].toPlainText(), 'www.yandex.com');
      expect(textSpan3.children![2].toPlainText(), ', looked into ');
      expect(textSpan3.children![3].toPlainText(), 'bing.com');

      const String text4 =
          'I decided to go to api.flutter.dev/flutter/painting/TextSpan/recognizer.html, and went to bed.';
      final TextSpan textSpan4 =
          text4.detectLinksAndEmails(linkGestureRecognizers);
      expect(textSpan4.children!.length, 3);
      expect(textSpan4.children![0].toPlainText(), 'I decided to go to ');
      expect(
        textSpan4.children![1].toPlainText(),
        'api.flutter.dev/flutter/painting/TextSpan/recognizer.html',
      );
      expect(textSpan4.children![2].toPlainText(), ', and went to bed.');

      const String text5 =
          'I sent an email to lajive9827@fectode.com, and received a letter from the address cat.dog@gmail.com';
      final TextSpan textSpan5 =
          text5.detectLinksAndEmails(linkGestureRecognizers);
      expect(textSpan5.children!.length, 4);
      expect(textSpan5.children![0].toPlainText(), 'I sent an email to ');
      expect(textSpan5.children![1].toPlainText(), 'lajive9827@fectode.com');
      expect(
        textSpan5.children![2].toPlainText(),
        ', and received a letter from the address ',
      );
      expect(textSpan5.children![3].toPlainText(), 'cat.dog@gmail.com');
    },
  );
}
