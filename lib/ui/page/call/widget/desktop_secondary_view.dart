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
import 'package:messenger/l10n/l10n.dart';

import '/util/web/web_utils.dart';
import '/domain/model/ongoing_call.dart';
import '/themes.dart';
import '/util/platform_utils.dart';
import '../../../widget/context_menu/menu.dart';
import '../../../widget/context_menu/region.dart';
import '../../../widget/svg/svg.dart';
import '../component/desktop.dart';
import '../component/desktop_sub.dart';
import '../controller.dart';
import 'animated_delayed_scale.dart';
import 'conditional_backdrop.dart';
import 'participant.dart';
import 'reorderable_fit.dart';
import 'scaler.dart';

/// [ReorderableFit] of the [CallController.secondary] participants.
class SecondaryView extends StatelessWidget {
  const SecondaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      builder: (CallController c) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(size: c.size),
          child: Obx(() {
            if (c.secondary.isEmpty) {
              return Container();
            }

            // [BorderRadius] to decorate the secondary panel with.
            final BorderRadius borderRadius = BorderRadius.circular(10);

            double? left, right;
            double? top, bottom;
            Axis? axis;

            if (c.secondaryAlignment.value == Alignment.centerRight) {
              top = 0;
              right = 0;
              axis = Axis.horizontal;
            } else if (c.secondaryAlignment.value == Alignment.centerLeft) {
              top = 0;
              left = 0;
              axis = Axis.horizontal;
            } else if (c.secondaryAlignment.value == Alignment.topCenter) {
              top = 0;
              left = 0;
              axis = Axis.vertical;
            } else if (c.secondaryAlignment.value == Alignment.bottomCenter) {
              bottom = 0;
              left = 0;
              axis = Axis.vertical;
            } else {
              left = c.secondaryLeft.value;
              top = c.secondaryTop.value;
              right = c.secondaryRight.value;
              bottom = c.secondaryBottom.value;

              axis = null;
            }

            double width, height;
            if (axis == Axis.horizontal) {
              width = c.secondaryWidth.value;
              height = c.size.height;
            } else if (axis == Axis.vertical) {
              width = c.size.width;
              height = c.secondaryHeight.value;
            } else {
              width = c.secondaryWidth.value;
              height = c.secondaryHeight.value;
            }

            void onDragEnded(DesktopDragData d) {
              c.secondaryDrags.value = 0;
              c.draggedRenderer.value = null;
              c.doughDraggedRenderer.value = null;
              c.hoveredRenderer.value = d.participant;
              c.hoveredRendererTimeout = 5;
              c.isCursorHidden.value = false;
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                // Secondary panel shadow.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: IgnorePointer(
                    child: Obx(() {
                      if (c.secondaryAlignment.value == null) {
                        return Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            boxShadow: const [
                              CustomBoxShadow(
                                color: Color(0x44000000),
                                blurRadius: 9,
                                blurStyle: BlurStyle.outer,
                              )
                            ],
                            borderRadius: borderRadius,
                          ),
                        );
                      }

                      return Container();
                    }),
                  ),
                ),

                // Secondary panel background.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Obx(() {
                        if (c.secondaryAlignment.value == null) {
                          return IgnorePointer(
                            child: ClipRRect(
                              borderRadius: borderRadius,
                              child: Stack(
                                children: [
                                  Container(color: const Color(0xFF0A1724)),
                                  SvgImage.asset(
                                    'assets/images/background_dark.svg',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(color: const Color(0x11FFFFFF)),
                                ],
                              ),
                            ),
                          );
                        }

                        return Container();
                      }),
                    ),
                  ),
                ),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.centerLeft,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                x: ScaleModeX.left,
                                dx: dx,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.centerRight,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                x: ScaleModeX.right,
                                dx: -dx,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.bottomCenter,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                y: ScaleModeY.bottom,
                                dy: -dy,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.topCenter,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                y: ScaleModeY.top,
                                dy: dy,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.topLeft,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                y: ScaleModeY.top,
                                x: ScaleModeX.left,
                                dx: dx,
                                dy: dy,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.topRight,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                y: ScaleModeY.top,
                                x: ScaleModeX.right,
                                dx: -dx,
                                dy: dy,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.bottomLeft,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                y: ScaleModeY.bottom,
                                x: ScaleModeX.left,
                                dx: dx,
                                dy: -dy,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.bottomRight,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                y: ScaleModeY.bottom,
                                x: ScaleModeX.right,
                                dx: -dx,
                                dy: -dy,
                              ),
                            )
                          : Container(),
                    )),

                // Secondary panel itself.
                ReorderableFit<DesktopDragData>(
                  key: const Key('SecondaryFitView'),
                  onAdded: (d, i) => c.unfocus(d.participant),
                  onWillAccept: (d) {
                    if (d?.chatId == c.chatId.value) {
                      c.secondaryTargets.value = 1;
                      return true;
                    }

                    return false;
                  },
                  onLeave: (b) => c.secondaryTargets.value = 0,
                  onDragStarted: (r) {
                    c.draggedRenderer.value = r.participant;
                    c.showDragAndDropVideosHint = false;
                    c.secondaryDrags.value = 1;
                    c.displayMore.value = false;
                    c.keepUi(false);
                  },
                  onDoughBreak: (r) =>
                      c.doughDraggedRenderer.value = r.participant,
                  onDragEnd: onDragEnded,
                  onDragCompleted: onDragEnded,
                  onDraggableCanceled: onDragEnded,
                  axis: axis,
                  width: width,
                  height: height,
                  left: left,
                  top: top,
                  right: right,
                  bottom: bottom,
                  onOffset: () {
                    if (c.minimized.value && !c.fullscreen.value) {
                      return Offset(-c.left.value, -c.top.value - 30);
                    } else if (!WebUtils.isPopup) {
                      return const Offset(0, -30);
                    }

                    return Offset.zero;
                  },
                  overlayBuilder: (DesktopDragData data) {
                    var participant = data.participant;

                    return Obx(() {
                      bool muted =
                          participant.member.owner == MediaOwnerKind.local
                              ? !c.audioState.value.isEnabled
                              : participant.audio.value?.isMuted.value ?? false;

                      bool anyDragIsHappening = c.secondaryDrags.value != 0 ||
                          c.primaryDrags.value != 0 ||
                          c.secondaryDragged.value;

                      bool isHovered = c.hoveredRenderer.value == participant &&
                          !anyDragIsHappening;

                      return MouseRegion(
                        opaque: false,
                        onEnter: (d) {
                          if (c.draggedRenderer.value == null) {
                            c.hoveredRenderer.value = data.participant;
                            c.hoveredRendererTimeout = 5;
                            c.isCursorHidden.value = false;
                          }
                        },
                        onHover: (d) {
                          if (c.draggedRenderer.value == null) {
                            c.hoveredRenderer.value = data.participant;
                            c.hoveredRendererTimeout = 5;
                            c.isCursorHidden.value = false;
                          }
                        },
                        onExit: (d) {
                          c.hoveredRendererTimeout = 0;
                          c.hoveredRenderer.value = null;
                          c.isCursorHidden.value = false;
                        },
                        child: AnimatedSwitcher(
                          duration: 200.milliseconds,
                          child: c.draggedRenderer.value == data.participant
                              ? Container()
                              : ContextMenuRegion(
                                  key: ObjectKey(participant),
                                  preventContextMenu: true,
                                  actions: [
                                    ContextMenuButton(
                                      label: 'btn_call_center'.l10n,
                                      onPressed: () => c.center(participant),
                                    ),
                                    if (participant.member.id != c.me.id) ...[
                                      if (participant.video.value?.direction
                                              .value.isEmitting ??
                                          false)
                                        ContextMenuButton(
                                          label: participant.video.value
                                                      ?.renderer.value !=
                                                  null
                                              ? 'btn_call_disable_video'.l10n
                                              : 'btn_call_enable_video'.l10n,
                                          onPressed: () =>
                                              c.toggleVideoEnabled(participant),
                                        ),
                                      if (participant.audio.value?.direction
                                              .value.isEmitting ??
                                          false)
                                        ContextMenuButton(
                                          label: (participant
                                                      .audio
                                                      .value
                                                      ?.direction
                                                      .value
                                                      .isEnabled ==
                                                  true)
                                              ? 'btn_call_disable_audio'.l10n
                                              : 'btn_call_enable_audio'.l10n,
                                          onPressed: () =>
                                              c.toggleAudioEnabled(participant),
                                        ),
                                      if (participant
                                          .member.isRedialing.isFalse)
                                        ContextMenuButton(
                                          label: 'btn_call_remove_participant'
                                              .l10n,
                                          onPressed: () =>
                                              c.removeChatCallMember(
                                            participant.member.id.userId,
                                          ),
                                        ),
                                    ] else ...[
                                      ContextMenuButton(
                                        label: c.videoState.value.isEnabled
                                            ? 'btn_call_video_off'.l10n
                                            : 'btn_call_video_on'.l10n,
                                        onPressed: c.toggleVideo,
                                      ),
                                      ContextMenuButton(
                                        label: c.audioState.value.isEnabled
                                            ? 'btn_call_audio_off'.l10n
                                            : 'btn_call_audio_on'.l10n,
                                        onPressed: c.toggleAudio,
                                      ),
                                    ],
                                  ],
                                  child: IgnorePointer(
                                    child: ParticipantOverlayWidget(
                                      participant,
                                      key: ObjectKey(participant),
                                      muted: muted,
                                      hovered: isHovered,
                                      preferBackdrop: !c.minimized.value ||
                                          c.fullscreen.value,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    });
                  },
                  decoratorBuilder: (_) => const ParticipantDecoratorWidget(),
                  itemConstraints: (DesktopDragData data) {
                    final double size =
                        (c.size.longestSide * 0.33).clamp(100, 250);
                    return BoxConstraints(maxWidth: size, maxHeight: size);
                  },
                  itemBuilder: (DesktopDragData data) {
                    var participant = data.participant;
                    return Obx(
                      () => ParticipantWidget(
                        participant,
                        key: ObjectKey(participant),
                        offstageUntilDetermined: true,
                        respectAspectRatio: true,
                        borderRadius: BorderRadius.zero,
                        expanded: c.doughDraggedRenderer.value == participant,
                      ),
                    );
                  },
                  children: c.secondary
                      .map((e) => DesktopDragData(e, c.chatId.value))
                      .toList(),
                  borderRadius:
                      c.secondaryAlignment.value == null ? borderRadius : null,
                ),

                // Discards the pointer when hovered over videos.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: MouseRegion(
                    opaque: false,
                    cursor: SystemMouseCursors.basic,
                    child: IgnorePointer(
                        child: SizedBox(width: width, height: height)),
                  ),
                ),

                // Sliding from top draggable title bar.
                Positioned(
                  key: c.secondaryKey,
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: Obx(() {
                    bool isAnyDrag = c.secondaryDrags.value != 0 ||
                        c.primaryDrags.value != 0;

                    return SizedBox(
                      width: width,
                      height: height,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: 30,
                          child: MouseRegion(
                            cursor: isAnyDrag
                                ? MouseCursor.defer
                                : SystemMouseCursors.grab,
                            child: GestureDetector(
                              onPanStart: (d) {
                                c.secondaryBottomShifted = null;
                                c.secondaryDragged.value = true;
                                c.displayMore.value = false;
                                c.keepUi(false);

                                c.calculateSecondaryPanning(d.globalPosition);

                                if (c.secondaryAlignment.value != null) {
                                  c.secondaryAlignment.value = null;
                                  c.updateSecondaryOffset(d.globalPosition);
                                } else {
                                  c.secondaryLeft.value ??= c.size.width -
                                      c.secondaryWidth.value -
                                      (c.secondaryRight.value ?? 0);
                                  c.secondaryTop.value ??= c.size.height -
                                      c.secondaryHeight.value -
                                      (c.secondaryBottom.value ?? 0);
                                  c.applySecondaryConstraints();
                                }

                                c.secondaryRight.value = null;
                                c.secondaryBottom.value = null;
                              },
                              onPanUpdate: (d) {
                                c.updateSecondaryOffset(d.globalPosition);
                                c.applySecondaryConstraints();
                              },
                              onPanEnd: (d) {
                                c.secondaryDragged.value = false;
                                if (c.possibleSecondaryAlignment.value !=
                                    null) {
                                  c.secondaryAlignment.value =
                                      c.possibleSecondaryAlignment.value;
                                  c.possibleSecondaryAlignment.value = null;
                                  c.applySecondaryConstraints();
                                } else {
                                  c.updateSecondaryAttach();
                                }
                              },
                              child: AnimatedOpacity(
                                duration: 200.milliseconds,
                                key: const ValueKey('TitleBar'),
                                opacity: c.secondaryHovered.value ? 1 : 0,
                                child: ClipRRect(
                                  borderRadius:
                                      c.secondaryAlignment.value == null
                                          ? BorderRadius.only(
                                              topLeft: borderRadius.topLeft,
                                              topRight: borderRadius.topRight,
                                            )
                                          : BorderRadius.zero,
                                  child: ConditionalBackdropFilter(
                                    condition: PlatformUtils.isWeb &&
                                        (c.minimized.isFalse ||
                                            c.fullscreen.isTrue),
                                    child: Container(
                                      color: PlatformUtils.isWeb
                                          ? const Color(0x9D165084)
                                          : const Color(0xE9165084),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 7),
                                          const Expanded(
                                            child: Text(
                                              'Draggable',
                                              style: TextStyle(
                                                  color: Colors.white),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          InkResponse(
                                            onTap:
                                                isAnyDrag ? null : c.focusAll,
                                            child: SvgImage.asset(
                                              'assets/icons/close.svg',
                                              height: 10.25,
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == Alignment.centerRight
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.centerLeft,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                x: ScaleModeX.left,
                                dx: dx,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == Alignment.centerLeft
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.centerRight,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                x: ScaleModeX.right,
                                dx: -dx,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == Alignment.topCenter
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.bottomCenter,
                              onDrag: (dx, dy) => c.resizeSecondary(
                                context,
                                y: ScaleModeY.top,
                                dy: dy,
                              ),
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == Alignment.bottomCenter
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.topCenter,
                            )
                          : Container(),
                    )),

                // Secondary panel drag target indicator.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Obx(() {
                        return AnimatedSwitcher(
                          duration: 200.milliseconds,
                          child: c.primaryDrags.value != 0 &&
                                  c.secondaryTargets.value != 0
                              ? Container(
                                  color: const Color(0x40000000),
                                  child: Center(
                                    child: AnimatedDelayedScale(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      beginScale: 1,
                                      endScale: 1.06,
                                      child: ConditionalBackdropFilter(
                                        condition: !c.minimized.value ||
                                            c.fullscreen.value,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            color: !c.minimized.value ||
                                                    c.fullscreen.value
                                                ? const Color(0x40000000)
                                                : const Color(0x90000000),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Icon(
                                              Icons.add_rounded,
                                              size: 50,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        );
                      }),
                    ),
                  ),
                ),

                // Secondary panel border.
                Positioned(
                  left: left == null ? null : (left - Scaler.size / 2),
                  right: right == null ? null : (right - Scaler.size / 2),
                  top: top == null ? null : (top - Scaler.size / 2),
                  bottom: bottom == null ? null : (bottom - Scaler.size / 2),
                  child: MouseRegion(
                    opaque: false,
                    onEnter: (p) => c.secondaryHovered.value = true,
                    onHover: (p) => c.secondaryHovered.value = true,
                    onExit: (p) => c.secondaryHovered.value = false,
                    child: SizedBox(
                      width: width + Scaler.size,
                      height: height + Scaler.size,
                      child: Obx(() {
                        return Stack(
                          children: [
                            IgnorePointer(
                              child: AnimatedContainer(
                                duration: 200.milliseconds,
                                margin: const EdgeInsets.all(Scaler.size / 2),
                                decoration: ShapeDecoration(
                                  shape: c.secondaryHovered.value ||
                                          c.primaryDrags.value != 0
                                      ? c.secondaryAlignment.value == null
                                          ? RoundedRectangleBorder(
                                              side: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 1,
                                              ),
                                              borderRadius: borderRadius,
                                            )
                                          : Border(
                                              top: c.secondaryAlignment.value ==
                                                      Alignment.bottomCenter
                                                  ? BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      width: 1,
                                                    )
                                                  : BorderSide.none,
                                              left: c.secondaryAlignment
                                                          .value ==
                                                      Alignment.centerRight
                                                  ? BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      width: 1,
                                                    )
                                                  : BorderSide.none,
                                              right: c.secondaryAlignment
                                                          .value ==
                                                      Alignment.centerLeft
                                                  ? BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      width: 1,
                                                    )
                                                  : BorderSide.none,
                                              bottom: c.secondaryAlignment
                                                          .value ==
                                                      Alignment.topCenter
                                                  ? BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      width: 1,
                                                    )
                                                  : BorderSide.none,
                                            )
                                      : c.secondaryAlignment.value == null
                                          ? RoundedRectangleBorder(
                                              side: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0),
                                                width: 1,
                                              ),
                                              borderRadius: borderRadius,
                                            )
                                          : Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0),
                                              width: 1,
                                            ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

class PositionedBoilerplateWidget extends StatelessWidget {
  const PositionedBoilerplateWidget({
    Key? key,
    required this.child,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.width,
    required this.height,
  }) : super(key: key);

  /// The widget contained by this widget
  final Widget child;

  /// The distance between the left edge of the [PositionedBoilerplateWidget]
  /// and the left edge of the parent widget.
  final double? left;

  /// The distance between the right edge of the [PositionedBoilerplateWidget]
  /// and the right edge of the parent widget.
  final double? right;

  /// The distance between the top edge of the [PositionedBoilerplateWidget]
  /// and the top edge of the parent widget.
  final double? top;

  /// The distance between the bottom edge of the [PositionedBoilerplateWidget]
  /// and the bottom edge of the parent widget.
  final double? bottom;

  ///The width of the [PositionedBoilerplateWidget].
  final double width;

  ///The height of the [PositionedBoilerplateWidget].
  final double height;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left == null ? null : (left! - Scaler.size / 2),
      right: right == null ? null : (right! - Scaler.size / 2),
      top: top == null ? null : (top! - Scaler.size / 2),
      bottom: bottom == null ? null : (bottom! - Scaler.size / 2),
      child: SizedBox(
        width: width + Scaler.size,
        height: height + Scaler.size,
        child: child,
      ),
    );
  }
}
