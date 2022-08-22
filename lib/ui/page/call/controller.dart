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

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' show VideoView;
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:mutex/mutex.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'participant/controller.dart';
import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/info/add_member/view.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/context_menu/overlay.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'add_dialog_member/view.dart';
import 'component/common.dart';
import 'settings/view.dart';

export 'view.dart';

/// Controller of an [OngoingCall] overlay.
class CallController extends GetxController {
  CallController(
    this._currentCall,
    this._calls,
    this._chatService,
    this._userService,
  );

  /// Duration of the current ongoing call.
  final Rx<Duration> duration = Rx<Duration>(Duration.zero);

  /// Reactive [Chat] that this [OngoingCall] is happening in.
  final Rx<RxChat?> chat = Rx<RxChat?>(null);

  /// Indicator whether the view is minimized or maximized.
  late final RxBool minimized;

  /// Indicator whether the view is fullscreen or not.
  late final RxBool fullscreen;

  /// Indicator whether UI is shown or not.
  final RxBool showUi = RxBool(true);
  final RxBool showHeader = RxBool(true);

  /// Local [Participant]s in `default` mode.
  final RxList<Participant> locals = RxList([]);

  /// Remote [Participant]s in `default` mode.
  final RxList<Participant> remotes = RxList([]);

  /// [Participant]s in `focus` mode.
  final RxList<Participant> focused = RxList([]);

  /// [Participant]s in `panel` mode.
  final RxList<Participant> paneled = RxList([]);

  /// Indicator whether the secondary view is being scaled.
  final RxBool secondaryScaled = RxBool(false);

  /// Indicator whether the secondary view is being hovered.
  final RxBool secondaryHovered = RxBool(false);

  /// Indicator whether the secondary view is being dragged.
  final RxBool secondaryDragged = RxBool(false);

  /// Indicator whether the secondary view is being manipulated in any way, be
  /// that scaling or panning.
  final RxBool secondaryManipulated = RxBool(false);

  /// [Participant] being dragged currently.
  final Rx<Participant?> draggedRenderer = Rx(null);

  /// [Participant] being dragged currently with its dough broken.
  final Rx<Participant?> doughDraggedRenderer = Rx(null);

  /// [Participant]s to display in the fit view.
  final RxList<Participant> primary = RxList();

  /// [Participant]s to display in the secondary view.
  final RxList<Participant> secondary = RxList();

  /// Indicator whether the view is mobile or desktop.
  late bool isMobile;

  /// [OverlayEntry] of an empty secondary view.
  OverlayEntry? secondaryEntry;

  /// Count of a currently happening drags of the secondary videos used to
  /// determine if any drag happened at all.
  final RxInt secondaryDrags = RxInt(0);

  /// Count of a currently happening drags of the primary videos used to
  /// determine if any drag happened at all and to display secondary view hint.
  final RxInt primaryDrags = RxInt(0);

  /// Count of [Participant]s to be accepted into the fit view.
  final RxInt primaryTargets = RxInt(0);

  /// Count of [Participant]s to be accepted into the secondary view.
  final RxInt secondaryTargets = RxInt(0);

  /// Indicator whether the camera was switched or not.
  final RxBool cameraSwitched = RxBool(false);

  /// Indicator whether the speaker was switched or not.
  final RxBool speakerSwitched = RxBool(true);

  /// Temporary indicator whether the hand was raised or not.
  final RxBool isHandRaised = RxBool(false);

  /// Indicator whether the buttons panel is open or not.
  final RxBool isPanelOpen = RxBool(false);

  /// Indicator whether the hint is dismissed or not.
  final RxBool isHintDismissed = RxBool(true);

  /// Indicator whether the more hint is dismissed or not.
  final RxBool isMoreHintDismissed = RxBool(true);

  /// Indicator whether the cursor should be hidden or not.
  final RxBool isCursorHidden = RxBool(false);

  /// [PanelController] used to close the [SlidingUpPanel].
  final PanelController panelController = PanelController();

  /// Position of a [Listener.onPointerDown] callback used in
  /// [Listener.onPointerUp] since the latter does not provide this info.
  Offset downPosition = Offset.zero;

  /// Buttons that were pressed in a [Listener.onPointerDown] callback used in
  /// [Listener.onPointerUp] since the latter does not provide this info.
  int downButtons = 0;

  /// [Participant] that is hovered right now.
  final Rx<Participant?> hoveredRenderer = Rx<Participant?>(null);

  /// Timeout of a [hoveredRenderer] used to hide it.
  int hoveredRendererTimeout = 0;

  /// Temporary indicator whether the secondary view should always be on top.
  final RxBool panelUp = RxBool(false);

  /// Temporary indicator whether a left mouse button clicks on
  /// [RtcVideoRenderer]s should call [focus], [unfocus] and [center] or not.
  final RxBool handleLmb = RxBool(false);

  /// Timeout of a [handleLmb] used to decline any clicks happened after it
  /// reaches zero.
  int lmbTimeout = 7;

  /// Error happened in a call.
  final RxString error = RxString('');

  /// Timeout of a [error] being shown.
  final RxInt errorTimeout = RxInt(0);

  /// Minimized view current width.
  late final RxDouble width;

  /// Minimized view current height.
  late final RxDouble height;

  /// Minimized view current top position.
  late final RxDouble top;

  /// Minimized view current left position.
  late final RxDouble left;

  /// Indicator whether more panel is displayed.
  final RxBool displayMore = RxBool(false);

  /// [CallButton]s available in the more panel.
  late final RxList<CallButton> panel;

  /// [CallButton]s placed in the [Dock].
  late final RxList<CallButton> buttons;

  /// [GlobalKey] of the [Dock].
  final GlobalKey dockKey = GlobalKey();

  /// Currently dragged [CallButton].
  final Rx<CallButton?> draggedButton = Rx(null);

  /// [AnimationController] of a [MinimizableView] used to change the
  /// [minimized] value.
  AnimationController? minimizedAnimation;

  /// Maximum size a single [CallButton] is allowed to occupy in the [Dock].
  static const double buttonSize = 48.0;

  /// Color of a call buttons that accept the call.
  static const Color acceptColor = Color(0x7F34B139);

  /// Color of a call buttons that end the call.
  static const Color endColor = Color(0x7FFF0000);

  /// Secondary view current left position.
  final RxnDouble secondaryLeft = RxnDouble(0);

  /// Secondary view current top position.
  final RxnDouble secondaryTop = RxnDouble(0);

  /// Secondary view current right position.
  final RxnDouble secondaryRight = RxnDouble(null);

  /// Secondary view current bottom position.
  final RxnDouble secondaryBottom = RxnDouble(null);

  /// Secondary view current width.
  late final RxDouble secondaryWidth;

  /// Secondary view current height.
  late final RxDouble secondaryHeight;

  /// [secondaryWidth] or [secondaryHeight] of the secondary view before its
  /// scaling.
  double? secondaryUnscaledSize;

  /// [Alignment] of the secondary view.
  final Rx<Alignment?> secondaryAlignment = Rx(Alignment.centerRight);

