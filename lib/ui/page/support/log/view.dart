// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:log_me/log_me.dart' as me;

import '/config.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/domain/service/session.dart';
import '/l10n/l10n.dart';
import '/provider/file/log.dart';
import '/pubspec.g.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/safe_area/safe_area.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/get.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the technical information and [Log]s.
class LogView extends StatelessWidget {
  const LogView({super.key});

  /// Displays a [LogView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) async {
    final route = DialogRoute<T>(
      context: context,
      builder: (_) => LogView(),
      settings: RouteSettings(name: 'LogView'),
      barrierColor:
          DialogTheme.of(context).barrierColor ??
          Theme.of(context).dialogTheme.barrierColor ??
          Colors.black54,
    );

    router.obscuring.add(route);

    try {
      return await Navigator.of(context, rootNavigator: true).push<T>(route);
    } finally {
      router.obscuring.remove(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: LogController(
        Get.find(),
        Get.findOrNull<MyUserService>(),
        Get.findOrNull<SessionService>(),
        Get.findOrNull<NotificationService>(),
        Get.findOrNull<LogFileProvider>(),
      ),
      builder: (LogController c) {
        return Scaffold(
          backgroundColor: style.colors.background,
          body: SelectionArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalPopupHeader(
                  text: 'Version: ${Pubspec.ref}',
                  onBack: context.isMobile ? Navigator.of(context).pop : null,
                ),
                Flexible(
                  child: Scrollbar(
                    controller: c.scrollController,
                    child: Obx(() {
                      return ListView(
                        controller: c.scrollController,
                        padding: EdgeInsets.all(8),
                        shrinkWrap: true,
                        children: [
                          SelectionContainer.disabled(
                            child: Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    onPressed: () async {
                                      try {
                                        await PlatformUtils.copy(
                                          text: LogController.report(
                                            sessions: c.sessions,
                                            sessionId: c.sessionId,
                                            userAgent: c.userAgent.value,
                                            myUser: c.myUser?.value,
                                            token: c.token,
                                            pushNotifications:
                                                c.pushNotifications,
                                          ),
                                        );

                                        MessagePopup.success(
                                          'label_copied'.l10n,
                                        );
                                      } catch (e) {
                                        MessagePopup.error(e);
                                      }
                                    },
                                    title: 'Copy as text',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: PrimaryButton(
                                    onPressed: () async {
                                      await LogController.download(
                                        sessions: c.sessions,
                                        sessionId: c.sessionId,
                                        userAgent: c.userAgent.value,
                                        myUser: c.myUser?.value,
                                        token: c.token,
                                        pushNotifications: c.pushNotifications,
                                      );
                                    },
                                    title: 'Download as file',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (Config.logWrite)
                            Obx(() {
                              final stat = c.stat.value;

                              if (stat == null) {
                                return const SizedBox();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SelectionContainer.disabled(
                                  child: PrimaryButton(
                                    onPressed: () async =>
                                        await c.downloadArchive(),
                                    title:
                                        'Download whole ${stat.size ~/ 1024} KB dump',
                                  ),
                                ),
                              );
                            }),

                          _application(context, c),
                          _myUser(context, c),
                          _session(context, c),
                          _token(context, c),

                          // Logs.
                          ListTile(
                            leading: WidgetButton(
                              onPressed: () {},
                              onPressedWithDetails: (u) {
                                PlatformUtils.copy(
                                  text: Log.logs
                                      .map((e) => '[${e.at.toStamp}] ${e.text}')
                                      .join('\n'),
                                );

                                MessagePopup.success(
                                  'label_copied'.l10n,
                                  at: u.globalPosition,
                                );
                              },
                              child: SvgIcon(SvgIcons.copy),
                            ),
                            trailing: WidgetButton(
                              onPressed: c.clearLogs,
                              child: SvgIcon(SvgIcons.delete19),
                            ),
                            title: Text('Logs'),
                          ),
                          ...Log.logs.map((e) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.at.toUtc().toStamp,
                                  style: style.fonts.small.regular.onBackground,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    e.text,
                                    style: switch (e.level) {
                                      me.LogLevel.fatal =>
                                        style.fonts.small.regular.danger,

                                      me.LogLevel.error =>
                                        style.fonts.small.regular.danger,

                                      me.LogLevel.warning =>
                                        style.fonts.small.regular.onBackground
                                            .copyWith(
                                              color: style.colors.warning,
                                            ),

                                      me.LogLevel.info =>
                                        style.fonts.small.regular.onBackground
                                            .copyWith(
                                              color:
                                                  style.colors.acceptAuxiliary,
                                            ),

                                      me.LogLevel.debug =>
                                        style.fonts.small.regular.onBackground,

                                      me.LogLevel.trace =>
                                        style
                                            .fonts
                                            .small
                                            .regular
                                            .secondaryHighlightDarkest,

                                      me.LogLevel.off || me.LogLevel.all =>
                                        style
                                            .fonts
                                            .small
                                            .regular
                                            .secondaryHighlightDarkest,
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the technical information version of application.
  Widget _application(BuildContext context, LogController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: WidgetButton(
            onPressed: () {},
            onPressedWithDetails: (u) {
              PlatformUtils.copy(text: Pubspec.ref);
              MessagePopup.success('label_copied'.l10n, at: u.globalPosition);
            },
            child: SvgIcon(SvgIcons.copy),
          ),
          title: Text('Application'),
        ),
        Text('Ref: ${Pubspec.ref}'),
        Text('User-Agent: ${c.userAgent.value}'),
        Text('Is PWA: ${CustomSafeArea.isPwa}'),
      ],
    );
  }

  /// Builds the technical information about [MyUser].
  Widget _myUser(BuildContext context, LogController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: WidgetButton(
            onPressed: () {},
            onPressedWithDetails: (u) {
              PlatformUtils.copy(text: '${c.myUser?.value?.toJson()}');
              MessagePopup.success('label_copied'.l10n, at: u.globalPosition);
            },
            child: SvgIcon(SvgIcons.copy),
          ),
          title: Text('MyUser'),
        ),
        Text('${c.myUser?.value?.toJson()}'),
      ],
    );
  }

  /// Builds the technical information about current [Session].
  Widget _session(BuildContext context, LogController c) {
    final style = Theme.of(context).style;

    final session = c.sessions
        ?.firstWhereOrNull((e) => e.session.value.id == c.sessionId)
        ?.session
        .value
        .toJson();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: WidgetButton(
            onPressed: () {},
            onPressedWithDetails: (u) {
              PlatformUtils.copy(text: '$session');
              MessagePopup.success('label_copied'.l10n, at: u.globalPosition);
            },
            child: SvgIcon(SvgIcons.copy),
          ),
          title: Text('Session'),
        ),
        Text('ID: ${c.sessionId}'),
        Text('$session'),
        ListTile(
          title: Text(
            'Force `refreshSession()` to occur',
            style: style.fonts.small.regular.primary,
          ),
          onTap: c.refreshSession,
        ),
      ],
    );
  }

  /// Builds the technical information about a [DeviceToken] used.
  Widget _token(BuildContext context, LogController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: WidgetButton(
            onPressed: () {},
            onPressedWithDetails: (u) {
              PlatformUtils.copy(text: '${c.token}');
              MessagePopup.success('label_copied'.l10n, at: u.globalPosition);
            },
            child: SvgIcon(SvgIcons.copy),
          ),
          title: Text('Token'),
        ),
        Text('${c.token}'),
        Text(
          'Push Notifications are considered active: ${c.pushNotifications}',
        ),
        Text(
          'Push Notifications permissions are: ${c.notificationSettings.value?.authorizationStatus.name}',
        ),
      ],
    );
  }
}
