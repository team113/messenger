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
import 'package:get/get.dart';

import '../widget/caption.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/page/auth/widget/outlined_rounded_button.dart';
import '/ui/page/call/widget/call_title.dart';
import '/ui/page/call/widget/round_button.dart';
import '/ui/page/call/widget/tooltip_button.dart';
import '/ui/page/home/page/chat/widget/animated_fab.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/svg/svg.dart';
import '/util/web/web_utils.dart';

/// Elements tab view of the [Routes.style] page.
class ElementStyleTabView extends StatelessWidget {
  const ElementStyleTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget _element({
      required String title,
      required Widget child,
      bool background = false,
      Color backgroundColor = const Color(0xFF444444),
      String? asset,
    }) =>
        Column(
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

    return SingleChildScrollView(
      controller: ScrollController(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _element(
                title: 'Logo в полный рост.',
                asset: 'assets/images/logo/logo0000.svg',
                child: SvgLoader.asset('assets/images/logo/logo0000.svg',
                    height: 350),
              ),
              _element(
                title: 'Logo голова.',
                asset: 'assets/images/logo/head0000.svg',
                child: SvgLoader.asset('assets/images/logo/head0000.svg',
                    height: 160),
              ),
              _element(
                background: true,
                title: 'Кнопка начать общение.',
                asset: 'assets/icons/start.svg',
                child: OutlinedRoundedButton(
                  title: Text(
                    'Start chatting'.l10n,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'no registration'.l10n,
                    style: const TextStyle(color: Colors.white),
                  ),
                  leading: SvgLoader.asset('assets/icons/start.svg', width: 25),
                  onPressed: () {},
                  gradient: const LinearGradient(
                    colors: [Color(0xFF03A803), Color(0xFF20CD66)],
                  ),
                ),
              ),
              _element(
                background: true,
                title: 'Кнопка войти.',
                asset: 'assets/icons/sign_in.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Sign in'),
                  subtitle: const Text('or register'),
                  leading:
                      SvgLoader.asset('assets/icons/sign_in.svg', width: 20),
                  onPressed: () {},
                ),
              ),
              _element(
                background: true,
                title: 'Кнопка загрузки App Store.',
                asset: 'assets/icons/apple.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Download'),
                  subtitle: const Text('App Store'),
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: SvgLoader.asset('assets/icons/apple.svg', width: 22),
                  ),
                  onPressed: () {},
                ),
              ),
              _element(
                background: true,
                title: 'Кнопка загрузки Google Play.',
                asset: 'assets/icons/google.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Download'),
                  subtitle: const Text('Google Play'),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child:
                        SvgLoader.asset('assets/icons/google.svg', width: 22),
                  ),
                  onPressed: () {},
                ),
              ),
              _element(
                background: true,
                title: 'Кнопка загрузки Linux.',
                asset: 'assets/icons/linux.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Download'),
                  subtitle: const Text('application'),
                  leading: SvgLoader.asset('assets/icons/linux.svg', width: 22),
                  onPressed: () {},
                ),
              ),
              _element(
                background: true,
                title: 'Кнопка загрузки Windows.',
                asset: 'assets/icons/windows.svg',
                child: OutlinedRoundedButton(
                  title: const Text('Download'),
                  subtitle: const Text('application'),
                  leading:
                      SvgLoader.asset('assets/icons/windows.svg', width: 22),
                  onPressed: () {},
                ),
              ),
              _element(
                title: 'Аватары.',
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: List.generate(
                    AvatarWidget.colors.length,
                    (i) => AvatarWidget(title: 'Иван Иванович', color: i),
                  ),
                ),
              ),
              _element(
                title: 'Перетягиваемая панель окна звонка.',
                child: Container(
                  color: const Color(0xFF222222),
                  height: 45,
                  child: Material(
                    color: const Color(0xFF222222),
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
                                        style: context.textTheme.bodyText1
                                            ?.copyWith(
                                          fontSize: 17,
                                          color: const Color(0xFFBBBBBB),
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
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x00222222),
                                  Color(0xFF222222),
                                  Color(0xFF222222),
                                  Color(0xFF222222),
                                  Color(0xFF222222),
                                  Color(0xFF222222),
                                  Color(0xFF222222),
                                  Color(0xFF222222),
                                  Color(0x00222222),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '10:04',
                                  style: context.textTheme.bodyText1?.copyWith(
                                      color: const Color(0xFFBBBBBB)),
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
                                  hint: 'btn_add_participant'
                                      .l10nfmt({'twoLines': 'false'}),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: SvgLoader.asset(
                                      'assets/icons/add_user.svg',
                                      color: const Color(0xFFBBBBBB),
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
                                  child: SvgLoader.asset(
                                    'assets/icons/settings.svg',
                                    color: const Color(0xFFBBBBBB),
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
                                  child: SvgLoader.asset(
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
              _element(
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
              _element(
                background: true,
                title: 'Принять звонок с аудио.',
                asset: 'assets/icons/audio_call_start.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  text: 'Answer\nwith audio',
                  color: const Color(0xDD34B139),
                  children: [
                    SvgLoader.asset('assets/icons/audio_call_start.svg',
                        width: 29)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Принять звонок с видео.',
                asset: 'assets/icons/video_on.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  text: 'Answer\nwith video',
                  color: const Color(0xDD34B139),
                  children: [
                    SvgLoader.asset('assets/icons/video_on.svg', width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Отклонить звонок.',
                asset: 'assets/icons/call_end.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  text: 'Decline',
                  color: const Color(0xDDFF0000),
                  children: [
                    SvgLoader.asset('assets/icons/call_end.svg', width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Положить/отменить звонок.',
                asset: 'assets/icons/call_end.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  hint: 'End call',
                  color: const Color(0xDDFF0000),
                  children: [
                    SvgLoader.asset('assets/icons/call_end.svg', width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Выключить камеру в звонке.',
                asset: 'assets/icons/video_on.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  hint: 'Turn video off',
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/video_on.svg', width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Включить камеру в звонке.',
                asset: 'assets/icons/video_off.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  hint: 'Turn video on',
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/video_off.svg', width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Выключить микрофон в звонке.',
                asset: 'assets/icons/microphone_on.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  hint: 'Mute',
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/microphone_on.svg', width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Включить микрофон в звонке.',
                asset: 'assets/icons/microphone_off.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  hint: 'Unmute',
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/microphone_off.svg',
                        width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Выключить демонстрацию экрана в звонке.',
                asset: 'assets/icons/screen_share_on.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  hint: 'Share screen',
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/screen_share_on.svg',
                        width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Включить демонстрацию экрана в звонке.',
                asset: 'assets/icons/screen_share_off.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  hint: 'Stop sharing',
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/screen_share_off.svg',
                        width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Выключить динамик в звонке.',
                asset: 'assets/icons/speaker_on.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/speaker_on.svg', width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Включить динамик в звонке.',
                asset: 'assets/icons/speaker_off.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/speaker_off.svg', width: 60)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Переключить камеру на заднюю в звонке.',
                asset: 'assets/icons/camera_front.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/camera_front.svg', width: 28)
                  ],
                ),
              ),
              _element(
                background: true,
                title: 'Переключить камеру на переднюю в звонке.',
                asset: 'assets/icons/camera_back.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/camera_back.svg', width: 28)
                  ],
                ),
              ),
              _element(
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
                      SvgLoader.asset('assets/icons/drag_n_drop.svg',
                          width: 44),
                      const SizedBox(height: 5),
                      Text(
                        'Drop any\nvideo here',
                        style: context.textTheme.bodyText1?.copyWith(
                          color: const Color(0xFFBBBBBB),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              _element(
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
              _element(
                background: true,
                title: 'Информация о звонке в панели на мобильном устройстве.',
                asset: 'assets/icons/add_user.svg',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
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
                                style: context.textTheme.headline4?.copyWith(
                                    color: Colors.white, fontSize: 20),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '10:04',
                                style: context.textTheme.headline4?.copyWith(
                                    color: Colors.white, fontSize: 15),
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
              _element(
                background: true,
                title:
                    'Добавить участника в звонок в панели на мобильном устройстве.',
                asset: 'assets/icons/add_user.svg',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 1,
                          child: RoundFloatingButton(
                            onPressed: () {},
                            scale: 0.75,
                            children: [
                              SvgLoader.asset(
                                'assets/icons/add_user.svg',
                                width: 22,
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Добавить участника',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.headline4
                                ?.copyWith(color: Colors.white, fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _element(
                title: 'Кнопка назад в чате.',
                asset: 'assets/icons/arrow_left.svg',
                child: SizedBox(
                  width: 40,
                  height: 40,
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
                ),
              ),
              _element(
                background: true,
                title: 'Временная метка в чате.',
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                  ),
                  child: const Text(
                    '11:04',
                    style: TextStyle(color: Color(0xFF888888)),
                  ),
                ),
              ),
              _element(
                background: true,
                title: 'Выпадающее меню с кнопками в чате.',
                child: AnimatedFab(
                  labelStyle: const TextStyle(fontSize: 17),
                  closedIcon: const Icon(
                    Icons.more_horiz,
                    color: Colors.blue,
                    size: 30,
                  ),
                  openedIcon: const Icon(
                    Icons.close,
                    color: Colors.blue,
                    size: 30,
                  ),
                  actions: [
                    AnimatedFabAction(
                      icon: const Icon(Icons.call, color: Colors.blue),
                      label: 'label_audio_call'.l10n,
                      onTap: () {},
                      noAnimation: true,
                    ),
                    AnimatedFabAction(
                      icon: const Icon(Icons.video_call, color: Colors.blue),
                      label: 'label_video_call'.l10n,
                      onTap: () {},
                      noAnimation: true,
                    ),
                    AnimatedFabAction(
                      icon: const Icon(Icons.person, color: Colors.blue),
                      label: 'label_contact'.l10n,
                      onTap: () {},
                    ),
                    AnimatedFabAction(
                      icon: const Icon(Icons.attachment, color: Colors.blue),
                      label: 'label_file'.l10n,
                      onTap: () {},
                    ),
                    AnimatedFabAction(
                      icon: const Icon(Icons.photo, color: Colors.blue),
                      label: 'label_photo'.l10n,
                      onTap: () {},
                    ),
                    AnimatedFabAction(
                      icon: const Icon(Icons.camera, color: Colors.blue),
                      label: 'label_camera'.l10n,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 200),
              const Caption('Не используется'),
              _element(
                background: true,
                title: 'Открыть настройки в звонке.',
                asset: 'assets/icons/settings.svg',
                child: RoundFloatingButton(
                  onPressed: () {},
                  hint: 'Settings',
                  color: const Color(0xDD818181),
                  children: [
                    SvgLoader.asset('assets/icons/settings.svg', width: 32)
                  ],
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