  /// [Alignment] that might become the [secondaryAlignment] serving as a hint
  /// while dragging the secondary view.
  final Rx<Alignment?> possibleSecondaryAlignment = Rx(null);

  /// [Offset] the secondary view has relative to the pan gesture position.
  Offset? secondaryPanningOffset;

  /// [GlobalKey] of the secondary view.
  final GlobalKey secondaryKey = GlobalKey();

  /// [secondaryBottom] value before the secondary view got relocated with the
  /// [relocateSecondary] method.
  double? secondaryBottomShifted;

  /// Indicator whether the [relocateSecondary] is already invoked during the
  /// current frame.
  bool _secondaryRelocated = false;

  /// Height of the title bar.
  static const double titleHeight = 30;

  /// Indicator whether the [MinimizableView] is being minimized.
  final RxBool minimizing = RxBool(false);

  /// Max width of the minimized view in percentage of the screen width.
  static const double _maxWidth = 0.99;

  /// Max height of the minimized view in percentage of the screen height.
  static const double _maxHeight = 0.99;

  /// Min width of the minimized view in pixels.
  static const double _minWidth = 500;

  /// Min height of the minimized view in pixels.
  static const double _minHeight = 500;

  /// Max width of the secondary view in percentage of the call width.
  static const double _maxSWidth = 0.80;

  /// Max height of the secondary view in percentage of the call height.
  static const double _maxSHeight = 0.80;

  /// Min width of the secondary view in pixels.
  static const double _minSWidth = 100;

  /// Min height of the secondary view in pixels.
  static const double _minSHeight = 100;

  /// Duration of UI being opened in seconds.
  static const int _uiDuration = 4;

  /// Duration of an error being shown in seconds.
  static const int _errorDuration = 6;

  /// Mutex guarding [toggleHand].
  final Mutex _toggleHandGuard = Mutex();

  /// Service managing the [_currentCall].
  final CallService _calls;

  /// [Chat]s service used to fetch the[chat].
  final ChatService _chatService;

  /// Current [OngoingCall].
  final Rx<OngoingCall> _currentCall;

  /// [User]s service, used to fill a [Participant.user] field.
  final UserService _userService;

  /// Timer for updating [duration] of the call.
  ///
  /// Starts once the [state] becomes [OngoingCallState.active].
  Timer? _durationTimer;

  /// Timer to toggle [showUi] value.
  Timer? _uiTimer;

  /// Subscription for [PlatformUtils.onFullscreenChange], used to correct the
  /// [fullscreen] value.
  StreamSubscription? _onFullscreenChange;

  /// Subscription for [OngoingCall.errors] stream.
  StreamSubscription? _errorsSubscription;

  /// [Map] of [BoxFit]s that [RtcVideoRenderer] should explicitly have.
  final RxMap<String, BoxFit?> rendererBoxFit = RxMap<String, BoxFit?>();

  /// [Worker] for catching the [state] changes to start the [_durationTimer].
  late final Worker _stateWorker;

  /// [Worker] closing the more panel on [showUi] changes.
  late final Worker _showUiWorker;

  /// Subscription for [OngoingCall.localVideos] changes.
  late final StreamSubscription _localsSubscription;

  /// Subscription for [OngoingCall.remoteVideos] changes.
  late final StreamSubscription _remotesSubscription;

  /// Subscription for [OngoingCall.remoteAudios] changes.
  late final StreamSubscription _audiosSubscription;

  /// Subscription for [OngoingCall.members] changes.
  late final StreamSubscription _membersSubscription;

  /// Subscription for [OngoingCall.members] changes updating the title.
  StreamSubscription? _titleSubscription;

  /// Subscription for [duration] changes updating the title.
  StreamSubscription? _durationSubscription;

  /// [Worker] reacting on [OngoingCall.chatId] changes to fetch the new [chat].
  late final Worker _chatWorker;

  /// Returns the [ChatId] of the [Chat] this [OngoingCall] is taking place in.
  ChatId get chatId => _currentCall.value.chatId.value;

  /// State of the current [OngoingCall] progression.
  Rx<OngoingCallState> get state => _currentCall.value.state;

  /// Returns an [UserId] of the currently authorized [MyUser].
  UserId get me => _calls.me;

  /// Indicates whether the current authorized [MyUser] is the caller.
  bool get outgoing =>
      _calls.me == _currentCall.value.caller?.id ||
      _currentCall.value.caller == null;

  /// Indicates whether the current [OngoingCall] has started or not.
  bool get started => _currentCall.value.conversationStartedAt != null;

  /// Indicates whether the current [OngoingCall] is with video or not.
  bool get withVideo => _currentCall.value.withVideo ?? false;

  /// Returns remote audio track renderers.
  ObsList<RtcAudioRenderer> get audios => _currentCall.value.remoteAudios;

  /// Returns local audio stream enabled flag.
  Rx<LocalTrackState> get audioState => _currentCall.value.audioState;

  /// Returns local video stream enabled flag.
  Rx<LocalTrackState> get videoState => _currentCall.value.videoState;

  /// Returns local screen-sharing stream enabled flag.
  Rx<LocalTrackState> get screenShareState =>
      _currentCall.value.screenShareState;

  /// Returns an [UserCallCover] of the current call's caller.
  UserCallCover? get callCover => _currentCall.value.caller?.callCover;

  /// Returns a name of the current [OngoingCall]'s caller.
  String? get callerName =>
      _currentCall.value.caller?.name?.val ??
      _currentCall.value.caller?.num.val;

