import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../controller.dart';
import '../widget/call_cover.dart';
import '../widget/participant.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/fit_view.dart';
import '../widget/hint.dart';
import '../widget/minimizable_view.dart';
import '../widget/round_button.dart';
import '../widget/video_view.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'common.dart';

/// Returns a mobile design of a [CallView].
Widget mobileCall(CallController c, BuildContext context) {
  return Obx(
    () {
      c.padding = MediaQuery.of(context).padding;

      bool isOutgoing =
          (c.outgoing || c.state.value == OngoingCallState.local) && !c.started;

      // Participants to display.
      List<Participant> videos = [
        ...c.locals,
        ...c.focused,
        ...c.paneled,
        ...c.remotes,
      ];

      if (!c.isGroup) {
        videos.removeWhere((e) => e.video.value == null);
      }

      // Keep only the remote participants if the call is minimized.
      if (c.minimized.value) {
        var remotes = videos.where((e) => e.owner == MediaOwnerKind.remote);
        if (remotes.isNotEmpty) {
          videos = remotes.toList();
        }
      }

      // Self minimized renderer.
      Participant? self;

      // Populate the self renderer if we aren't in a group call.
      if (!c.isGroup) {
        self = videos
            .where((e) =>
                e.owner == MediaOwnerKind.local &&
                e.source == MediaSourceKind.Device)
            .firstOrNull;

        if (self != null) {
          videos.removeWhere((e) =>
              e.owner == MediaOwnerKind.local &&
              e.source == MediaSourceKind.Device);
        }
      }

      bool showUi = (c.showUi.isTrue ||
              c.state.value != OngoingCallState.active ||
              (c.state.value == OngoingCallState.active && videos.isEmpty)) &&
          !c.minimized.value;

      // Call stackable content.
      List<Widget> content = [];

      // Layer of [MouseRegion]s to determine the hovered renderer.
      List<Widget> overlay = [];

      // Active call.
      if (c.state.value == OngoingCallState.active) {
        content = [
          _mobileView(
            c,
            videos
                .map((e) => _mobileVideo(c, participant: e, videos: videos))
                .toList(),
          )
        ];

        // Self renderer positioned video.
        content.add(
          Obx(
            () => AnimatedPositioned(
              duration: c.isSelfPanning.value
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: c.isSlidingPanelEnabled.value
                  ? Curves.easeOutQuad
                  : Curves.easeInQuad,
              right:
                  c.minimized.value && videos.isEmpty ? 0 : c.selfRight.value,
              bottom: c.minimized.value && videos.isEmpty
                  ? 0
                  : c.selfBottom.value + c.padding.bottom,
              width: 150,
              height: 150,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: self == null
                    ? Container(key: const Key('Empty'))
                    : GestureDetector(
                        onPanStart: (d) => c.isSelfPanning.value = true,
                        onPanDown: (d) => c.isSelfPanning.value = true,
                        onPanEnd: (d) => c.isSelfPanning.value = false,
                        onPanCancel: () => c.isSelfPanning.value = false,
                        onPanUpdate: (d) {
                          c.selfRight.value = c.selfRight.value - d.delta.dx;
                          c.selfBottom.value = c.selfBottom.value - d.delta.dy;
                          c.applySelfConstraints(context);
                        },
                        onLongPress: () => c.highlight(self),
                        child: Material(
                          type: MaterialType.card,
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          elevation: 10,
                          child: ParticipantWidget(
                            self,
                            key: c.selfKey,
                            fit: BoxFit.cover,
                            muted: !c.audioState.value.isEnabled(),
                            animate: false,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );

        // Place the highlighted renderer above the others.
        if (c.highlighted.value != null) {
          content.add(Container(color: const Color(0xCC000000)));
          content.add(
            _mobileVideo(
              c,
              participant: c.highlighted.value!,
              videos: videos,
            ),
          );
        }
      } else {
        // Call is not active.
        RtcVideoRenderer? local = c.locals.firstOrNull?.video.value ??
            c.paneled.firstOrNull?.video.value;
        var callCover = c.chat.value?.callCover;

        content =
            c.videoState.value == LocalTrackState.disabled || local == null
                ? [CallCoverWidget(callCover)]
                : [RtcVideoView(local, mirror: true, fit: BoxFit.cover)];
      }

      // If there's any error to show, display it.
      if (c.errorTimeout.value != 0) {
        overlay.add(
          Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: 240,
              height: 110,
              child: HintWidget(
                text: '${c.error}.',
                onTap: () => c.errorTimeout.value = 0,
              ),
            ),
          ),
        );
      }

      Widget _padding(Widget child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: child,
          );

      Widget _buttons(List<Widget> children) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.map((e) => Expanded(child: e)).toList(),
            ),
          );

      c.isSlidingPanelEnabled.value =
          (c.state.value == OngoingCallState.active ||
                  c.state.value == OngoingCallState.joining) &&
              showUi;

      double panelHeight = 500;
      List<Widget> panelChildren = [];

      // Populate the sliding panel height and its content.
      if (c.state.value == OngoingCallState.active ||
          c.state.value == OngoingCallState.joining) {
        panelHeight = 300;
        if (c.chat.value?.chat.value.isGroup == true) {
          panelHeight += (44 + 8) * c.chat.value!.chat.value.members.length;
        }
        panelHeight = min(c.size.height - 45, panelHeight);

        panelChildren = [
          const SizedBox(height: 12),
          _buttons(
            [
              if (PlatformUtils.isMobile)
                _padding(
                  c.videoState.value.isEnabled()
                      ? switchButton(c)
                      : speakerButton(c),
                ),
              if (PlatformUtils.isDesktop) _padding(screenButton(c)),
              _padding(audioButton(c)),
              _padding(videoButton(c)),
              _padding(dropButton(c)),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0x99FFFFFF), thickness: 1, height: 1),
          const SizedBox(height: 13),
          _callTile(context, c),
          const SizedBox(height: 13),
          const Divider(color: Color(0x99FFFFFF), thickness: 1, height: 1),
          if (c.chat.value?.chat.value.isGroup != true) ...[
            const SizedBox(height: 13),
            _textButton(
              context,
              onTap: () => c.openAddMember(context),
              asset: SvgLoader.asset('assets/icons/add_user.svg', width: 22),
              label: 'btn_add_participant'.tr,
            ),
            const SizedBox(height: 13),
          ],
          if (c.chat.value?.chat.value.isGroup == true) ...[
            const SizedBox(height: 5),
            ...c.chat.value!.chat.value.members
                .map(
                  (e) => FutureBuilder<RxUser?>(
                    future: c.getUser(e.user.id),
                    builder: (context, snapshot) {
                      if (snapshot.data == null) {
                        return _userButton(c, context, e.user);
                      } else {
                        return Obx(() =>
                            _userButton(c, context, snapshot.data!.user.value));
                      }
                    },
                  ),
                )
                .toList(),
            const SizedBox(height: 8),
            _textButton(
              context,
              onTap: () => c.openAddMember(context),
              asset: SvgLoader.asset('assets/icons/add_user.svg', width: 22),
              label: 'btn_add_participant'.tr,
            ),
            const SizedBox(height: 13),
          ],
        ];
      }

      List<Widget> ui = [
        // Dimmed container.
        IgnorePointer(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: (c.state.value != OngoingCallState.active &&
                    c.state.value != OngoingCallState.joining &&
                    (videos.firstWhereOrNull((e) => e.video.value != null) !=
                            null ||
                        self != null) &&
                    !c.minimized.value)
                ? Container(color: const Color(0x55000000))
                : null,
          ),
        ),
        // Listen to the taps only if the call is not minimized.
        c.minimized.value
            ? Container()
            : Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (d) {
                  if (c.highlighted.value == null) {
                    c.downPosition = d.localPosition;
                    c.downButtons = d.buttons;
                  } else {
                    c.downButtons = 0;
                    c.highlight(null);
                  }
                },
                onPointerUp: (d) {
                  if (c.downButtons & kPrimaryButton != 0) {
                    if (c.state.value == OngoingCallState.active) {
                      if ((d.localPosition.distanceSquared -
                                  c.downPosition.distanceSquared)
                              .abs() <=
                          80000) {
                        if (c.highlighted.value == null) {
                          if (c.showUi.isFalse) {
                            c.keepUi();
                          } else {
                            c.keepUi(c.isPanelOpen.value);
                          }
                        } else {
                          c.keepUi(c.isPanelOpen.value);
                        }
                      }
                    }
                  }
                },
              ),
        // Sliding from the top title bar.
        SafeArea(
          child: AnimatedSlider(
            duration: const Duration(milliseconds: 400),
            isOpen: showUi &&
                (c.state.value != OngoingCallState.active || videos.isEmpty),
            beginOffset: Offset(
              0,
              -190 - MediaQuery.of(context).padding.top,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: c.size.height * 0.05,
                ),
                child: callTitle(c),
              ),
            ),
          ),
        ),
        // Sliding from the bottom buttons panel.
        SafeArea(
          left: false,
          right: false,
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: c.state.value == OngoingCallState.active ||
                    c.state.value == OngoingCallState.joining
                ? AnimatedSlider(
                    beginOffset: Offset(
                      0,
                      130 + MediaQuery.of(context).padding.bottom,
                    ),
                    isOpen: showUi,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuad,
                    reverseCurve: Curves.easeOutQuad,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(size: c.size),
                      child: SlidingUpPanel(
                        controller: c.panelController,
                        boxShadow: null,
                        color: PlatformUtils.isIOS && WebUtils.isSafari
                            ? const Color(0xAA000000)
                            : const Color(0x66000000),
                        backdropEnabled: true,
                        backdropOpacity: 0,
                        minHeight: min(c.size.height - 45, 130),
                        maxHeight: panelHeight,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        panel: ConditionalBackdropFilter(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          condition: !PlatformUtils.isIOS || !WebUtils.isSafari,
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Center(
                                child: Container(
                                  width: 60,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0x99FFFFFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(children: panelChildren),
                                ),
                              ),
                            ],
                          ),
                        ),
                        onPanelSlide: (d) {
                          c.keepUi(true);
                          c.isPanelOpen.value = d > 0;
                        },
                        onPanelOpened: () {
                          c.keepUi(true);
                          c.isPanelOpen.value = true;
                        },
                        onPanelClosed: () {
                          c.keepUi();
                          c.isPanelOpen.value = false;
                        },
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: AnimatedSlider(
                            isOpen: showUi,
                            duration: const Duration(milliseconds: 400),
                            beginOffset: Offset(
                              0,
                              150 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: _buttons(
                              isOutgoing
                                  ? [
                                      if (PlatformUtils.isMobile)
                                        _padding(
                                          c.videoState.value.isEnabled()
                                              ? switchButton(c)
                                              : speakerButton(c),
                                        ),
                                      _padding(audioButton(c)),
                                      _padding(videoButton(c)),
                                      _padding(cancelButton(c)),
                                    ]
                                  : [
                                      _padding(acceptAudioButton(c)),
                                      _padding(acceptVideoButton(c)),
                                      _padding(declineButton(c)),
                                    ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ];

      // Combines all the stackable content into [Scaffold].
      Widget scaffold = Scaffold(
        backgroundColor: const Color(0xFF444444),
        body: Stack(
          children: [
            ...content,
            const MouseRegion(
              opaque: false,
              cursor: SystemMouseCursors.basic,
            ),
            ...ui.map((e) => ClipRect(child: e)),
            ...overlay,
          ],
        ),
      );

      if (c.minimized.value) {
        c.applyConstraints(context);
      } else {
        c.applySelfConstraints(context);
      }

      return MinimizableView(
        onInit: (animation) {
          c.minimizedAnimation = animation;
          animation.addListener(() => c.minimized.value = animation.value != 0);
        },
        onDispose: () => c.minimizedAnimation = null,
        child: IgnorePointer(
          ignoring: c.minimized.value,
          child: scaffold,
        ),
      );
    },
  );
}

/// Button with an [icon] and a [child] that has a strict layout.
Widget _layoutButton({
  required Widget icon,
  required Widget child,
  void Function()? onTap,
}) =>
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(flex: 1, child: icon),
            Expanded(flex: 3, child: child),
          ],
        ),
      ),
    );

