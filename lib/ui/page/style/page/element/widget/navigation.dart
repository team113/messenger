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

import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/widget/svg/svg.dart';
import '/themes.dart';

/// View of all navigation elements in the app.
class NavigationWidget extends StatelessWidget {
  const NavigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.colors.onPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 61,
              width: 335,
              child: CustomNavigationBar(
                currentIndex: 1,
                onTap: (p0) {},
                items: const [
                  CustomNavigationBarItem(
                    child: SvgImage.asset(
                      'assets/icons/contacts.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),
                  CustomNavigationBarItem(
                    child: SvgImage.asset(
                      'assets/icons/chats.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),
                  CustomNavigationBarItem(
                    child: AvatarWidget(
                      radius: 16,
                      title: 'John Doe',
                      color: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 65,
              child: Scaffold(
                appBar: CustomAppBar(
                  title: Row(
                    children: [
                      Material(
                        elevation: 6,
                        type: MaterialType.circle,
                        shadowColor: style.colors.onBackgroundOpacity27,
                        color: style.colors.onPrimary,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {},
                          child: const Center(
                            child: AvatarWidget(title: 'Front End', radius: 17),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: InkWell(
                          splashFactory: NoSplash.splashFactory,
                          hoverColor: style.colors.transparent,
                          highlightColor: style.colors.transparent,
                          onTap: () {},
                          child: DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Фронтенд',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text('6 участников',
                                    style: style.fonts.bodySmallSecondary),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                  padding: const EdgeInsets.only(left: 4, right: 20),
                  leading: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: style.colors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                  actions: const [],
                ),
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                height: 65,
                child: SizedBox(
                  width: 335,
                  child: Scaffold(
                      appBar: CustomAppBar(
                    border: Border.all(color: style.colors.primary, width: 2),
                    title: const Text('Поиск'),
                    leading: [
                      const SizedBox(
                        width: 16,
                      ),
                      Icon(
                        key: const Key('ArrowBack'),
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: style.colors.primary,
                      )
                    ],
                    actions: const [
                      SizedBox(width: 30),
                    ],
                  )),
                ),
              )),
          Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                height: 65,
                child: SizedBox(
                  width: 335,
                  child: Scaffold(
                      appBar: CustomAppBar(
                    title: const Text('Чаты'),
                    leading: const [
                      SizedBox(width: 16),
                      SvgImage.asset(
                        'assets/icons/search.svg',
                        width: 17.77,
                      ),
                    ],
                    actions: [
                      Icon(
                        Icons.more_vert,
                        color: style.colors.primary,
                      ),
                      const SizedBox(width: 16),
                    ],
                  )),
                ),
              )),
        ],
      ),
    );
  }
}