  /// Returns actual size of the call view.
  Size get size {
    if ((!fullscreen.value && minimized.value) || minimizing.value) {
      return Size(width.value, height.value - (isMobile ? 0 : titleHeight));
    } else if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      // TODO: Account [BuildContext.mediaQueryPadding].
      return router.context!.mediaQuerySize;
    } else {
      // If not [WebUtils.isPopup], then subtract the title bar from the height.
      if (fullscreen.isTrue && !WebUtils.isPopup) {
        var size = router.context!.mediaQuerySize;
        return Size(size.width, size.height - titleHeight);
      } else {
        return router.context!.mediaQuerySize;
      }
    }
  }

  /// Indicates whether the [chat] is a dialog.
  bool get isDialog => chat.value?.chat.value.isDialog ?? false;

  /// Indicates whether the [chat] is a group.
  bool get isGroup => chat.value?.chat.value.isGroup ?? false;

  /// Reactive map of the current call [RemoteMemberId]s.
  RxObsMap<RemoteMemberId, bool> get members => _currentCall.value.members;

  /// Indicator whether the inbound video in the current [OngoingCall] is
  /// enabled or not.
  RxBool get isRemoteVideoEnabled => _currentCall.value.isRemoteVideoEnabled;

  /// Indicator whether the inbound audio in the current [OngoingCall] is
  /// enabled.
  RxBool get isRemoteAudioEnabled => _currentCall.value.isRemoteAudioEnabled;

  @override
  void onInit() {
    super.onInit();

    _currentCall.value.init(_chatService.me);

    Size size = router.context!.mediaQuerySize;

    if (router.context!.isMobile) {
      secondaryWidth = RxDouble(150);
      secondaryHeight = RxDouble(151);
    } else {
      secondaryWidth = RxDouble(200);
      secondaryHeight = RxDouble(200);
    }

    fullscreen = RxBool(false);
    minimized = RxBool(!router.context!.isMobile);
    isMobile = router.context!.isMobile;

    if (isMobile) {
      Size size = router.context!.mediaQuerySize;
      width = RxDouble(size.width);
      height = RxDouble(size.height);
    } else {
      width = RxDouble(
        min(
          max(
            min(
              500,
              size.shortestSide * _maxWidth,
            ),
            _minWidth,
          ),
          size.height * _maxHeight,
        ),
      );
      height = RxDouble(width.value);
    }

    left = size.width - width.value - 50 > 0
        ? RxDouble(size.width - width.value - 50)
        : RxDouble(size.width / 2 - width.value / 2);
    top = height.value + 50 < size.height
        ? RxDouble(50)
        : RxDouble(size.height / 2 - height.value / 2);

    void _onChat(RxChat? v) {
      chat.value = v;

      _putParticipant(RemoteMemberId(me, null));
      _insureCorrectGrouping();

      if (!isGroup) {
        secondaryAlignment.value = null;
        secondaryLeft.value = null;
        secondaryTop.value = null;
        secondaryRight.value = 10;
        secondaryBottom.value = 10;
        secondaryBottomShifted = secondaryBottom.value;
      }

      // Update the [WebUtils.title] if this call is in a popup.
      if (WebUtils.isPopup) {
        _titleSubscription?.cancel();
        _durationSubscription?.cancel();

        if (v != null) {
          void _updateTitle() {
            final Map<String, String> args = {
              'title': v.title.value,
              'state': state.value.name,
            };

            switch (state.value) {
              case OngoingCallState.local:
              case OngoingCallState.pending:
                bool isOutgoing =
                    (outgoing || state.value == OngoingCallState.local) &&
                        !started;
                if (isOutgoing) {
                  args['type'] = 'outgoing';
                } else if (withVideo) {
                  args['type'] = 'video';
                } else {
                  args['type'] = 'audio';
                }
                break;

              case OngoingCallState.active:
                var actualMembers = _currentCall.value.members.keys
                    .map((k) => k.userId)
                    .toSet();
                args['members'] = '${actualMembers.length + 1}';
                args['allMembers'] = '${v.chat.value.members.length}';
                args['duration'] = duration.value.hhMmSs();
                break;

              case OngoingCallState.joining:
              case OngoingCallState.ended:
                // No-op.
                break;
            }

            WebUtils.title(
              '\u205f​​​ \u205f​​​${'label_call_title'.l10nfmt(args)}\u205f​​​ \u205f​​​',
            );
          }

          _updateTitle();

          _titleSubscription =
              _currentCall.value.members.listen((_) => _updateTitle());
          _durationSubscription = duration.listen((_) => _updateTitle());
        }
      }
    }

    _chatService.get(_currentCall.value.chatId.value).then(_onChat);
    _chatWorker = ever(
      _currentCall.value.chatId,
      (ChatId id) => _chatService.get(id).then(_onChat),
    );

    _stateWorker = ever(state, (OngoingCallState state) {
      if (state == OngoingCallState.active && _durationTimer == null) {
        SchedulerBinding.instance
            .addPostFrameCallback((_) => relocateSecondary());
        DateTime begunAt = DateTime.now();
        _durationTimer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            duration.value = DateTime.now().difference(begunAt);
            if (hoveredRendererTimeout > 0) {
              --hoveredRendererTimeout;
              if (hoveredRendererTimeout == 0) {
                hoveredRenderer.value = null;
                isCursorHidden.value = true;
              }
            }

            if (lmbTimeout > 0) {
              --lmbTimeout;
            }

            if (errorTimeout.value > 0) {
              --errorTimeout.value;
            }
          },
        );

        keepUi();
      }

      refresh();
    });

    _onFullscreenChange = PlatformUtils.onFullscreenChange.listen((bool v) {
      fullscreen.value = v;
      applySecondaryConstraints();
    });

    _errorsSubscription = _currentCall.value.errors.listen((e) {
      error.value = e;
      errorTimeout.value = _errorDuration;
    });

    buttons = RxList([
      ScreenButton(this),
      VideoButton(this),
      EndCallButton(this),
      AudioButton(this),
      MoreButton(this),
    ]);

    panel = RxList([
      SettingsButton(this),
      AddMemberCallButton(this),
      HandButton(this),
      ScreenButton(this),
      RemoteVideoButton(this),
      RemoteAudioButton(this),
      VideoButton(this),
      AudioButton(this),
    ]);

    _showUiWorker = ever(showUi, (bool showUi) {
      if (displayMore.value && !showUi) {
        displayMore.value = false;
      }
    });

    _membersSubscription = _currentCall.value.members.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          _putParticipant(e.key!, handRaised: e.value);
          _insureCorrectGrouping();
          break;

        case OperationKind.removed:
          bool wasNotEmpty = primary.isNotEmpty;
          paneled.removeWhere((m) => m.id == e.key);
          locals.removeWhere((m) => m.id == e.key);
          focused.removeWhere((m) => m.id == e.key);
          remotes.removeWhere((m) => m.id == e.key);
          _insureCorrectGrouping();
          if (wasNotEmpty && primary.isEmpty) {
            focusAll();
          }

          break;

        case OperationKind.updated:
          _putParticipant(e.key!, handRaised: e.value);
          _insureCorrectGrouping();
          break;
      }
    });

    _localsSubscription = _currentCall.value.localVideos.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          _putParticipant(e.element.memberId, video: e.element);
          _insureCorrectGrouping();
          break;

        case OperationKind.removed:
          rendererBoxFit.remove(e.element.track.id);
          _removeParticipant(e.element.memberId, video: e.element);
          _insureCorrectGrouping();
          Future.delayed(1.seconds, e.element.inner.dispose);
          break;

        case OperationKind.updated:
          findParticipant(e.element.memberId, e.element.source)
              ?.video
              .refresh();
          break;
      }
    });

    _remotesSubscription = _currentCall.value.remoteVideos.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          _putParticipant(e.element.memberId, video: e.element);
          _insureCorrectGrouping();
          break;

        case OperationKind.removed:
          bool wasNotEmpty = primary.isNotEmpty;
          rendererBoxFit.remove(e.element.track.id);
          _removeParticipant(e.element.memberId, video: e.element);
          _insureCorrectGrouping();
          if (wasNotEmpty && primary.isEmpty) {
            focusAll();
          }

          Future.delayed(1.seconds, e.element.inner.dispose);
          break;

        case OperationKind.updated:
          findParticipant(e.element.memberId, e.element.source)
              ?.video
              .refresh();
          break;
      }
    });

    _audiosSubscription = _currentCall.value.remoteAudios.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          _putParticipant(e.element.memberId, audio: e.element);
          _insureCorrectGrouping();
          break;

        case OperationKind.removed:
          _removeParticipant(e.element.memberId, audio: e.element);
          _insureCorrectGrouping();
          e.element.inner.dispose();
          break;

        case OperationKind.updated:
          findParticipant(e.element.memberId, e.element.source)
              ?.audio
              .refresh();
          break;
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    _durationTimer?.cancel();
    _showUiWorker.dispose();
    _uiTimer?.cancel();
    _stateWorker.dispose();
    _chatWorker.dispose();
    _onFullscreenChange?.cancel();
    _errorsSubscription?.cancel();
    _titleSubscription?.cancel();
    _durationSubscription?.cancel();

    secondaryEntry?.remove();

    if (fullscreen.value) {
      PlatformUtils.exitFullscreen();
    }

    Future.delayed(Duration.zero, ContextMenuOverlay.of(router.context!).hide);

    _localsSubscription.cancel();
    _remotesSubscription.cancel();
    _audiosSubscription.cancel();
    _membersSubscription.cancel();
  }

  /// Drops the call.
  void drop() => _currentCall.value.leave(_calls);

  /// Declines the call.
  void decline() => _currentCall.value.decline(_calls);

  /// Joins the call.
  void join({
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  }) =>
      _currentCall.value.join(
        _calls,
        withAudio: withAudio,
        withVideo: withVideo,
        withScreen: withScreen,
      );

  /// Toggles local screen-sharing stream on and off.
  Future<void> toggleScreenShare() async {
    keepUi();
    await _currentCall.value.toggleScreenShare();
  }

  /// Toggles local audio stream on and off.
  Future<void> toggleAudio() async {
    keepUi();
    await _currentCall.value.toggleAudio();
  }

  /// Toggles local video stream on and off.
  Future<void> toggleVideo() async {
    keepUi();
    await _currentCall.value.toggleVideo();
  }

  /// Changes the local video device to the next one from the
  /// [OngoingCall.devices] list.
  Future<void> switchCamera() async {
    keepUi();

    List<MediaDeviceInfo> cameras = _currentCall.value.devices.video().toList();
    if (cameras.length > 1) {
      int selected = _currentCall.value.videoDevice.value == null
          ? 0
          : cameras.indexWhere(
              (e) => e.deviceId() == _currentCall.value.videoDevice.value!);
      selected += 1;
      cameraSwitched.toggle();
      await _currentCall.value.setVideoDevice(
        cameras[(selected) % cameras.length].deviceId(),
      );
    }
  }

  /// Toggles speaker on and off.
  Future<void> toggleSpeaker() async {
    keepUi();

    if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
      List<MediaDeviceInfo> outputs =
          _currentCall.value.devices.output().toList();
      if (outputs.length > 1) {
        int selected = _currentCall.value.outputDevice.value == null
            ? 0
            : outputs.indexWhere(
                (e) => e.deviceId() == _currentCall.value.outputDevice.value!);
        selected += 1;
        var deviceId = outputs[(selected) % outputs.length].deviceId();
        speakerSwitched.value = deviceId == 'speakerphone';
        await _currentCall.value.setOutputDevice(deviceId);
      }
    } else {
      // TODO: Ensure `flutter_webrtc` supports iOS and Web output device
      //       switching.
      speakerSwitched.toggle();
    }
  }

  /// Raises/lowers a hand.
  Future<void> toggleHand() async {
    keepUi();
    isHandRaised.toggle();
    _putParticipant(RemoteMemberId(me, null), handRaised: isHandRaised.value);
    await _toggleHand();
  }

  /// Toggles the [displayMore].
  void toggleMore() => displayMore.toggle();

  /// Invokes a [CallService.toggleHand] if the [_toggleHandGuard] is not
  /// locked.
  Future<void> _toggleHand() async {
    if (!_toggleHandGuard.isLocked) {
      var raised = isHandRaised.value;
      await _toggleHandGuard.protect(() async {
        await _calls.toggleHand(chatId, raised);
      });

      if (raised != isHandRaised.value) {
        _toggleHand();
      }
    }
  }

  /// Toggles fullscreen on and off.
  Future<void> toggleFullscreen() async {
    if (fullscreen.isTrue) {
      fullscreen.value = false;
      await PlatformUtils.exitFullscreen();
    } else {
      fullscreen.value = true;
      await PlatformUtils.enterFullscreen();
    }

    relocateSecondary();
  }

  /// Toggles inbound video in the current [OngoingCall] on and off.
  Future<void> toggleRemoteVideos() => _currentCall.value.toggleRemoteVideo();

  /// Toggles inbound audio in the current [OngoingCall] on and off.
  Future<void> toggleRemoteAudios() => _currentCall.value.toggleRemoteAudio();

  /// Toggles the provided [renderer]'s enabled status on and off.
  Future<void> toggleRendererEnabled(Rx<RtcVideoRenderer?> renderer) async {
    if (renderer.value != null) {
      await renderer.value!.setEnabled(!renderer.value!.isEnabled);
      renderer.refresh();
    }
  }

  /// Keeps UI open for some amount of time and then hides it if [enabled] is
  /// `null`, otherwise toggles its state immediately to [enabled].
  void keepUi([bool? enabled]) {
    _uiTimer?.cancel();
    showUi.value = isPanelOpen.value || (enabled ?? true);
    showHeader.value = (enabled ?? true);

    if (state.value == OngoingCallState.active &&
        enabled == null &&
        !isPanelOpen.value) {
      _uiTimer = Timer(
        const Duration(seconds: _uiDuration),
        () {
          showUi.value = false;
          showHeader.value = false;
        },
      );
    }
  }

  /// Returns a [Participant] identified by an [id] and a [source].
  Participant? findParticipant(RemoteMemberId id, MediaSourceKind source) {
    return locals.firstWhereOrNull((e) => e.id == id && e.source == source) ??
        remotes.firstWhereOrNull((e) => e.id == id && e.source == source) ??
        paneled.firstWhereOrNull((e) => e.id == id && e.source == source) ??
        focused.firstWhereOrNull((e) => e.id == id && e.source == source);
  }

  /// Centers the [participant], which means [focus]ing the [participant] and
  /// [unfocus]ing every participant in [focused].
  void center(Participant participant) {
    if (participant.owner == MediaOwnerKind.local &&
        participant.source == MediaSourceKind.Display) {
      // Movement of a local [MediaSourceKind.Display] is prohibited.
      return;
    }

    paneled.remove(participant);
    locals.remove(participant);
    remotes.remove(participant);
    focused.remove(participant);

    for (Participant r in List.from(focused, growable: false)) {
      _putVideoFrom(r, focused);
    }
    focused.add(participant);
    _insureCorrectGrouping();
  }

  /// Focuses [participant], which means putting in to the [focused].
  ///
  /// If [participant] is [paneled], then it will be placed to the [focused] if
  /// it's not empty, or to its `default` group otherwise.
  void focus(Participant participant) {
    if (participant.owner == MediaOwnerKind.local &&
        participant.source == MediaSourceKind.Display) {
      // Movement of a local [MediaSourceKind.Display] is prohibited.
      return;
    }

    if (focused.isNotEmpty) {
      if (paneled.contains(participant)) {
        focused.add(participant);
        paneled.remove(participant);
      } else {
        _putVideoTo(participant, focused);
      }
      _insureCorrectGrouping();
    } else {
      if (paneled.contains(participant)) {
        _putVideoFrom(participant, paneled);
        _insureCorrectGrouping();
      }
    }
  }

  /// Unfocuses [participant], which means putting it in its `default` group.
  void unfocus(Participant participant) {
    if (participant.owner == MediaOwnerKind.local &&
        participant.source == MediaSourceKind.Display) {
      // Movement of a local [MediaSourceKind.Display] is prohibited.
      return;
    }

    if (focused.contains(participant)) {
      _putVideoFrom(participant, focused);
      if (focused.isEmpty) {
        unfocusAll();
      }
      _insureCorrectGrouping();
    } else {
      if (!paneled.contains(participant)) {
        _putVideoTo(participant, paneled);
        _insureCorrectGrouping();
      }
    }
  }

  /// [focus]es all [Participant]s, which means putting them in theirs `default`
  /// groups.
  void focusAll() {
    for (Participant r in List.from(paneled, growable: false)) {
      _putVideoFrom(r, paneled);
    }

    for (Participant r in List.from(focused, growable: false)) {
      _putVideoFrom(r, focused);
    }

    _insureCorrectGrouping();
  }

  /// [unfocus]es all [Participant]s, which means putting them in the [paneled]
  /// group.
  void unfocusAll() {
    for (Participant r
        in List.from([...focused, ...locals, ...remotes], growable: false)) {
      _putVideoTo(r, paneled);
    }

    _insureCorrectGrouping();
  }

  /// Minimizes the view.
  void minimize() {
    if (isMobile) {
      minimizedAnimation?.forward(from: minimizedAnimation?.value);
      if (panelController.isAttached) {
        panelController.close();
      }
    } else {
      minimized.value = true;
    }
  }

  /// Maximizes the view.
  void maximize() {
    if (isMobile) {
      minimizedAnimation?.reverse(from: minimizedAnimation?.value);
      if (panelController.isAttached) {
        panelController.close();
      }
    } else {
      minimized.value = false;
    }
  }

  /// Returns a result of [showDialog] that builds [CallSettingsView].
  Future<dynamic> openSettings(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => CallSettingsView(
        _currentCall,
        lmbValue: handleLmb.value,
        onLmbChanged: (b) {
          lmbTimeout = 7;
          handleLmb.value = b ?? false;
        },
        panelValue: panelUp.value,
        onPanelChanged: (b) => panelUp.value = b ?? false,
      ),
    );
  }

  /// Returns a result of the [showDialog] building an [AddChatMemberView] or an
  /// [AddDialogMemberView].
  Future<dynamic> openAddMember(BuildContext context) {
    keepUi(false);
    return ModalPopup.show(
      context: context,
      child: ParticipantView(_currentCall, duration),
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      mobilePadding: const EdgeInsets.all(0),
    );

    // if (isGroup) {
    //   return showDialog(
    //     context: context,
    //     builder: (_) => AddChatMemberView(chat.value!.chat.value.id),
    //   );
    // } else if (isDialog) {
    //   return showDialog(
    //     context: context,
    //     builder: (_) =>
    //         AddDialogMemberView(chat.value!.chat.value.id, _currentCall),
    //   );
    // }

    return Future.value();
  }

  /// Returns an [User] from the [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Applies constraints to the [width], [height], [left] and [top].
  void applyConstraints(BuildContext context) {
    width.value = _applyWidth(context, width.value);
    height.value = _applyHeight(context, height.value);
    left.value = _applyLeft(context, left.value);
    top.value = _applyTop(context, top.value);
  }

  /// Relocates the secondary view accounting the possible intersections.
  void relocateSecondary() {
    if (secondaryAlignment.value == null &&
        secondaryDragged.isFalse &&
        secondaryScaled.isFalse &&
        !_secondaryRelocated) {
      _secondaryRelocated = true;

      final Rect? secondaryBounds = secondaryKey.globalPaintBounds;
      final Rect? dockBounds = dockKey.globalPaintBounds;
      Rect intersect =
          secondaryBounds?.intersect(dockBounds ?? Rect.zero) ?? Rect.zero;

      intersect = Rect.fromLTWH(
        intersect.left,
        intersect.top,
        intersect.width,
        intersect.height + 10,
      );

      if (intersect.width > 0 && intersect.height > 0) {
        // Intersection is non-zero, so move the secondary panel up.
        if (secondaryBottom.value != null) {
          secondaryBottom.value = secondaryBottom.value! + intersect.height;
        } else {
          secondaryTop.value = secondaryTop.value! - intersect.height;
        }

        applySecondaryConstraints();
      } else if ((intersect.height < 0 || intersect.width < 0) &&
          secondaryBottomShifted != null) {
        // Intersection is less than zero and the secondary panel is higher than
        // it was before, so move it to its original position.
        double bottom = secondaryBottom.value ??
            size.height - secondaryTop.value! - secondaryHeight.value;
        if (bottom > secondaryBottomShifted!) {
          double difference = bottom - secondaryBottomShifted!;
          if (secondaryBottom.value != null) {
            if (difference.abs() < intersect.height.abs() ||
                intersect.width < 0) {
              secondaryBottom.value = secondaryBottomShifted;
            } else {
              secondaryBottom.value = secondaryBottom.value! + intersect.height;
            }
          } else {
            if (difference.abs() < intersect.height.abs() ||
                intersect.width < 0) {
              secondaryTop.value =
                  size.height - secondaryHeight.value - secondaryBottomShifted!;
            } else {
              secondaryTop.value = secondaryTop.value! - intersect.height;
            }
          }

          applySecondaryConstraints();
        }
      }

      SchedulerBinding.instance
          .addPostFrameCallback((_) => _secondaryRelocated = false);
    }
  }

  /// Calculates the appropriate [secondaryLeft], [secondaryRight],
  /// [secondaryTop] and [secondaryBottom] values according to the nearest edge.
  void updateSecondaryAttach() {
    secondaryLeft.value ??=
        size.width - secondaryWidth.value - (secondaryRight.value ?? 0);
    secondaryTop.value ??=
        size.height - secondaryHeight.value - (secondaryBottom.value ?? 0);

    List<MapEntry<Alignment, double>> alignments = [
      MapEntry(
        Alignment.topLeft,
        Point(
          secondaryLeft.value!,
          secondaryTop.value!,
        ).squaredDistanceTo(const Point(0, 0)),
      ),
      MapEntry(
        Alignment.topRight,
        Point(
          secondaryLeft.value! + secondaryWidth.value,
          secondaryTop.value!,
        ).squaredDistanceTo(Point(size.width, 0)),
      ),
      MapEntry(
        Alignment.bottomLeft,
        Point(
          secondaryLeft.value!,
          secondaryTop.value! + secondaryHeight.value,
        ).squaredDistanceTo(Point(0, size.height)),
      ),
      MapEntry(
        Alignment.bottomRight,
        Point(
          secondaryLeft.value! + secondaryWidth.value,
          secondaryTop.value! + secondaryHeight.value,
        ).squaredDistanceTo(Point(size.width, size.height)),
      ),
    ]..sort((e1, e2) => e1.value.compareTo(e2.value));

    Alignment align = alignments.first.key;
    double left = secondaryLeft.value!;
    double top = secondaryTop.value!;

    secondaryTop.value = null;
    secondaryLeft.value = null;
    secondaryRight.value = null;
    secondaryBottom.value = null;

    if (align == Alignment.topLeft) {
      secondaryTop.value = top;
      secondaryLeft.value = left;
    } else if (align == Alignment.topRight) {
      secondaryTop.value = top;
      secondaryRight.value = secondaryWidth.value + left <= size.width
          ? secondaryRight.value = size.width - left - secondaryWidth.value
          : 0;
    } else if (align == Alignment.bottomLeft) {
      secondaryLeft.value = left;
      secondaryBottom.value = top + secondaryHeight.value <= size.height
          ? size.height - top - secondaryHeight.value
          : 0;
    } else if (align == Alignment.bottomRight) {
      secondaryRight.value = secondaryWidth.value + left <= size.width
          ? size.width - left - secondaryWidth.value
          : 0;
      secondaryBottom.value = top + secondaryHeight.value <= size.height
          ? size.height - top - secondaryHeight.value
          : 0;
    }

    secondaryBottomShifted =
        secondaryBottom.value ?? size.height - top - secondaryHeight.value;
    relocateSecondary();
  }

  /// Calculates the [secondaryPanningOffset] based on the provided [offset].
  void calculateSecondaryPanning(Offset offset) {
    Offset position =
        (secondaryKey.currentContext?.findRenderObject() as RenderBox?)
                ?.localToGlobal(Offset.zero) ??
            Offset.zero;

    if (secondaryAlignment.value == Alignment.centerRight ||
        secondaryAlignment.value == Alignment.centerLeft ||
        secondaryAlignment.value == null) {
      secondaryPanningOffset = Offset(
        offset.dx - position.dx,
        offset.dy - position.dy,
      );
    } else if (secondaryAlignment.value == Alignment.bottomCenter ||
        secondaryAlignment.value == Alignment.topCenter) {
      secondaryPanningOffset = Offset(
        secondaryWidth.value / 2,
        offset.dy - position.dy,
      );
    }
  }

  /// Sets the [secondaryLeft] and [secondaryTop] correctly to the provided
  /// [offset].
  void updateSecondaryOffset(Offset offset) {
    if (fullscreen.isTrue) {
      secondaryLeft.value = offset.dx - secondaryPanningOffset!.dx;
      secondaryTop.value = offset.dy -
          ((WebUtils.isPopup || router.context!.isMobile) ? 0 : titleHeight) -
          secondaryPanningOffset!.dy;
    } else if (WebUtils.isPopup) {
      secondaryLeft.value = offset.dx - secondaryPanningOffset!.dx;
      secondaryTop.value = offset.dy - secondaryPanningOffset!.dy;
    } else {
      secondaryLeft.value = offset.dx -
          (router.context!.isMobile ? 0 : left.value) -
          secondaryPanningOffset!.dx;
      secondaryTop.value = offset.dy -
          (router.context!.isMobile ? 0 : top.value + titleHeight) -
          secondaryPanningOffset!.dy;
    }

    if (secondaryLeft.value! < 0) {
      secondaryLeft.value = 0;
    }

    if (secondaryTop.value! < 0) {
      secondaryTop.value = 0;
    }
  }

  /// Applies constraints to the [secondaryWidth], [secondaryHeight],
  /// [secondaryLeft] and [secondaryTop].
  void applySecondaryConstraints() {
    if (secondaryAlignment.value == Alignment.centerRight ||
        secondaryAlignment.value == Alignment.centerLeft) {
      secondaryLeft.value = size.width / 2;
    } else if (secondaryAlignment.value == Alignment.topCenter ||
        secondaryAlignment.value == Alignment.bottomCenter) {
      secondaryTop.value = size.height / 2;
    }

    secondaryWidth.value = _applySWidth(secondaryWidth.value);
    secondaryHeight.value = _applySHeight(secondaryHeight.value);
    secondaryLeft.value = _applySLeft(secondaryLeft.value);
    secondaryRight.value = _applySRight(secondaryRight.value);
    secondaryTop.value = _applySTop(secondaryTop.value);
    secondaryBottom.value = _applySBottom(secondaryBottom.value);

    // Limit the width and height if docked.
    if (secondaryAlignment.value == Alignment.centerRight ||
        secondaryAlignment.value == Alignment.centerLeft) {
      secondaryWidth.value = min(secondaryWidth.value, size.width / 2);
    } else if (secondaryAlignment.value == Alignment.topCenter ||
        secondaryAlignment.value == Alignment.bottomCenter) {
      secondaryHeight.value = min(secondaryHeight.value, size.height / 2);
    }

    // Determine the [possibleSecondaryAlignment].
    possibleSecondaryAlignment.value = null;
    if (secondaryDragged.value) {
      if (secondaryLeft.value != null) {
        if (secondaryLeft.value! <= 0) {
          possibleSecondaryAlignment.value = Alignment.centerLeft;
        } else if (secondaryLeft.value! >= size.width - secondaryWidth.value) {
          possibleSecondaryAlignment.value = Alignment.centerRight;
        }
      }

      if (secondaryTop.value != null) {
        if (secondaryTop.value! <= 0) {
          possibleSecondaryAlignment.value = Alignment.topCenter;
        } else if (secondaryTop.value! >= size.height - secondaryHeight.value) {
          possibleSecondaryAlignment.value = Alignment.bottomCenter;
        }
      }
    }
  }

  /// Resizes the minimized view along [x] by [dx] and/or [y] by [dy] axis.
  void resize(BuildContext context,
      {ScaleModeY? y, ScaleModeX? x, double? dx, double? dy}) {
    switch (x) {
      case ScaleModeX.left:
        double w = _applyWidth(context, width.value - dx!);
        if (width.value - dx == w) {
          double l = _applyLeft(context, left.value + (width.value - w));
          if (left.value + (width.value - w) == l) {
            left.value = l;
            width.value = w;
          } else if (l == context.mediaQuerySize.width - width.value) {
            left.value = context.mediaQuerySize.width - w;
            width.value = w;
          }
        }
        break;
      case ScaleModeX.right:
        double w = _applyWidth(context, width.value - dx!);
        if (width.value - dx == w) {
          double r = left.value + w;
          if (r < context.mediaQuerySize.width) {
            width.value = w;
          }
        }
        break;
      default:
        break;
    }

    switch (y) {
      case ScaleModeY.top:
        double h = _applyHeight(context, height.value - dy!);
        if (height.value - dy == h) {
          double t = _applyTop(context, top.value + (height.value - h));
          if (top.value + (height.value - h) == t) {
            top.value = t;
            height.value = h;
          } else if (t == context.mediaQuerySize.height - height.value) {
            top.value = context.mediaQuerySize.height - h;
            height.value = h;
          }
        }
        break;
      case ScaleModeY.bottom:
        double h = _applyHeight(context, height.value - dy!);
        if (height.value - dy == h) {
          double b = top.value + h;
          if (b < context.mediaQuerySize.height) {
            height.value = h;
          }
        }
        break;
      default:
        break;
    }

    applySecondaryConstraints();
  }

  /// Resizes the secondary view along [x] by [dx] and/or [y] by [dy] axis.
  void resizeSecondary(BuildContext context,
      {ScaleModeY? y, ScaleModeX? x, double? dx, double? dy}) {
    secondaryLeft.value ??=
        size.width - secondaryWidth.value - (secondaryRight.value ?? 0);
    secondaryTop.value ??=
        size.height - secondaryHeight.value - (secondaryBottom.value ?? 0);
    secondaryBottom.value = null;
    secondaryRight.value = null;

    switch (x) {
      case ScaleModeX.left:
        double width = _applySWidth(secondaryWidth.value - dx!);
        if (secondaryWidth.value - dx == width) {
          double? left = _applySLeft(
            secondaryLeft.value! + (secondaryWidth.value - width),
          );

          if (secondaryLeft.value! + (secondaryWidth.value - width) == left) {
            secondaryLeft.value = left;
            secondaryWidth.value = width;
          } else if (left == size.width - secondaryWidth.value) {
            secondaryLeft.value = size.width - width;
            secondaryWidth.value = width;
          }
        }
        break;

      case ScaleModeX.right:
        double width = _applySWidth(secondaryWidth.value - dx!);
        if (secondaryWidth.value - dx == width) {
          double right = secondaryLeft.value! + width;
          if (right < size.width) {
            secondaryWidth.value = width;
          }
        }
        break;

      default:
        break;
    }

    switch (y) {
      case ScaleModeY.top:
        double height = _applySHeight(secondaryHeight.value - dy!);
        if (secondaryHeight.value - dy == height) {
          double? top = _applySTop(
            secondaryTop.value! + (secondaryHeight.value - height),
          );

          if (secondaryTop.value! + (secondaryHeight.value - height) == top) {
            secondaryTop.value = top;
            secondaryHeight.value = height;
          } else if (top == size.height - secondaryHeight.value) {
            secondaryTop.value = size.height - height;
            secondaryHeight.value = height;
          }
        }
        break;

      case ScaleModeY.bottom:
        double height = _applySHeight(secondaryHeight.value - dy!);
        if (secondaryHeight.value - dy == height) {
          double bottom = secondaryTop.value! + height;
          if (bottom < size.height) {
            secondaryHeight.value = height;
          }
        }
        break;

      default:
        break;
    }

    applySecondaryConstraints();
  }

  /// Scales the secondary view by the provided [scale].
  void scaleSecondary(double scale) {
    _scaleSWidth(scale);
    _scaleSHeight(scale);
  }

  /// Scales the [secondaryWidth] according to the provided [scale].
  void _scaleSWidth(double scale) {
    double width = _applySWidth(secondaryUnscaledSize! * scale);
    if (width != secondaryWidth.value) {
      double widthDifference = width - secondaryWidth.value;
      secondaryWidth.value = width;
      secondaryLeft.value =
          _applySLeft(secondaryLeft.value! - widthDifference / 2);
      secondaryPanningOffset =
          secondaryPanningOffset?.translate(widthDifference / 2, 0);
    }
  }

  /// Scales the [secondaryHeight] according to the provided [scale].
  void _scaleSHeight(double scale) {
    double height = _applySHeight(secondaryUnscaledSize! * scale);
    if (height != secondaryHeight.value) {
      double heightDifference = height - secondaryHeight.value;
      secondaryHeight.value = height;
      secondaryTop.value =
          _applySTop(secondaryTop.value! - heightDifference / 2);
      secondaryPanningOffset =
          secondaryPanningOffset?.translate(0, heightDifference / 2);
    }
  }

  /// Returns corrected according to secondary constraints [width] value.
  double _applySWidth(double width) {
    if (_minSWidth > size.width * _maxSWidth) {
      return size.width * _maxSWidth;
    } else if (width > size.width * _maxSWidth) {
      return (size.width * _maxSWidth);
    } else if (width < _minSWidth) {
      return _minSWidth;
    }
    return width;
  }

  /// Returns corrected according to secondary constraints [height] value.
  double _applySHeight(double height) {
    if (_minSHeight > size.height * _maxSHeight) {
      return size.height * _maxSHeight;
    } else if (height > size.height * _maxSHeight) {
      return size.height * _maxSHeight;
    } else if (height < _minSHeight) {
      return _minSHeight;
    }
    return height;
  }

  /// Returns corrected according to secondary constraints [left] value.
  double? _applySLeft(double? left) {
    if (left != null) {
      if (left + secondaryWidth.value > size.width) {
        return size.width - secondaryWidth.value;
      } else if (left < 0) {
        return 0;
      }
    }

    return left;
  }

  /// Returns corrected according to secondary constraints [right] value.
  double? _applySRight(double? right) {
    if (right != null) {
      if (right + secondaryWidth.value > size.width) {
        return size.width - secondaryWidth.value;
      } else if (right < 0) {
        return 0;
      }
    }

    return right;
  }

  /// Returns corrected according to secondary constraints [top] value.
  double? _applySTop(double? top) {
    if (top != null) {
      if (top + secondaryHeight.value > size.height) {
        return size.height - secondaryHeight.value;
      } else if (top < 0) {
        return 0;
      }
    }

    return top;
  }

  /// Returns corrected according to secondary constraints [bottom] value.
  double? _applySBottom(double? bottom) {
    if (bottom != null) {
      if (bottom + secondaryHeight.value > size.height) {
        return size.height - secondaryHeight.value;
      } else if (bottom < 0) {
        return 0;
      }
    }

    return bottom;
  }

  /// Returns corrected according to constraints [width] value.
  double _applyWidth(BuildContext context, double width) {
    if (_minWidth > context.mediaQuerySize.width * _maxWidth) {
      return context.mediaQuerySize.width * _maxWidth;
    } else if (width > context.mediaQuerySize.width * _maxWidth) {
      return (context.mediaQuerySize.width * _maxWidth);
    } else if (width < _minWidth) {
      return _minWidth;
    }
    return width;
  }

  /// Returns corrected according to constraints [height] value.
  double _applyHeight(BuildContext context, double height) {
    if (_minHeight > context.mediaQuerySize.height * _maxHeight) {
      return context.mediaQuerySize.height * _maxHeight;
    } else if (height > context.mediaQuerySize.height * _maxHeight) {
      return context.mediaQuerySize.height * _maxHeight;
    } else if (height < _minHeight) {
      return _minHeight;
    }
    return height;
  }

  /// Returns corrected according to constraints [left] value.
  double _applyLeft(BuildContext context, double left) {
    if (left + width.value > context.mediaQuerySize.width) {
      return context.mediaQuerySize.width - width.value;
    } else if (left < 0) {
      return 0;
    }
    return left;
  }

  /// Returns corrected according to constraints [top] value.
  double _applyTop(BuildContext context, double top) {
    if (top + height.value > context.mediaQuerySize.height) {
      return context.mediaQuerySize.height - height.value;
    } else if (top < 0) {
      return 0;
    }
    return top;
  }

  /// Puts [participant] from its `default` group to [list].
  void _putVideoTo(Participant participant, RxList<Participant> list) {
    if (participant.owner == MediaOwnerKind.local &&
        participant.source == MediaSourceKind.Display) {
      // Movement of a local [MediaSourceKind.Display] is prohibited.
      return;
    }

    locals.remove(participant);
    remotes.remove(participant);
    focused.remove(participant);
    paneled.remove(participant);
    list.add(participant);
  }

  /// Puts [participant] from [list] to its `default` group.
  void _putVideoFrom(Participant participant, RxList<Participant> list) {
    switch (participant.owner) {
      case MediaOwnerKind.local:
        // Movement of [MediaSourceKind.Display] to [locals] is prohibited.
        if (participant.source == MediaSourceKind.Display) {
          break;
        }

        locals.addIf(!locals.contains(participant), participant);
        list.remove(participant);
        break;

      case MediaOwnerKind.remote:
        remotes.addIf(!remotes.contains(participant), participant);
        list.remove(participant);
        break;
    }
  }

  /// Insures the [paneled] and [focused] are in correct state, and fixes the
  /// state if not.
  void _insureCorrectGrouping() {
    if (locals.isEmpty && remotes.isEmpty) {
      // If every [RtcVideoRenderer] is in focus, then put everyone outside of
      // it.
      if (paneled.isEmpty && focused.isNotEmpty) {
        List<Participant> copy = List.from(focused, growable: false);
        for (Participant r in copy) {
          _putVideoFrom(r, focused);
        }
      }
    }

    locals.refresh();
    remotes.refresh();
    paneled.refresh();
    focused.refresh();

    primary.value = focused.isNotEmpty ? focused : [...locals, ...remotes];
    secondary.value =
        focused.isNotEmpty ? [...locals, ...paneled, ...remotes] : paneled;
  }

  /// Returns all [Participant]s identified by an [id].
  Iterable<Participant> _findParticipants(RemoteMemberId id) {
    return [
      ...locals.where((e) => e.id == id),
      ...remotes.where((e) => e.id == id),
      ...paneled.where((e) => e.id == id),
      ...focused.where((e) => e.id == id),
    ];
  }

  /// Puts a [video] and/or [audio] renderers to [Participant] identified by an
  /// [id] with the same [MediaSourceKind] as a [video] or [audio].
  ///
  /// Defaults to [MediaSourceKind.Device] if no [video] and [audio] is
  /// provided.
  ///
  /// Creates a new [Participant] if it doesn't exist.
  void _putParticipant(
    RemoteMemberId id, {
    RtcVideoRenderer? video,
    RtcAudioRenderer? audio,
    bool? handRaised,
  }) {
    Participant? participant = findParticipant(
      id,
      video?.source ?? audio?.source ?? MediaSourceKind.Device,
    );

    if (participant == null) {
      MediaOwnerKind owner;

      if (id.userId == me && id.deviceId == null) {
        owner = MediaOwnerKind.local;
      } else {
        owner = MediaOwnerKind.remote;
      }

      participant = Participant(
        id,
        owner,
        video: video,
        audio: audio,
        handRaised: handRaised,
      );

      _userService
          .get(id.userId)
          .then((u) => participant?.user.value = u ?? participant.user.value);

      switch (owner) {
        case MediaOwnerKind.local:
          if (isGroup) {
            switch (participant.source) {
              case MediaSourceKind.Device:
                locals.add(participant);
                break;

              case MediaSourceKind.Display:
                paneled.add(participant);
                break;
            }
          } else {
            paneled.add(participant);
          }
          break;

        case MediaOwnerKind.remote:
          switch (participant.source) {
            case MediaSourceKind.Device:
              remotes.add(participant);
              break;

            case MediaSourceKind.Display:
              focused.add(participant);
              break;
          }
          break;
      }
    } else {
      participant.audio.value = audio ?? participant.audio.value;
      participant.video.value = video ?? participant.video.value;
      participant.handRaised.value = handRaised ?? participant.handRaised.value;
    }
  }

  /// Removes [video] and/or [audio] renderers from [Participant] identified by
  /// an [id].
  ///
  /// Removes the specified [Participant] from a corresponding list if it is
  /// [MediaSourceKind.Display] and has no non-`null` renderers.
  void _removeParticipant(
    RemoteMemberId id, {
    RtcVideoRenderer? video,
    RtcAudioRenderer? audio,
  }) {
    for (var participant in _findParticipants(id)) {
      if (participant.audio.value == audio) {
        participant.audio.value = null;
      }

      if (participant.video.value == video) {
        participant.video.value = null;
      }

      if (participant.source == MediaSourceKind.Display &&
          participant.video.value == null &&
          participant.audio.value == null) {
        locals.remove(participant);
        remotes.remove(participant);
        paneled.remove(participant);
        focused.remove(participant);
      }
    }
  }
}

