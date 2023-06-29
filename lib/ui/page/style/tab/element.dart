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
import 'package:messenger/themes.dart';

import '../../../widget/svg/svg.dart';
import '../../home/widget/avatar.dart';
import '../widget/animated_circle_avatar.dart';

// import '/themes.dart';

/// Elements tab view of the [Routes.style] page.
class ElementStyleTabView extends StatelessWidget {
  const ElementStyleTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // final (style, fonts) = Theme.of(context).styles;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70),
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 20),
                  const _Header(label: 'Элементы интерфейса'),
                  const SizedBox(height: 100),
                  const _Header(label: 'Изображения'),
                  const _SmallHeader(label: 'Аватар'),
                  const _Avatar(),
                  const Divider(),
                  const _SmallHeader(label: 'Логотип'),
                  const _Logo(),
                  const SizedBox(height: 15),
                  const Divider(),
                  const _SmallHeader(label: 'Иконки'),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label, this.height});

  final String label;

  final double? height;

  @override
  Widget build(BuildContext context) {
    final (_, fonts) = Theme.of(context).styles;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: fonts.displayLarge!.copyWith(color: const Color(0xFF1F3C5D)),
        ),
      ],
    );
  }
}

class _SmallHeader extends StatelessWidget {
  const _SmallHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final (_, fonts) = Theme.of(context).styles;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 70),
        Text(
          label,
          style: fonts.headlineLarge!.copyWith(color: const Color(0xFF1F3C5D)),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final (style, _) = Theme.of(context).styles;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          children: [
            Tooltip(
              message: 'Аватары Пользователей',
              child: SizedBox(
                height: 120,
                width: 250,
                child: GridView.count(
                  crossAxisCount: style.colors.userColors.length ~/ 2,
                  children: List.generate(
                    style.colors.userColors.length,
                    (i) => AvatarWidget(
                      title: 'Сергей Александрович',
                      color: i,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 150),
        const Column(
          children: [
            Tooltip(
              message: 'Изменение аватара',
              child: Padding(
                padding: EdgeInsets.only(bottom: 25),
                child: AnimatedCircleAvatar(
                  avatar: AvatarWidget(
                    radius: 50,
                    title: 'Сергей Александрович',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Tooltip(
          message: 'Logo в полный рост',
          child: SvgImage.asset(
            'assets/images/logo/logo0000.svg',
            height: 300,
            width: 300,
          ),
        ),
        const SizedBox(width: 100),
        Tooltip(
          message: 'Logo голова',
          child: SvgImage.asset(
            'assets/images/logo/head0000.svg',
            height: 150,
            width: 150,
          ),
        ),
      ],
    );
  }
}