/// Returns labeled [_layoutButton].
Widget _textButton(
  BuildContext context, {
  void Function()? onTap,
  String? label,
  Widget? asset,
}) =>
    _layoutButton(
      icon: RoundFloatingButton(
        onPressed: onTap,
        scale: 0.75,
        children: asset == null ? [] : [asset],
      ),
      child: Text(
        label ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.headline4
            ?.copyWith(color: Colors.white, fontSize: 17),
      ),
      onTap: onTap,
    );

/// Returns [_layoutButton] of a [User].
Widget _userButton(CallController c, BuildContext context, User user) =>
    Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: _layoutButton(
        icon: Center(
          child: SizedBox(
            width: 45,
            height: 45,
            child: AvatarWidget.fromUser(
              user,
              radius: 22,
            ),
          ),
        ),
        child: Text(
          user.name?.val ?? user.num.val,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.headline4
              ?.copyWith(color: Colors.white, fontSize: 17),
        ),
        onTap: () {
          c.minimize();
          router.user(user.id);
        },
      ),
    );

/// Call's tile containing information about the call.
Widget _callTile(BuildContext context, CallController c) => Obx(
      () {
        bool isOutgoing =
            (c.outgoing || c.state.value == OngoingCallState.local) &&
                !c.started;
        String state = c.state.value == OngoingCallState.active
            ? c.duration.value.localizedString()
            : c.state.value == OngoingCallState.joining
                ? 'label_call_joining'.tr
                : isOutgoing
                    ? 'label_call_calling'.tr
                    : c.withVideo == true
                        ? 'label_video_call'.tr
                        : 'label_audio_call'.tr;

        return _layoutButton(
          icon: Center(
            child: SizedBox(
              width: 58,
              height: 58,
              child: AvatarWidget.fromRxChat(c.chat.value),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.chat.value?.title.value ?? ('.'.tr * 3),
                style: context.textTheme.headline4
                    ?.copyWith(color: Colors.white, fontSize: 20),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 5),
              Text(
                state,
                style: context.textTheme.headline4
                    ?.copyWith(color: Colors.white, fontSize: 15),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          onTap: () {
            if (c.chat.value != null) {
              c.minimize();
              router.chat(c.chat.value!.chat.value.id);
            }
          },
        );
      },
    );

/// [RtcVideoView] in a fit view.
Widget _mobileVideo(
  CallController c, {
  required Participant participant,
  required List<Participant> videos,
}) =>
    GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (d) {},
      // Required for `Flutter` to handle the [ContextMenuRegion]'s
      // secondary tap.
      onSecondaryTap: () {},
      child: StatefulBuilder(builder: (context, setState) {
        return LayoutBuilder(
          builder: (context, constraints) => Obx(
            () {
              bool? muted = participant.owner == MediaOwnerKind.local
                  ? !c.audioState.value.isEnabled()
                  : participant.source == MediaSourceKind.Display
                      ? c
                          .findParticipant(
                              participant.id, MediaSourceKind.Device)
                          ?.audio
                          .value
                          ?.muted
                      : null;

              BoxFit? fit = BoxFit.contain;

              if (participant.video.value != null) {
                RtcVideoRenderer renderer = participant.video.value!;

                if (renderer.source != MediaSourceKind.Display) {
                  fit = c.rendererBoxFit[renderer.track.id()];
                }

                // Calculate the default [BoxFit] if there's no explicit fit
                // and this renderer's stream is from camera.
                if (renderer.source == MediaSourceKind.Device && fit == null) {
                  if (renderer.width == 0 && renderer.height == 0) {
                    fit = BoxFit.contain;
                  } else {
                    bool contain = false;

                    // Video is horizontal.
                    if (renderer.aspectRatio >= 1) {
                      double width = constraints.maxWidth;
                      double height = renderer.height *
                          (constraints.maxWidth / renderer.width);
                      double factor = constraints.maxHeight / height;
                      contain = factor >= 2.41;
                      if (factor < 1) {
                        width = renderer.width *
                            (constraints.maxHeight / renderer.height);
                        height = constraints.maxHeight;
                        factor = constraints.maxWidth / width;
                        contain = factor >= 1.5;
                      }
                    }
                    // Video is vertical.
                    else {
                      double width = renderer.width *
                          (constraints.maxHeight / renderer.height);
                      double height = constraints.maxHeight;
                      double factor = constraints.maxWidth / width;
                      contain = factor >= 1.5;
                      if (factor < 1) {
                        width = constraints.maxWidth;
                        height = renderer.height *
                            (constraints.maxWidth / renderer.width);
                        factor = constraints.maxHeight / height;
                        contain = factor >= 2.2;
                      }
                    }

                    fit = contain ? BoxFit.contain : BoxFit.cover;
                  }
                }
              }

              return ContextMenuRegion(
                preventContextMenu: false,
                enabled: participant.video.value != null,
                menu: ContextMenu(
                  actions: [
                    if (participant.video.value?.isEnabled == true) ...[
                      if (participant.source != MediaSourceKind.Display)
                        ContextMenuButton(
                          label: fit == null || fit == BoxFit.cover
                              ? 'btn_call_do_not_cut_video'.tr
                              : 'btn_call_cut_video'.tr,
                          onPressed: () {
                            c.rendererBoxFit[
                                    participant.video.value!.track.id()] =
                                fit == null || fit == BoxFit.cover
                                    ? BoxFit.contain
                                    : BoxFit.cover;
                            if (c.focused.isNotEmpty) {
                              c.focused.refresh();
                            } else {
                              c.remotes.refresh();
                              c.locals.refresh();
                            }
                          },
                        ),
                      if (videos.length > 1)
                        ContextMenuButton(
                          label: 'btn_call_center_video'.tr,
                          onPressed: () => c.highlight(participant),
                        ),
                    ],
                    ContextMenuButton(
                      label: participant.video.value?.isEnabled == true
                          ? 'btn_call_disable_video'.tr
                          : 'btn_call_enable_video'.tr,
                      onPressed: () =>
                          c.toggleRendererEnabled(participant.video),
                    ),
                  ],
                ),
                child: ParticipantWidget(
                  participant,
                  offstageUntilDetermined: true,
                  onSizeDetermined: () => setState(() {}),
                  fit: fit ?? BoxFit.cover,
                  enableContextMenu: false,
                  muted: muted,
                  withLabels: !c.minimized.value,
                  borderRadius: BorderRadius.zero,
                ),
              );
            },
          ),
        );
      }),
    );

/// [FitView] of a [mobile] widgets.
Widget _mobileView(CallController c, List<Widget> mobile) => mobile.isEmpty
    ? Obx(
        () => CallCoverWidget(c.chat.value?.callCover),
      )
    : AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: FitView(
          key: Key('${mobile.length}'),
          children: mobile,
        ),
      );