/// X-axis scale mode.
enum ScaleModeX { left, right }

/// Y-axis scale mode.
enum ScaleModeY { top, bottom }

/// Separate call entity participating in a call.
class Participant {
  Participant(
    this.id,
    this.owner, {
    RxUser? user,
    RtcVideoRenderer? video,
    RtcAudioRenderer? audio,
    bool? handRaised,
  })  : video = Rx(video),
        audio = Rx(audio),
        handRaised = Rx(handRaised ?? false),
        user = Rx(user),
        source = video?.source ?? audio?.source ?? MediaSourceKind.Device;

  /// [RemoteMemberId] of the [User] this [Participant] represents.
  final RemoteMemberId id;

  /// [User] this [Participant] represents.
  final Rx<RxUser?> user;

  /// Indicator whether this [Participant] raised a hand.
  final Rx<bool> handRaised;

  /// Media ownership kind of this [Participant].
  final MediaOwnerKind owner;

  /// Media source kind of this [Participant].
  final MediaSourceKind source;

  /// Reactive video renderer of this [Participant].
  late final Rx<RtcVideoRenderer?> video;

  /// Reactive audio renderer of this [Participant].
  late final Rx<RtcAudioRenderer?> audio;

  /// [GlobalKey] of this [Participant]'s [VideoView].
  final GlobalKey videoKey = GlobalKey();
}
