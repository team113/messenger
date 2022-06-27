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
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:mutex/mutex.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/routes.dart';
import '/ui/page/call/add_dialog_member/controller.dart';
import '/ui/page/home/page/chat/info/add_member/view.dart';
import '/ui/widget/context_menu/overlay.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
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

  /// Local [Participant]s in `default` mode.
  final RxList<Participant> locals = RxList([]);

  /// Remote [Participant]s in `default` mode.
  final RxList<Participant> remotes = RxList([]);

  /// [Participant]s in `focus` mode.
  final RxList<Participant> focused = RxList([]);

  /// [Participant]s in `panel` mode.
  final RxList<Participant> paneled = RxList([]);

  /// [Participant] that should be highlighted over the others.
  final Rx<Participant?> highlighted = Rx(null);

  /// Indicator whether the view is mobile or desktop.
  late bool isMobile;

  /// Count of a currently happening drags of the secondary videos used to
  /// determine if any drag happened at all.
  RxInt secondaryDrags = RxInt(0);

  /// Count of a currently happening drags of the primary videos used to
  /// determine if any drag happened at all and to display secondary view hint.
  final RxInt primaryDrags = RxInt(0);

  /// Indicator whether the camera was switched or not.
  final RxBool cameraSwitched = RxBool(false);

  /// Indicator whether the speaker was switched or not.
  final RxBool speakerSwitched = RxBool(true);

  /// Temporary indicator whether the hand was raised or not.
  final RxBool isHandRaised = RxBool(false);

  /// Indicator whether the buttons panel is open or not.
  final RxBool isPanelOpen = RxBool(false);

  /// Indicator whether the title bar panel is shown or not.
  final RxBool isTitleBarShown = RxBool(false);

  /// Indicator whether the hint is dismissed or not.
  final RxBool isHintDismissed = RxBool(false);

  /// Indicator whether the cursor should be hidden or not.
  final RxBool isCursorHidden = RxBool(false);

  /// Indicator whether the [SlidingUpPanel] is on screen or not.
  final RxBool isSlidingPanelEnabled = RxBool(false);

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

  /// [GlobalKey] of a self view used in [applySelfConstraints].
  final GlobalKey selfKey = GlobalKey();

  /// Minimized self view right offset.
  final Rx<double> selfRight = Rx<double>(10);

  /// Minimized self view bottom offset.
  final Rx<double> selfBottom = Rx<double>(10);

  /// Indicator whether the minimized self view is being panned or not.
  final RxBool isSelfPanning = RxBool(false);

  /// Indicator whether need to show hints to [CallButton]'s or not.
  final RxBool hideHint = RxBool(false);

  /// Indicator whether need to show bottom ui.
  final RxBool showBottomUi = RxBool(true);

  /// Indicator whether button is dragging now.
  final RxBool isDraggingNow = RxBool(false);

  /// Indicator whether the more hint is dismissed or not.
  final RxBool isMoreHintDismissed = RxBool(false);

  /// Currently draggable [CallButton].
  final Rx<CallButton?> draggableButton = Rx(null);

  /// Buttons width and height.
  final RxDouble buttonSize = RxDouble(48);

  /// [GlobalKey] of buttons panel.
  final GlobalKey buttonsPanelKey = GlobalKey();

  /// Indicator whether need to display more panel.
  final RxBool displayMore = RxBool(false);

  /// Indicator whether more panel was displayed before user start dragging
  /// buttons.
  final RxBool morePanelBeforeStartDrag = RxBool(false);

  /// List of top panel [CallButton]'s.
  late final RxList<CallButton> panel;

  /// List of bottom panel [CallButton]'s.
  late final RxList<CallButton> buttons;

  /// [Worker] for catching the changes of [showBottomUi].
  late final Worker _showBottomUiWorker;

  /// [Timer] of bottom ui.
  Timer? _uiBottomTimer;

  /// [AnimationController] of a [MinimizableView] used to change the
  /// [minimized] value.
  AnimationController? minimizedAnimation;

  /// View padding of the screen.
  EdgeInsets padding = EdgeInsets.zero;

  /// Color of a call buttons that accept the call.
  static const Color acceptColor = Color(0x7F34B139);

  /// Color of a call buttons that end the call.
  static const Color endColor = Color(0x7FFF0000);

  /// Max width of the minimized view in percentage of the screen width.
  static const double _maxWidth = 0.99;

  /// Max height of the minimized view in percentage of the screen height.
  static const double _maxHeight = 0.99;

  /// Min width of the minimized view in pixels.
  static const double _minWidth = 500;

  /// Min height of the minimized view in pixels.
  static const double _minHeight = 500;

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
  final Map<String, BoxFit?> rendererBoxFit = <String, BoxFit?>{};

  /// [Worker] for catching the [state] changes to start the [_durationTimer].
  late final Worker _stateWorker;

  /// [Worker] for catching the [isSlidingPanelEnabled] changes to correct the
  /// position of a minimized self view.
  late final Worker _panelWorker;

  /// Subscription for [OngoingCall.localVideos] changes.
  late final StreamSubscription _localsSubscription;

  /// Subscription for [OngoingCall.remoteVideos] changes.
  late final StreamSubscription _remotesSubscription;

  /// Subscription for [OngoingCall.remoteAudios] changes.
  late final StreamSubscription _audiosSubscription;

  /// Subscription for [OngoingCall.members] changes.
  late final StreamSubscription _membersSubscription;

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
  Size get size => !fullscreen.value && minimized.value
      ? Size(width.value, height.value)
      : router.context!.mediaQuerySize;

  /// Indicates whether the [chat] is a dialog.
  bool get isDialog => chat.value?.chat.value.isDialog ?? false;

  /// Indicates whether the [chat] is a group.
  bool get isGroup => chat.value?.chat.value.isGroup ?? false;

  /// Indicator whether the inbound video in the current [OngoingCall] is
  /// enabled or not.
  RxBool get isRemoteVideoEnabled => _currentCall.value.isRemoteVideoEnabled;

  /// Indicator whether the inbound audio in the current [OngoingCall] is
  /// enabled or not.
  RxBool get isRemoteAudioEnabled => _currentCall.value.isRemoteAudioEnabled;

  @override
  void onInit() {
    super.onInit();

    _currentCall.value.init(_chatService.me);

    Size size = router.context!.mediaQuerySize;

    fullscreen = RxBool(false);
    minimized = RxBool(!router.context!.isMobile);
    isMobile = router.context!.isMobile;

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
    left = size.width - width.value - 50 > 0
        ? RxDouble(size.width - width.value - 50)
        : RxDouble(size.width / 2 - width.value / 2);
    top = height.value + 50 < size.height
        ? RxDouble(50)
        : RxDouble(size.height / 2 - height.value / 2);

    _panelWorker = ever(isSlidingPanelEnabled, (bool b) {
      if (b && selfBottom.value < 140) {
        selfBottom.value = 140;
      } else if (!b && selfBottom.value <= 150) {
        selfBottom.value = 10;
      }
    });

    _chatService
        .get(_currentCall.value.chatId.value)
        .then((v) => chat.value = v);

    _chatWorker = ever(
      _currentCall.value.chatId,
      (ChatId id) => _chatService.get(id).then((v) => chat.value = v),
    );

    _stateWorker = ever(state, (OngoingCallState state) {
      if (state == OngoingCallState.active && _durationTimer == null) {
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
    });

    _onFullscreenChange = PlatformUtils.onFullscreenChange
        .listen((bool v) => fullscreen.value = v);

    _errorsSubscription = _currentCall.value.errors.listen((e) {
      error.value = e;
      errorTimeout.value = _errorDuration;
    });

    _putParticipant(RemoteMemberId(me, null), handRaised: false);

    buttons = RxList([
      ScreenCallButton(this),
      VideoCallButton(this),
      EndCallButton(this),
      AudioCallButton(this),
      MoreCallButton(this),
    ]);

    panel = RxList([
      SettingsCallButton(this),
      AddMemberCallButton(this),
      HandCallButton(this),
      ScreenCallButton(this),
      DisableRemoteVideoCallButton(this),
      DisableRemoteAudioCallButton(this),
      VideoCallButton(this),
      AudioCallButton(this),
    ]);

    _showBottomUiWorker = ever(showBottomUi, (bool v) {
      if (displayMore.value && !v) {
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
          paneled.removeWhere((m) => m.id == e.key);
          locals.removeWhere((m) => m.id == e.key);
          focused.removeWhere((m) => m.id == e.key);
          remotes.removeWhere((m) => m.id == e.key);
          _insureCorrectGrouping();

          if (highlighted.value?.id == e.key) {
            highlighted.value = null;
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
    _uiBottomTimer?.cancel();
    _showBottomUiWorker.dispose();
    _uiTimer?.cancel();
    _stateWorker.dispose();
    _panelWorker.dispose();
    _chatWorker.dispose();
    _onFullscreenChange?.cancel();
    _errorsSubscription?.cancel();

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
    keepBottomUi();
    await _currentCall.value.toggleScreenShare();
  }

  /// Toggles local audio stream on and off.
  Future<void> toggleAudio() async {
    keepBottomUi();
    await _currentCall.value.toggleAudio();
  }

  /// Toggles local video stream on and off.
  Future<void> toggleVideo() async {
    keepBottomUi();
    await _currentCall.value.toggleVideo();
  }

  /// Changes the local video device to the next one from the
  /// [OngoingCall.devices] list.
  Future<void> switchCamera() async {
    keepBottomUi();

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

  Future<void> toggleSpeaker() async {
    keepBottomUi();

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
  }

  /// Raises/lowers a hand.
  Future<void> toggleHand() async {
    keepBottomUi();
    isHandRaised.toggle();
    _putParticipant(RemoteMemberId(me, null), handRaised: isHandRaised.value);
    await _toggleHand();
  }

  /// Toggles more panel.
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
  void toggleFullscreen() {
    if (fullscreen.isTrue) {
      fullscreen.value = false;
      PlatformUtils.exitFullscreen();
    } else {
      fullscreen.value = true;
      PlatformUtils.enterFullscreen();
    }
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
    if (state.value == OngoingCallState.active &&
        enabled == null &&
        !isPanelOpen.value) {
      _uiTimer = Timer(
        const Duration(seconds: _uiDuration),
        () => showUi.value = false,
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
      _insureCorrectGrouping();
    } else {
      if (!paneled.contains(participant)) {
        _putVideoTo(participant, paneled);
        _insureCorrectGrouping();
      }
    }
  }

  /// Highlights the [participant].
  void highlight(Participant? participant) {
    highlighted.value = participant;
    keepUi(false);
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

  /// Hides or shows bottom ui.
  void keepBottomUi([bool? enabled]) {
    _uiBottomTimer?.cancel();
    showBottomUi.value = isPanelOpen.value || (enabled ?? true);
    if (state.value == OngoingCallState.active &&
        enabled == null &&
        !isPanelOpen.value) {
      _uiBottomTimer = Timer(
        const Duration(seconds: _uiDuration),
        () => showBottomUi.value = false,
      );
    }
  }

  /// Returns a result of the [showDialog] building an [AddChatMemberView] or an
  /// [AddDialogMemberView].
  Future<dynamic> openAddMember(BuildContext context) {
    if (isGroup) {
      return showDialog(
        context: context,
        builder: (_) => AddChatMemberView(chat.value!.chat.value.id),
      );
    } else if (isDialog) {
      return showDialog(
        context: context,
        builder: (_) =>
            AddDialogMemberView(chat.value!.chat.value.id, _currentCall),
      );
    }

    return Future.value();
  }

  /// Returns an [User] from the [UserService] by the provided [id].
  Future<Rx<User>?> getUser(UserId id) => _userService.get(id);

  /// Applies constraints to the [width], [height], [left] and [top].
  void applyConstraints(BuildContext context) {
    width.value = _applyWidth(context, width.value);
    height.value = _applyHeight(context, height.value);
    left.value = _applyLeft(context, left.value);
    top.value = _applyTop(context, top.value);
  }

  /// Applies constraints to the [selfRight] and [selfBottom].
  void applySelfConstraints(BuildContext context) {
    final keyContext = selfKey.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;

      if (selfRight.value < 0) {
        selfRight.value = 0;
      } else if (selfRight.value > size.width - box.size.width) {
        selfRight.value = size.width - box.size.width;
      }

      if (selfBottom.value < 0) {
        selfBottom.value = 0;
      } else if (selfBottom.value >
          size.height - box.size.height - padding.bottom - padding.top) {
        selfBottom.value =
            size.height - box.size.height - padding.bottom - padding.top;
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

      // If every [RtcVideoRenderer] is in panel, then put everyone outside of
      // it.
      else if (paneled.isNotEmpty && focused.isEmpty) {
        List<Participant> copy = List.from(paneled, growable: false);
        for (Participant r in copy) {
          _putVideoFrom(r, paneled);
        }
      }
    }

    locals.refresh();
    remotes.refresh();
    paneled.refresh();
    focused.refresh();
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
          switch (participant.source) {
            case MediaSourceKind.Device:
              locals.add(participant);
              break;

            case MediaSourceKind.Display:
              paneled.add(participant);
              break;
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

        if (highlighted.value == participant) {
          highlighted.value = null;
        }
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
    Rx<User>? user,
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
  final Rx<Rx<User>?> user;

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
}
