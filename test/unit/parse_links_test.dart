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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

void main() {
  test(
    'LinkParsingExtension.parseLinks correctly separates plain text from links and emails',
    () {
      const String text1 =
          'The first set of Holmes stories was published between 1887 and 1893';
      final TextSpan span1 = text1.parseLinks([]);
      expect(
        span1.toPlainText(),
        'The first set of Holmes stories was published between 1887 and 1893',
      );

      const String text2 = 'I visited the site https://www.google.com.';
      final TextSpan span2 = text2.parseLinks([]);
      expect(span2.children!.length, 3);
      expect(span2.children![0].toPlainText(), 'I visited the site ');
      expect(span2.children![1].toPlainText(), 'https://www.google.com');
      expect((span2.children![1] as TextSpan).recognizer != null, true);
      expect(span2.children![2].toPlainText(), '.');

      const String text3 =
          'Then clicked on the link www.yandex.com, looked into bing.com';
      final TextSpan span3 = text3.parseLinks([]);
      expect(span3.children!.length, 4);
      expect(span3.children![0].toPlainText(), 'Then clicked on the link ');
      expect(span3.children![1].toPlainText(), 'www.yandex.com');
      expect((span3.children![1] as TextSpan).recognizer != null, true);
      expect(span3.children![2].toPlainText(), ', looked into ');
      expect(span3.children![3].toPlainText(), 'bing.com');
      expect((span3.children![3] as TextSpan).recognizer != null, true);

      const String text4 =
          'I decided to go to api.flutter.dev/flutter/painting/TextSpan/recognizer.html, and went to bed.';
      final TextSpan span4 = text4.parseLinks([]);
      expect(span4.children!.length, 3);
      expect(span4.children![0].toPlainText(), 'I decided to go to ');
      expect(
        span4.children![1].toPlainText(),
        'api.flutter.dev/flutter/painting/TextSpan/recognizer.html',
      );
      expect((span4.children![1] as TextSpan).recognizer != null, true);
      expect(span4.children![2].toPlainText(), ', and went to bed.');

      const String text5 =
          'I sent an email to lajive9827@fectode.com, and received a letter from the address cat.dog@gmail.com';
      final TextSpan span5 = text5.parseLinks([]);
      expect(span5.children!.length, 4);
      expect(span5.children![0].toPlainText(), 'I sent an email to ');
      expect(span5.children![1].toPlainText(), 'lajive9827@fectode.com');
      expect((span5.children![1] as TextSpan).recognizer != null, true);
      expect(
        span5.children![2].toPlainText(),
        ', and received a letter from the address ',
      );
      expect(span5.children![3].toPlainText(), 'cat.dog@gmail.com');
      expect((span5.children![3] as TextSpan).recognizer != null, true);

      const String text6 =
          'Duplicate google.com links working as expected, google.com';
      final TextSpan span6 = text6.parseLinks([]);
      expect(span6.children!.length, 4);
      expect(span6.children![0].toPlainText(), 'Duplicate ');
      expect(span6.children![1].toPlainText(), 'google.com');
      expect((span6.children![1] as TextSpan).recognizer != null, true);
      expect(
        span6.children![2].toPlainText(),
        ' links working as expected, ',
      );
      expect(span6.children![3].toPlainText(), 'google.com');
      expect((span6.children![3] as TextSpan).recognizer != null, true);
    },
  );
}
