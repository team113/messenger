import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/vacancy.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/animated_logo.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/page/home/widget/vacancy.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'body/view.dart';
import 'contact/view.dart';
import 'controller.dart';
import 'widget/vacancy_description.dart';

class VacancyView extends StatelessWidget {
  const VacancyView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: VacancyController(Get.find()),
      builder: (VacancyController c) {
        return Stack(
          children: [
            IgnorePointer(
              child: SvgImage.asset(
                'assets/images/background_light.svg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Scaffold(
              body: LayoutBuilder(builder: (context, constraints) {
                if (context.isNarrow) {
                  return Stack(
                    children: [
                      Obx(() {
                        return AnimatedOpacity(
                          duration: 300.milliseconds,
                          opacity: c.vacancy.value == null ? 1 : 0,
                          child: Container(
                            decoration:
                                BoxDecoration(color: style.sidebarColor),
                            child: _list(c, context),
                          ),
                        );
                      }),
                      Obx(() {
                        return IgnorePointer(
                          ignoring: c.vacancy.value == null,
                          child: _vacancy(c, context),
                        );
                      }),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: style.sidebarColor),
                      width: (constraints.maxWidth / 2).clamp(0, 340),
                      child: _list(c, context),
                    ),
                    Expanded(child: _vacancy(c, context)),
                  ],
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _list(VacancyController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Scaffold(
      appBar: CustomAppBar(
        // leading: const [StyledBackButton()],
        leading: [
          AnimatedButton(
            decorator: (child) => Container(
              margin: const EdgeInsets.only(left: 18),
              height: double.infinity,
              child: Center(child: child),
            ),
            onPressed: () => Navigator.maybePop(context),
            child: Icon(
              Icons.home_outlined,
              size: 27,
              color: style.colors.primary,
            ),
          ),
        ],
        title: Text('label_work_with_us'.l10n),
        actions: [
          AnimatedButton(
            decorator: (child) => Container(
              padding: const EdgeInsets.only(right: 18),
              height: double.infinity,
              child: Center(child: child),
            ),
            onPressed: () {},
            child: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
        // actions: const [SizedBox(width: 46)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          ...Vacancies.all.map((e) {
            return Obx(() {
              return VacancyWidget(
                e.title,
                subtitle: [
                  if (e.subtitle != null) ...[
                    Text(e.subtitle!),
                  ],
                ],
                selected: c.vacancy.value == e,
                onPressed: () {
                  router.vacancy(e.id);
                  // c.vacancy.value = e;
                },
              );
            });
          }),
        ],
      ),
    );
  }

  Widget _vacancy(VacancyController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Widget child;

      if (c.vacancy.value != null) {
        final e = c.vacancy.value!;

        child = Scaffold(
          key: Key(e.id),
          appBar: CustomAppBar(
            leading: [
              StyledBackButton(onPressed: () => c.vacancy.value = null),
            ],
            title: Text(e.title),
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
                    : SvgImage.asset('assets/icons/copy.svg', height: 18),
              ),
            ],
          ),
          body: VacancyBodyView(e),
        );
      } else {
        if (context.isNarrow) {
          child = const SizedBox();
        } else {
          child = Scaffold(
            body: Center(child: Text('label_work_with_us'.l10n)),
          );
        }
      }

      return AnimatedSwitcher(
        duration: 300.milliseconds,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: CurvedAnimation(
              curve: Curves.ease,
              parent: animation,
            ).drive(Tween(begin: const Offset(1, 0), end: const Offset(0, 0))),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: child,
      );
    });
  }
}
