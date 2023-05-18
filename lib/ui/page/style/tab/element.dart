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

import '../widget/caption.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/call_title.dart';
import '/ui/page/call/widget/round_button.dart';
import '/ui/page/call/widget/tooltip_button.dart';
import '/ui/page/home/page/chat/widget/animated_fab.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/web/web_utils.dart';

/// Elements tab view of the [Routes.style] page.
class ElementStyleTabView extends StatelessWidget {
  const ElementStyleTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget element({
      required String title,
      required Widget child,
      bool background = false,
      String? asset,
    }) {
      final Color backgroundColor = style.colors.secondaryBackgroundLight;

      return Column(
        children: [
          Caption(title),
          _WithDownload(
            enabled: asset != null,
            path: asset ?? '',
            child: Container(
              color: background ? backgroundColor : null,
              padding:
                  background ? const EdgeInsets.fromLTRB(30, 8, 30, 8) : null,
              child: child,
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      controller: ScrollController(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              element(
                title: 'Logo в полный рост.',
                asset: 'assets/images/logo/logo0000.svg',
                child: SvgImage.asset(
                  'assets/images/logo/logo0000.svg',
                  height: 350,
                ),
              ),
              element(
                title: 'Logo голова.',
                asset: 'assets/images/logo/head0000.svg',
                child: SvgImage.asset(
                  'assets/images/logo/head0000.svg',
                  height: 160,
                ),
              ),
              element(
                background: true,
                title: 'Кнопка начать общение.',
                asset: 'assets/icons/start.svg',
                child: OutlinedRoundedButton(
                  title: Text(
                    'Start chatting'.l10n,
                    style: TextStyle(color: style.colors.onPrimary),
                  ),
                  subtitle: Text(
                    'no registration'.l10n,
                    style: TextStyle(color: style.colors.onPrimary),
                  ),
                  leading: SvgImage.asset('assets/icons/start.svg', width: 25),
                  onPressed: () {},
                  gradient: LinearGradient(
                    colors: [
                      style.colors.acceptColor,
                      style.colors.acceptAuxiliaryColor
                    ],
                  ),
                ),
              ),
              element(
                background: true,
                title: 'Кнопка войти.',
                asset: 'assets/icons/sign_in.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Sign in'),
                  subtitle: const Text('or register'),
                  leading:
                      SvgImage.asset('assets/icons/sign_in.svg', width: 20),
                  onPressed: () {},
                ),
              ),
              element(
                background: true,
                title: 'Кнопка загрузки App Store.',
                asset: 'assets/icons/apple.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Download'),
                  subtitle: const Text('App Store'),
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: SvgImage.asset('assets/icons/apple.svg', width: 22),
                  ),
                  onPressed: () {},
                ),
              ),
              element(
                background: true,
                title: 'Кнопка загрузки Google Play.',
                asset: 'assets/icons/google.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Download'),
                  subtitle: const Text('Google Play'),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: SvgImage.asset('assets/icons/google.svg', width: 22),
                  ),
                  onPressed: () {},
                ),
              ),
              element(
                background: true,
                title: 'Кнопка загрузки Linux.',
                asset: 'assets/icons/linux.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Download'),
                  subtitle: const Text('application'),
                  leading: SvgImage.asset('assets/icons/linux.svg', width: 22),
                  onPressed: () {},
                ),
              ),
              element(
                background: true,
                title: 'Кнопка загрузки Windows.',
                asset: 'assets/icons/windows.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Download'),
                  subtitle: const Text('application'),
                  leading:
                      SvgImage.asset('assets/icons/windows.svg', width: 22),
                  onPressed: () {},
                ),
              ),
              element(
                title: 'Аватары.',
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: List.generate(
                    style.colors.userColors.length,
                    (i) => AvatarWidget(title: 'Иван Иванович', color: i),
                  ),
                ),
              ),
              element(
                title: 'Перетягиваемая панель окна звонка.',
                child: Container(
                  color: style.colors.secondaryBackground,
                  height: 45,
                  child: Material(
                    color: style.colors.secondaryBackground,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: context.mediaQuerySize.width / 2),
                            child: InkWell(
                              onTap: () {},
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 10),
                                  const AvatarWidget(radius: 15),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 160),
                                      child: Text(
                                        'Username',
                                        style: context.textTheme.bodyLarge
                                            ?.copyWith(
                                          fontSize: 17,
                                          color: style
                                              .colors.secondaryHighlightDarkest,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: Container(
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 90),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  style.colors.transparent,
                                  style.colors.secondaryBackground,
                                  style.colors.secondaryBackground,
                                  style.colors.secondaryBackground,
                                  style.colors.secondaryBackground,
                                  style.colors.secondaryBackground,
                                  style.colors.secondaryBackground,
                                  style.colors.secondaryBackground,
                                  style.colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '10:04',
                                  style: context.textTheme.bodyLarge?.copyWith(
                                    color:
                                        style.colors.secondaryHighlightDarkest,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TooltipButton(
                                  onTap: () => WebUtils.download(
                                    '/assets/assets/icons/add_user.svg',
                                    'add_user.svg',
                                  ),
                                  hint: 'btn_add_participant'.l10n,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: SvgImage.asset(
                                      'assets/icons/add_user.svg',
                                      width: 19,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                TooltipButton(
                                  onTap: () => WebUtils.download(
                                    '/assets/assets/icons/settings.svg',
                                    'settings.svg',
                                  ),
                                  hint: 'btn_call_settings'.l10n,
                                  child: SvgImage.asset(
                                    'assets/icons/settings.svg',
                                    width: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TooltipButton(
                                  onTap: () => WebUtils.download(
                                    '/assets/assets/icons/fullscreen_enter.svg',
                                    'fullscreen_enter.svg',
                                  ),
                                  hint: 'Fullscreen mode',
                                  child: SvgImage.asset(
                                    'assets/icons/fullscreen_enter.svg',
                                    width: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('(иконки скачиваются по клику по иконкам)'),
              element(
                background: true,
                title: 'Меню ПКМ над видео в звонке.',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: ContextMenu(
                    actions: [
                      ContextMenuButton(
                        label: 'Do not cut video',
                        onPressed: () {},
                      ),
                      ContextMenuButton(
                        label: 'Center video',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              element(
                background: true,
                title: 'Принять звонок с аудио.',
                asset: 'assets/icons/audio_call_start.svg',
                child: RoundFloatingButton(
                  asset: 'audio_call_start',
                  onPressed: () {},
                  text: 'Answer\nwith audio',
                  color: style.colors.acceptColor,
                ),
              ),
              element(
                background: true,
                title: 'Принять звонок с видео.',
                asset: 'assets/icons/video_on.svg',
                child: RoundFloatingButton(
                  asset: 'video_on',
                  onPressed: () {},
                  text: 'Answer\nwith video',
                  color: style.colors.acceptColor,
                ),
              ),
              element(
                background: true,
                title: 'Отклонить звонок.',
                asset: 'assets/icons/call_end.svg',
                child: RoundFloatingButton(
                  asset: 'call_end',
                  onPressed: () {},
                  text: 'Decline',
                  color: style.colors.declineColor,
                ),
              ),
              element(
                background: true,
                title: 'Положить/отменить звонок.',
                asset: 'assets/icons/call_end.svg',
                child: RoundFloatingButton(
                  asset: 'call_end',
                  onPressed: () {},
                  hint: 'End call',
                  color: style.colors.declineColor,
                ),
              ),
              element(
                background: true,
                title: 'Выключить камеру в звонке.',
                asset: 'assets/icons/video_on.svg',
                child: RoundFloatingButton(
                  asset: 'video_on',
                  onPressed: () {},
                  hint: 'Turn video off',
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Включить камеру в звонке.',
                asset: 'assets/icons/video_off.svg',
                child: RoundFloatingButton(
                  asset: 'video_off',
                  onPressed: () {},
                  hint: 'Turn video on',
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Выключить микрофон в звонке.',
                asset: 'assets/icons/microphone_on.svg',
                child: RoundFloatingButton(
                  asset: 'microphone_on',
                  onPressed: () {},
                  hint: 'Mute',
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Включить микрофон в звонке.',
                asset: 'assets/icons/microphone_off.svg',
                child: RoundFloatingButton(
                  asset: 'microphone_off',
                  onPressed: () {},
                  hint: 'Unmute',
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Выключить демонстрацию экрана в звонке.',
                asset: 'assets/icons/screen_share_on.svg',
                child: RoundFloatingButton(
                  asset: 'screen_share_on',
                  onPressed: () {},
                  hint: 'Share screen',
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Включить демонстрацию экрана в звонке.',
                asset: 'assets/icons/screen_share_off.svg',
                child: RoundFloatingButton(
                  asset: 'screen_share_off',
                  onPressed: () {},
                  hint: 'Stop sharing',
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Выключить динамик в звонке.',
                asset: 'assets/icons/speaker_on.svg',
                child: RoundFloatingButton(
                  asset: 'speaker_on',
                  onPressed: () {},
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Включить динамик в звонке.',
                asset: 'assets/icons/speaker_off.svg',
                child: RoundFloatingButton(
                  asset: 'speaker_off',
                  onPressed: () {},
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Переключить камеру на заднюю в звонке.',
                asset: 'assets/icons/camera_front.svg',
                child: RoundFloatingButton(
                  asset: 'camera_front',
                  onPressed: () {},
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Переключить камеру на переднюю в звонке.',
                asset: 'assets/icons/camera_back.svg',
                child: RoundFloatingButton(
                  asset: 'camera_back',
                  onPressed: () {},
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              element(
                background: true,
                title: 'Область Drag-n-drop в боковой панели звонка.',
                asset: 'assets/icons/drag-n-drop.svg',
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgImage.asset('assets/icons/drag_n_drop.svg', width: 44),
                      const SizedBox(height: 5),
                      Text(
                        'Drop any\nvideo here',
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: style.colors.secondaryHighlightDarkest,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              element(
                background: true,
                title: 'Титульная информация звонка.',
                child: CallTitle(
                  const UserId('val'),
                  chat: Chat(
                    const ChatId('val'),
                    name: ChatName('Групповой чат'),
                    kindIndex: 2,
                  ),
                  title: 'Групповой чат',
                  state: 'Звоним',
                  withDots: true,
                ),
              ),
              element(
                background: true,
                title: 'Информация о звонке в панели на мобильном устройстве.',
                asset: 'assets/icons/add_user.svg',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: InkWell(
                    hoverColor: style.colors.transparent,
                    splashColor: style.colors.transparent,
                    highlightColor: style.colors.transparent,
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Expanded(
                          flex: 1,
                          child: Center(
                            child: SizedBox(
                              width: 58,
                              height: 58,
                              child: AvatarWidget(
                                title: 'Иван Иванович',
                                radius: 29,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Иван Иванович',
                                style:
                                    context.textTheme.headlineMedium?.copyWith(
                                  color: style.colors.onPrimary,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '10:04',
                                style:
                                    context.textTheme.headlineMedium?.copyWith(
                                  color: style.colors.onPrimary,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              element(
                background: true,
                title:
                    'Добавить участника в звонок в панели на мобильном устройстве.',
                asset: 'assets/icons/add_user.svg',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: InkWell(
                    hoverColor: style.colors.transparent,
                    splashColor: style.colors.transparent,
                    highlightColor: style.colors.transparent,
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 1,
                          child: RoundFloatingButton(
                            color: style.colors.onSecondaryOpacity50,
                            asset: 'add_user',
                            onPressed: () {},
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Добавить участника',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.headlineMedium?.copyWith(
                              color: style.colors.onPrimary,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              element(
                background: true,
                title: 'Временная метка в чате.',
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: style.colors.onPrimary,
                  ),
                  child: Text(
                    '11:04',
                    style: TextStyle(color: style.colors.secondary),
                  ),
                ),
              ),
              element(
                background: true,
                title: 'Выпадающее меню с кнопками в чате.',
                child: AnimatedFab(
                  labelStyle: const TextStyle(fontSize: 17),
                  closedIcon: Icon(
                    Icons.more_horiz,
                    color: style.colors.primaryHighlight,
                    size: 30,
                  ),
                  openedIcon: Icon(
                    Icons.close,
                    color: style.colors.primaryHighlight,
                    size: 30,
                  ),
                  actions: [
                    AnimatedFabAction(
                      icon: Icon(
                        Icons.call,
                        color: style.colors.primaryHighlight,
                      ),
                      label: 'label_audio_call'.l10n,
                      onTap: () {},
                      noAnimation: true,
                    ),
                    AnimatedFabAction(
                      icon: Icon(
                        Icons.video_call,
                        color: style.colors.primaryHighlight,
                      ),
                      label: 'label_video_call'.l10n,
                      onTap: () {},
                      noAnimation: true,
                    ),
                    AnimatedFabAction(
                      icon: Icon(
                        Icons.person,
                        color: style.colors.primaryHighlight,
                      ),
                      label: 'label_contact'.l10n,
                      onTap: () {},
                    ),
                    AnimatedFabAction(
                      icon: Icon(
                        Icons.attachment,
                        color: style.colors.primaryHighlight,
                      ),
                      label: 'label_file'.l10n,
                      onTap: () {},
                    ),
                    AnimatedFabAction(
                      icon: Icon(
                        Icons.photo,
                        color: style.colors.primaryHighlight,
                      ),
                      label: 'label_photo'.l10n,
                      onTap: () {},
                    ),
                    AnimatedFabAction(
                      icon: Icon(
                        Icons.camera,
                        color: style.colors.primaryHighlight,
                      ),
                      label: 'label_camera'.l10n,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 200),
              const Caption('Не используется'),
              element(
                background: true,
                title: 'Открыть настройки в звонке.',
                asset: 'assets/icons/settings.svg',
                child: RoundFloatingButton(
                  asset: 'settings',
                  onPressed: () {},
                  hint: 'Settings',
                  color: style.colors.secondaryOpacity85,
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adds a download button in a row with its child.
class _WithDownload extends StatelessWidget {
  const _WithDownload({
    Key? key,
    required this.child,
    required this.path,
    this.enabled = true,
  }) : super(key: key);

  /// Child to display download button for.
  final Widget child;

  /// Path of the asset that should be downloaded.
  final String path;

  /// Indicator whether download is enabled or not.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return enabled
        ? Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runAlignment: WrapAlignment.center,
            alignment: WrapAlignment.center,
            runSpacing: 5,
            children: [
              Align(alignment: Alignment.centerLeft, child: child),
              const SizedBox(width: 15),
              FloatingActionButton(
                onPressed: () =>
                    WebUtils.download('/assets/$path', path.split('/').last),
                mini: true,
                child: const Icon(Icons.download),
              ),
            ],
          )
        : child;
  }
}
