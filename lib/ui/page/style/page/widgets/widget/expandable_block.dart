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

import '/ui/page/home/widget/block.dart';

class ExpandableBlock extends StatefulWidget {
  const ExpandableBlock({
    super.key,
    this.headline,
    this.take = 11,
    this.padding = const EdgeInsets.fromLTRB(32, 16, 32, 16),
    this.color,
    this.children = const [],
  });

  final Color? color;
  final EdgeInsets padding;
  final String? headline;
  final List<Widget> children;
  final int take;

  @override
  State<ExpandableBlock> createState() => _ExpandableBlockState();
}

class _ExpandableBlockState extends State<ExpandableBlock> {
  final bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Block(
          color: widget.color,
          headline: widget.headline,
          padding: widget.padding,
          fade: !_expanded,
          expanded: [
            ..._expanded ? widget.children.skip(widget.take) : [],
            const SizedBox(height: 32)
          ],
          children: [
            const SizedBox(height: 32),
            ...widget.children.take(widget.take),
          ],
        ),
      ],
    );
  }
}
