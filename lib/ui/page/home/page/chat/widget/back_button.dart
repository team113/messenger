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

import 'package:flutter/material.dart';

import '/ui/widget/svg/svg.dart';

/// Custom styled [BackButton].
class StyledBackButton extends StatelessWidget {
  const StyledBackButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)?.canPop == true) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 7, 0, 8),
        child: InkWell(
          customBorder: const CircleBorder(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SvgLoader.asset(
                'assets/icons/arrow_left.svg',
                height: 16,
              ),
            ),
          ),
          onTap: () => Navigator.maybePop(context),
        ),
      );
    } else {
      return Container();
    }
  }
}
