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

import 'package:flutter/material.dart';

import '../widget/headline.dart';
import '../widget/playable_asset.dart';
import '/routes.dart';
import '/ui/page/style/widget/builder_wrap.dart';

/// [Routes.style] sounds section.
class SoundsSection {
  /// Returns the [Widget]s of this [SoundsSection].
  static List<Widget> build() {
    final List<({String title, bool once})> sounds = [
      (title: 'incoming_call', once: false),
      (title: 'incoming_call_web', once: false),
      (title: 'outgoing_call', once: false),
      (title: 'reconnect', once: false),
      (title: 'message_sent', once: true),
      (title: 'notification', once: true),
      (title: 'pop', once: true),
    ];

    return [
      Headline(
        headline: 'Sounds',
        child: BuilderWrap(
          sounds,
          (e) => PlayableAsset(e.title, once: e.once),
          dense: true,
        ),
      ),
    ];
  }
}
