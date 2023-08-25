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
import 'package:get/get.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/vacancy.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/page/vacancy/body/view.dart';
import 'package:messenger/ui/page/vacancy/widget/vacancy_description.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:share_plus/share_plus.dart';

import 'controller.dart';

class VacancyView extends StatelessWidget {
  const VacancyView(this.id, {super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      tag: id,
      init: VacancyController(id),
      builder: (VacancyController c) {
        if (c.vacancy.value == null) {
          return const Scaffold(
            appBar: CustomAppBar(leading: [StyledBackButton()]),
            body: Center(child: CustomProgressIndicator()),
          );
        }

        final Vacancy e = c.vacancy.value!;

        return Scaffold(
          appBar: CustomAppBar(
            title: Text(e.title),
            leading: const [StyledBackButton()],
            actions: [
              AnimatedButton(
                decorator: (child) => Container(
                  padding: const EdgeInsets.only(left: 12, right: 18),
                  height: double.infinity,
                  child: child,
                ),
                onPressed: () async {
                  if (PlatformUtils.isMobile) {
                    await Share.share('${Config.origin}${router.route}');
                  } else {
                    PlatformUtils.copy(
                      text: '${Config.origin}${router.route}',
                    );
                    MessagePopup.success('label_copied'.l10n);
                  }
                },
                child: PlatformUtils.isMobile
                    ? Icon(
                        Icons.ios_share_rounded,
                        color: style.colors.primary,
                        size: 24,
                      )
                    : SvgImage.asset(
                        'assets/icons/copy_thick.svg',
                        width: 16.18,
                        height: 18.8,
                      ),
              ),
            ],
          ),
          body: VacancyBodyView(e, detailed: false),
        );
      },
    );
  }
}
