// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '/domain/model/contact.dart';
import '/l10n/l10n.dart';
import 'controller.dart';

// TODO: Implement [Routes.contact] page.
/// View of the [Routes.contact] page.
class ContactView extends StatelessWidget {
  const ContactView(this.id, {Key? key}) : super(key: key);

  /// ID of a [ChatContact] this [ContactView] represents.
  final ChatContactId id;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ContactController>(
      init: ContactController(id),
      tag: id.val,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text('Contact $id'),
          elevation: 0,
        ),
        body: Center(child: Text('Contact with tag: $id'.l10n)),
      ),
    );
  }
}
