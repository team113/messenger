// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';

/// Elements view of the [Routes.style] page.
class ElementsView extends StatelessWidget {
  const ElementsView({
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this view should be compact, meaning minimal [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return ScrollableColumn(
      children: [
        const Header('Elements'),
        const SubHeader('Avatars'),
        _avatars(context),
        const Divider(),
        const SubHeader('Text fields'),
        _fields(context),
        const Divider(),
        const SubHeader('Buttons'),
        _buttons(context),
        const Divider(),
        const SubHeader('Switchers'),
        _switches(context),
        const Divider(),
        const SubHeader('Containment'),
        _containment(context),
        const Divider(),
        const SubHeader('System messages'),
        _system(context),
        const Divider(),
        const SubHeader('Navigation'),
        _navigation(context),
        const Divider(),
      ],
    );
  }

  /// Builds the animation [Column].
  Widget _avatars(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _fields(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _buttons(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _switches(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _containment(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _system(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  /// Builds the animation [Column].
  Widget _navigation(BuildContext context) {
    // final style = Theme.of(context).style;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }
}
