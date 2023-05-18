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

import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' show VideoView;
import 'package:medea_jason/medea_jason.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show RemoveChatCallMemberException, RemoveChatMemberException;
import '/routes.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'component/common.dart';
import 'participant/view.dart';
import 'screen_share/view.dart';
import 'settings/view.dart';
import 'widget/dock.dart';

export 'view.dart';

/// Controller of an [OngoingCall] overlay.
class CallController extends GetxController {
  CallController(
    this._currentCall,
    this._calls,
    this._chatService,
    this._userService,
    this._myUserService,
    this._settingsRepository,
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

  /// Indicator whether info header is shown or not.
  final RxBool showHeader = RxBool(true);

  /// Local [Participant]s in `default` mode.
  final RxList<Participant> locals = RxList([]);

  /// Remote [Participant]s in `default` mode.
  final RxList<Participant> remotes = RxList([]);

  /// [Participant]s in `focus` mode.
  final RxList<Participant> focused = RxList([]);

  /// [Participant]s in `panel` mode.
  final RxList<Participant> paneled = RxList([]);

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
  late final RxBool speakerSwitched;

  /// Indicator whether the buttons panel is open or not.
  final RxBool isPanelOpen = RxBool(false);

  /// Indicator whether the cursor should be hidden or not.
  final RxBool isCursorHidden = RxBool(false);

  /// [PanelController] used to close the [SlidingUpPanel].
  final PanelController panelController = PanelController();

  /// [DateTime] of when the last [Listener.onPointerDown] callback happened.
  DateTime? downAt;

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

  /// Reactive [Rect] of the [Dock].
  ///
  /// Used to calculate intersections.
  final Rx<Rect?> dockRect = Rx(null);

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

  final AudioPlayer _reconnectPlayer = AudioPlayer();
  Worker? _reconnectWorker;

  /// Max width of the minimized view in percentage of the screen width.
  static const double _maxWidth = 0.99;

  /// Max height of the minimized view in percentage of the screen height.
  static const double _maxHeight = 0.99;

  /// Min width of the minimized view in pixels.
  static const double _minWidth = 300;

  /// Min height of the minimized view in pixels.
  static const double _minHeight = 300;

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

  /// [BoxConstraints] representing the previous [size] used in [scaleSecondary]
  /// to calculate the difference.
  BoxConstraints? _lastConstraints;

  /// Service managing the [_currentCall].
  final CallService _calls;

  /// [Chat]s service used to fetch the[chat].
  final ChatService _chatService;

  /// Settings repository maintaining [OngoingCall] related preferences.
  final AbstractSettingsRepository _settingsRepository;

  /// Current [OngoingCall].
  final Rx<OngoingCall> _currentCall;

  /// [User]s service, used to fill a [Participant.user] field.
  final UserService _userService;

  final MyUserService _myUserService;

  bool get income =>
      _myUserService.myUser.value?.name?.val == 'kirey' ||
      _myUserService.myUser.value?.name?.val == 'alex2';

  /// [Timer] for updating [duration] of the call.
  ///
  /// Starts once the [state] becomes [OngoingCallState.active].
  Timer? _durationTimer;

  /// [Timer] toggling [showUi] value.
  Timer? _uiTimer;

  /// Worker capturing any [buttons] changes to update the
  /// [ApplicationSettings.callButtons] value.
  Worker? _buttonsWorker;

  /// Worker capturing any [ApplicationSettings.callButtons] changes to update
  /// the [buttons] value.
  Worker? _settingsWorker;

  /// Subscription for [PlatformUtils.onFullscreenChange], used to correct the
  /// [fullscreen] value.
  StreamSubscription? _onFullscreenChange;

  /// Subscription for [OngoingCall.errors] stream.
  StreamSubscription? _errorsSubscription;

  /// Subscription for [WebUtils.onWindowFocus] changes hiding the UI on a focus
  /// lose.
  StreamSubscription? _onWindowFocus;

  /// [Map] of [BoxFit]s that [RtcVideoRenderer] should explicitly have.
  final RxMap<String, BoxFit?> rendererBoxFit = RxMap<String, BoxFit?>();

  /// [Worker] for catching the [state] changes to start the [_durationTimer].
  late final Worker _stateWorker;

  /// [Worker] closing the more panel on [showUi] changes.
  late final Worker _showUiWorker;

  /// Subscription for [OngoingCall.members] changes.
  late final StreamSubscription _membersSubscription;

  /// [StreamSubscription]s for the [CallMember.tracks] updates.
  late final Map<CallMemberId, StreamSubscription> _membersTracksSubscriptions;

  /// Subscription for [OngoingCall.members] changes updating the title.
  StreamSubscription? _titleSubscription;

  /// Subscription for [duration] changes updating the title.
  StreamSubscription? _durationSubscription;

  /// [Worker] reacting on [OngoingCall.chatId] changes to fetch the new [chat].
  late final Worker _chatWorker;

  /// Returns the [ChatId] of the [Chat] this [OngoingCall] is taking place in.
  Rx<ChatId> get chatId => _currentCall.value.chatId;

  /// State of the current [OngoingCall] progression.
  Rx<OngoingCallState> get state => _currentCall.value.state;

  /// Returns a [CallMember] of the currently authorized [MyUser].
  CallMember get me => _currentCall.value.me;

  /// Indicates whether the current authorized [MyUser] is the caller.
  bool get outgoing =>
      _calls.me == _currentCall.value.caller?.id ||
      _currentCall.value.caller == null;

  /// Indicates whether the current [OngoingCall] has started or not.
  bool get started => _currentCall.value.conversationStartedAt != null;

  /// Indicates whether the current [OngoingCall] is with video or not.
  bool get withVideo => _currentCall.value.withVideo ?? false;

  RxList<MediaDeviceDetails> get devices => _currentCall.value.devices;
  RxList<CallNotification> get deviceChanges =>
      _currentCall.value.deviceChanges;

  void addNotification({MediaDeviceDetails? device, int? score}) =>
      _currentCall.value.addNotification(device: device, score: score);

  void removeNotification(CallNotification notification) =>
      _currentCall.value.removeNotification(notification);

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

  /// Indicates whether a drag and drop videos hint should be displayed.
  bool get showDragAndDropVideosHint =>
      _settingsRepository
          .applicationSettings.value?.showDragAndDropVideosHint ??
      true;

  /// Sets the drag and drop videos hint indicator to the provided [value].
  set showDragAndDropVideosHint(bool value) {
    _settingsRepository.setShowDragAndDropVideosHint(value);
  }

  /// Indicates whether a drag and drop buttons hint should be displayed.
  bool get showDragAndDropButtonsHint =>
      _settingsRepository
          .applicationSettings.value?.showDragAndDropButtonsHint ??
      true;

  /// Sets the drag and drop buttons hint indicator to the provided [value].
  set showDragAndDropButtonsHint(bool value) {
    _settingsRepository.setShowDragAndDropButtonsHint(value);
  }

  RxBool get connectionLost => _currentCall.value.connectionLost;

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

  /// Indicates whether the [chat] is a monolog.
  bool get isMonolog => chat.value?.chat.value.isMonolog ?? false;

  /// Reactive map of the current call [CallMember]s.
  RxObsMap<CallMemberId, CallMember> get members => _currentCall.value.members;

  /// Indicator whether the inbound video in the current [OngoingCall] is
  /// enabled or not.
  RxBool get isRemoteVideoEnabled => _currentCall.value.isRemoteVideoEnabled;

  /// Indicator whether the inbound audio in the current [OngoingCall] is
  /// enabled.
  RxBool get isRemoteAudioEnabled => _currentCall.value.isRemoteAudioEnabled;

  PreciseDateTime get startedAt =>
      _currentCall.value.call.value?.conversationStartedAt ??
      _currentCall.value.call.value?.at ??
      PreciseDateTime.now();

  /// Constructs the arguments to pass to [L10nExtension.l10nfmt] to get the
  /// title of this [OngoingCall].
  Map<String, String> get titleArguments {
    final Map<String, String> args = {
      'title': chat.value?.title.value ?? ('dot'.l10n * 3),
      'state': state.value.name,
    };

    switch (state.value) {
      case OngoingCallState.local:
      case OngoingCallState.pending:
        bool isOutgoing =
            (outgoing || state.value == OngoingCallState.local) && !started;
        if (isOutgoing) {
          args['type'] = 'outgoing';
        } else if (withVideo) {
          args['type'] = 'video';
        } else {
          args['type'] = 'audio';
        }
        break;

      case OngoingCallState.active:
        final Set<UserId> actualMembers = members.keys
            .where((e) => e.deviceId != null)
            .map((k) => k.userId)
            .toSet();
        args['members'] = '${actualMembers.length}';
        args['allMembers'] = '${chat.value?.members.length ?? 1}';
        args['duration'] = duration.value.hhMmSs();
        if (income) {
          args['gpc'] = ((duration.value.inMinutes + 1) * 3).toString();
        }
        break;

      case OngoingCallState.joining:
      case OngoingCallState.ended:
        // No-op.
        break;
    }

    return args;
  }

  /// Returns a size ratio of the secondary view relative to the [size].
  double get secondaryRatio =>
      size.aspectRatio > 2 || size.aspectRatio < 0.5 ? 0.45 : 0.33;

  @override
  void onInit() {
    super.onInit();

    _currentCall.value.init();

    Size size = router.context!.mediaQuerySize;

    HardwareKeyboard.instance.addHandler(_onKey);
    if (PlatformUtils.isMobile) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    speakerSwitched = RxBool(!PlatformUtils.isIOS);

    fullscreen = RxBool(false);
    minimized = RxBool(!router.context!.isMobile && !WebUtils.isPopup);
    isMobile = router.context!.isMobile;

    final Rect? prefs =
        _settingsRepository.getCallRect(_currentCall.value.chatId.value);

    if (isMobile) {
      Size size = router.context!.mediaQuerySize;
      width = RxDouble(prefs?.width ?? size.width);
      height = RxDouble(prefs?.height ?? size.height);
    } else {
      width = RxDouble(
        prefs?.width ??
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
      height = RxDouble(prefs?.height ?? width.value);
    }

    final double secondarySize =
        (this.size.shortestSide * secondaryRatio).clamp(_minSHeight, 250);
    secondaryWidth = RxDouble(secondarySize);
    secondaryHeight = RxDouble(secondarySize);

    left = size.width - width.value - 50 > 0
        ? RxDouble(prefs?.left ?? size.width - width.value - 50)
        : RxDouble(prefs?.left ?? size.width / 2 - width.value / 2);
    top = height.value + 50 < size.height
        ? RxDouble(prefs?.top ?? 50)
        : RxDouble(prefs?.top ?? size.height / 2 - height.value / 2);

    void onChat(RxChat? v) {
      chat.value = v;
      if (!isGroup) {
        secondaryAlignment.value = null;
        secondaryLeft.value = null;
        secondaryTop.value = null;
        secondaryRight.value = 10;
        secondaryBottom.value = 10;
      }

      // Update the [WebUtils.title] if this call is in a popup.
      if (WebUtils.isPopup) {
        _titleSubscription?.cancel();
        _durationSubscription?.cancel();

        if (v != null) {
          void updateTitle() {
            WebUtils.title(
              '\u205f​​​ \u205f​​​${(income ? 'label_call_title_paid' : 'label_call_title').l10nfmt(titleArguments)}\u205f​​​ \u205f​​​',
            );
          }

          updateTitle();

          _titleSubscription =
              _currentCall.value.members.listen((_) => updateTitle());
          _durationSubscription = duration.listen((_) => updateTitle());
        }
      }
    }

    _chatService
        .get(_currentCall.value.chatId.value)
        .then(onChat)
        .whenComplete(() {
      members.forEach((_, value) => _putMember(value));
      _insureCorrectGrouping();
    });

    _chatWorker = ever(
      _currentCall.value.chatId,
      (ChatId id) => _chatService.get(id).then(onChat),
    );

    _stateWorker = ever(state, (OngoingCallState state) {
      switch (state) {
        case OngoingCallState.active:
          if (_durationTimer == null) {
            SchedulerBinding.instance.addPostFrameCallback(
              (_) {
                dockRect.value = dockKey.globalPaintBounds;
                relocateSecondary();
              },
            );
            DateTime begunAt = DateTime.now();
            _durationTimer = Timer.periodic(
              const Duration(seconds: 1),
              (_) {
                duration.value = DateTime.now().difference(begunAt);
                if (hoveredRendererTimeout > 0) {
                  --hoveredRendererTimeout;
                  if (hoveredRendererTimeout == 0) {
                    hoveredRenderer.value = null;
                    isCursorHidden.value = true;
                  }
                }

                if (errorTimeout.value > 0) {
                  --errorTimeout.value;
                }
              },
            );

            keepUi();
            _ensureSpeakerphone();
          }
          break;

        case OngoingCallState.joining:
          SchedulerBinding.instance.addPostFrameCallback(
            (_) => SchedulerBinding.instance.addPostFrameCallback(
              (_) => relocateSecondary(),
            ),
          );
          break;

        case OngoingCallState.pending:
        case OngoingCallState.local:
        case OngoingCallState.ended:
          // No-op.
          break;
      }

      refresh();
    });

    _onFullscreenChange = PlatformUtils.onFullscreenChange.listen((bool v) {
      fullscreen.value = v;
      refresh();
    });

    _onWindowFocus = WebUtils.onWindowFocus.listen((e) {
      if (!e) {
        hoveredRenderer.value = null;
        if (_uiTimer?.isActive != true) {
          if (displayMore.isTrue) {
            keepUi();
          } else {
            keepUi(false);
          }
        }
      }
    });

    _errorsSubscription = _currentCall.value.errors.listen((e) {
      error.value = e;
      errorTimeout.value = _errorDuration;
    });

    // Constructs a list of [CallButton]s from the provided [list] of [String]s.
    List<CallButton> toButtons(List<String>? list) {
      List<CallButton>? persisted = list
          ?.map((e) {
            switch (e) {
              case 'ScreenButton':
                return ScreenButton(this);

              case 'VideoButton':
                return VideoButton(this);

              case 'EndCallButton':
                return EndCallButton(this);

              case 'AudioButton':
                return AudioButton(this);

              case 'MoreButton':
                return MoreButton(this);

              case 'SettingsButton':
                return SettingsButton(this);

              case 'ParticipantsButton':
                return ParticipantsButton(this);

              case 'HandButton':
                return HandButton(this);

              case 'RemoteVideoButton':
                return RemoteVideoButton(this);

              case 'RemoteAudioButton':
                return RemoteAudioButton(this);
            }
          })
          .whereNotNull()
          .toList();

      // Add default [CallButton]s, if none are persisted.
      if (persisted?.isNotEmpty != true) {
        persisted = [
          ScreenButton(this),
          VideoButton(this),
          EndCallButton(this),
          AudioButton(this),
          MoreButton(this),
        ];
      }

      // Ensure [EndCallButton] is always in the list.
      if (persisted!.whereType<ReconnectButton>().isEmpty) {
        persisted.insert(0, ReconnectButton(this));
      }

      // Ensure [EndCallButton] is always in the list.
      if (persisted!.whereType<EndCallButton>().isEmpty) {
        persisted.add(EndCallButton(this));
      }

      // Ensure [MoreButton] is always in the list.
      if (persisted.whereType<MoreButton>().isEmpty) {
        persisted.add(MoreButton(this));
      }

      return persisted;
    }

    buttons = RxList(
      toButtons(_settingsRepository.applicationSettings.value?.callButtons),
    );

    panel = RxList([
      SettingsButton(this),
      ParticipantsButton(this),
      HandButton(this),
      ScreenButton(this),
      RemoteVideoButton(this),
      RemoteAudioButton(this),
      VideoButton(this),
      AudioButton(this),
    ]);

    _buttonsWorker = ever(buttons, (List<CallButton> list) {
      _settingsRepository
          .setCallButtons(list.map((e) => e.runtimeType.toString()).toList());
    });

    List<String>? previous =
        _settingsRepository.applicationSettings.value?.callButtons;
    _settingsWorker = ever(
      _settingsRepository.applicationSettings,
      (ApplicationSettings? settings) {
        if (!const ListEquality().equals(settings?.callButtons, previous)) {
          if (settings != null) {
            buttons.value = toButtons(settings.callButtons);
          }
          previous = settings?.callButtons;
        }
      },
    );

    _showUiWorker = ever(showUi, (bool showUi) {
      if (displayMore.value && !showUi) {
        displayMore.value = false;
      }
    });

    void onTracksChanged(
      CallMember member,
      ListChangeNotification<Track> track,
    ) {
      switch (track.op) {
        case OperationKind.added:
          _putParticipant(member, track.element);
          _insureCorrectGrouping();
          break;

        case OperationKind.removed:
          _removeParticipant(member, track.element);
          _insureCorrectGrouping();
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    }

    _membersTracksSubscriptions = _currentCall.value.members.map(
      (k, v) =>
          MapEntry(k, v.tracks.changes.listen((c) => onTracksChanged(v, c))),
    );

    _membersSubscription = _currentCall.value.members.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          _putMember(e.value!);
          _membersTracksSubscriptions[e.key!] = e.value!.tracks.changes.listen(
            (c) => onTracksChanged(e.value!, c),
          );

          _insureCorrectGrouping();
          break;

        case OperationKind.removed:
          bool wasNotEmpty = primary.isNotEmpty;
          paneled.removeWhere((m) => m.member.id == e.key);
          locals.removeWhere((m) => m.member.id == e.key);
          focused.removeWhere((m) => m.member.id == e.key);
          remotes.removeWhere((m) => m.member.id == e.key);
          _membersTracksSubscriptions.remove(e.key)?.cancel();
          _insureCorrectGrouping();
          if (wasNotEmpty && primary.isEmpty) {
            focusAll();
          }

          print(
              '${_settingsRepository.applicationSettings.value?.leaveWhenAlone == true}, ${e.value?.isConnected.value == true}, ${e.key?.userId != me.id.userId}, ${_currentCall.value.members.keys} vs ${me.id}');

          if (_settingsRepository.applicationSettings.value?.leaveWhenAlone ==
                  true &&
              e.value?.isConnected.value == true &&
              e.key?.userId != me.id.userId &&
              _currentCall.value.members.keys
                  .where((e) => e != me.id)
                  .isEmpty) {
            drop();
          }
          break;

        case OperationKind.updated:
          if (e.key != e.oldKey && e.oldKey != null) {
            for (var m in [
              ..._findParticipants(e.oldKey!, MediaSourceKind.Device),
              ..._findParticipants(e.oldKey!, MediaSourceKind.Display),
            ]) {
              m.member = e.value!;
              print('member is now ${e.value?.id}');
            }
          }

          _insureCorrectGrouping();
          break;
      }
    });

    AudioCache.instance.loadAll(['audio/reconnect.mp3']);
    _reconnectWorker = ever(_currentCall.value.connectionLost, (b) async {
      if (b) {
        await _reconnectPlayer.setReleaseMode(ReleaseMode.loop);
        await _reconnectPlayer.play(
          AssetSource('audio/reconnect.mp3'),
          position: Duration.zero,
          mode: PlayerMode.lowLatency,
        );
      } else {
        await _reconnectPlayer.stop();
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
    _onWindowFocus?.cancel();
    _titleSubscription?.cancel();
    _durationSubscription?.cancel();
    _buttonsWorker?.dispose();
    _settingsWorker?.dispose();
    _reconnectPlayer.dispose();

    secondaryEntry?.remove();

    _settingsRepository.setCallRect(
      chat.value!.id,
      Rect.fromLTWH(left.value, top.value, width.value, height.value),
    );

    if (fullscreen.value) {
      PlatformUtils.exitFullscreen();
    }

    HardwareKeyboard.instance.removeHandler(_onKey);
    if (PlatformUtils.isMobile) {
      BackButtonInterceptor.remove(_onBack);
    }

    _membersTracksSubscriptions.forEach((_, v) => v.cancel());
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
  Future<void> toggleScreenShare(BuildContext context) async {
    if (PlatformUtils.isMobile) {
      keepUi();
    }

    final LocalTrackState state = _currentCall.value.screenShareState.value;

    if (state == LocalTrackState.enabled || state == LocalTrackState.enabling) {
      await _currentCall.value.setScreenShareEnabled(false);
    } else {
      // TODO: `medea_jason` should have `onScreenChange` callback.
      await _currentCall.value.enumerateDevices(media: false);

      if (_currentCall.value.displays.length > 1) {
        final MediaDisplayDetails? display =
            await ScreenShareView.show(router.context!, _currentCall);

        if (display != null) {
          await _currentCall.value.setScreenShareEnabled(
            true,
            deviceId: display.deviceId(),
          );
        }
      } else {
        await _currentCall.value.setScreenShareEnabled(true);
      }
    }
  }

  /// Toggles local audio stream on and off.
  Future<void> toggleAudio() async {
    if (PlatformUtils.isMobile) {
      keepUi();
    }

    await _currentCall.value.toggleAudio();
  }

  /// Toggles local video stream on and off.
  Future<void> toggleVideo() async {
    if (PlatformUtils.isMobile) {
      keepUi();
    }

    await _currentCall.value.toggleVideo();
    await _ensureSpeakerphone();
  }

  /// Changes the local video device to the next one from the
  /// [OngoingCall.devices] list.
  Future<void> switchCamera() async {
    if (PlatformUtils.isMobile) {
      keepUi();
    }

    List<MediaDeviceDetails> cameras =
        _currentCall.value.devices.video().toList();
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

  /// Toggles between the speakerphone and earpiece output.
  ///
  /// Does nothing, if output device is a bluetooth headset.
  Future<void> toggleSpeaker() async {
    if (PlatformUtils.isMobile) {
      keepUi();
    }

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      final List<MediaDeviceDetails> outputs =
          _currentCall.value.devices.output().toList();
      if (outputs.length > 1) {
        MediaDeviceDetails? device;

        if (PlatformUtils.isIOS) {
          device = _currentCall.value.devices.output().firstWhereOrNull(
              (e) => e.deviceId() != 'ear-piece' && e.deviceId() != 'speaker');
        } else {
          device = _currentCall.value.devices.output().firstWhereOrNull((e) =>
              e.deviceId() != 'ear-speaker' && e.deviceId() != 'speakerphone');
        }

        if (device == null) {
          if (speakerSwitched.value) {
            device = outputs.firstWhereOrNull((e) =>
                e.deviceId() == 'ear-piece' || e.deviceId() == 'ear-speaker');
            speakerSwitched.value = !(device != null);
          } else {
            device = outputs.firstWhereOrNull((e) =>
                e.deviceId() == 'speakerphone' || e.deviceId() == 'speaker');
            speakerSwitched.value = (device != null);
          }

          if (device == null) {
            int selected = _currentCall.value.outputDevice.value == null
                ? 0
                : outputs.indexWhere((e) =>
                    e.deviceId() == _currentCall.value.outputDevice.value!);
            selected += 1;
            device = outputs[(selected) % outputs.length];
          }
        }

        await _currentCall.value.setOutputDevice(device.deviceId());
      }
    } else {
      // TODO: Ensure `medea_flutter_webrtc` supports Web output device
      //       switching.
      speakerSwitched.toggle();
    }
  }

  /// Raises/lowers a hand.
  Future<void> toggleHand() {
    if (PlatformUtils.isMobile) {
      keepUi();
    }

    return _currentCall.value.toggleHand(_calls);
  }

  /// Toggles the [displayMore].
  void toggleMore() => displayMore.toggle();

  /// Toggles fullscreen on and off.
  Future<void> toggleFullscreen() async {
    if (fullscreen.isTrue) {
      fullscreen.value = false;
      await PlatformUtils.exitFullscreen();
    } else {
      fullscreen.value = true;
      await PlatformUtils.enterFullscreen();
    }

    updateSecondaryAttach();
    applySecondaryConstraints();
  }

  /// Toggles inbound video in the current [OngoingCall] on and off.
  Future<void> toggleRemoteVideos() => _currentCall.value.toggleRemoteVideo();

  /// Toggles inbound audio in the current [OngoingCall] on and off.
  Future<void> toggleRemoteAudios() => _currentCall.value.toggleRemoteAudio();

  /// Toggles the provided [participant]'s incoming video on and off.
  Future<void> toggleVideoEnabled(Participant participant) async {
    if (participant.member.id == me.id) {
      await toggleVideo();
    } else if (participant.video.value?.direction.value.isEmitting ?? false) {
      await participant.member.setVideoEnabled(
        !participant.video.value!.direction.value.isEnabled,
        source: participant.video.value!.source,
      );
    }
  }

  /// Toggles the provided [participant]'s incoming audio on and off.
  Future<void> toggleAudioEnabled(Participant participant) async {
    if (participant.member.id == me.id) {
      await toggleAudio();
    } else if (participant.audio.value?.direction.value.isEmitting ?? false) {
      await participant.member.setAudioEnabled(
        !participant.audio.value!.direction.value.isEnabled,
      );
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

  /// Centers the [participant], which means [focus]ing the [participant] and
  /// [unfocus]ing every participant in [focused].
  void center(Participant participant) {
    if (participant.member.owner == MediaOwnerKind.local &&
        participant.video.value?.source == MediaSourceKind.Display) {
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
    if (participant.member.owner == MediaOwnerKind.local &&
        participant.video.value?.source == MediaSourceKind.Display) {
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
    if (participant.member.owner == MediaOwnerKind.local &&
        participant.video.value?.source == MediaSourceKind.Display) {
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
    return CallSettingsView.show(context, call: _currentCall);
  }

  /// Returns a result of the [showDialog] building a [ParticipantView].
  Future<void> openAddMember(BuildContext context) async {
    if (isMonolog) {
      return;
    }

    if (isMobile) {
      panelController.close().then((_) {
        isPanelOpen.value = false;
        keepUi(false);
      });
    }

    await ParticipantView.show(
      context,
      call: _currentCall,
      duration: duration,
    );
  }

  /// Removes [User] identified by the provided [userId] from the [chat].
  Future<void> removeChatMember(UserId userId) async {
    try {
      await _chatService.removeChatMember(chatId.value, userId);
    } on RemoveChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes [User] identified by the provided [userId] from the
  /// [_currentCall].
  Future<void> removeChatCallMember(UserId userId) async {
    try {
      await _calls.removeChatCallMember(chatId.value, userId);
    } on RemoveChatCallMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
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
        !_secondaryRelocated) {
      _secondaryRelocated = true;

      Rect? secondaryBounds, dockBounds;

      try {
        secondaryBounds = secondaryKey.globalPaintBounds;
        dockBounds = dockKey.globalPaintBounds;
      } catch (_) {
        // No-op.
      }

      Rect intersect =
          secondaryBounds?.intersect(dockBounds ?? Rect.zero) ?? Rect.zero;

      intersect = Rect.fromLTWH(
        intersect.left,
        intersect.top,
        intersect.width,
        intersect.height + 10,
      );

      if (intersect.width > 0 && intersect.height > 0) {
        secondaryBottomShifted ??= secondaryBottom.value ??
            size.height - secondaryTop.value! - secondaryHeight.value;

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
              secondaryBottomShifted = null;
            } else {
              secondaryBottom.value =
                  secondaryBottom.value! - intersect.height.abs();
            }
          } else {
            if (difference.abs() < intersect.height.abs() ||
                intersect.width < 0) {
              secondaryTop.value =
                  size.height - secondaryHeight.value - secondaryBottomShifted!;
              secondaryBottomShifted = null;
            } else {
              secondaryTop.value = secondaryTop.value! + intersect.height.abs();
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
  void resize(
    BuildContext context, {
    ScaleModeY? y,
    ScaleModeX? x,
    double? dx,
    double? dy,
  }) {
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

    // Update the secondary constraints.
    applySecondaryConstraints();
  }

  /// Resizes the secondary view along [x] by [dx] and/or [y] by [dy] axis.
  void resizeSecondary(
    BuildContext context, {
    ScaleModeY? y,
    ScaleModeX? x,
    double? dx,
    double? dy,
  }) {
    if (x != null && dx != null) {
      final RxnDouble xPrimaryOffset =
          x == ScaleModeX.left ? secondaryLeft : secondaryRight;
      final RxnDouble xSecondaryOffset =
          x == ScaleModeX.left ? secondaryRight : secondaryLeft;

      _updateSecondaryAxisOffset(
        primary: xPrimaryOffset,
        secondary: xSecondaryOffset,
        axis: Axis.horizontal,
      );

      _updateSecondarySize(
        sideOffset: xPrimaryOffset,
        applyOffset: x == ScaleModeX.left ? _applySLeft : _applySRight,
        delta: dx,
        axis: Axis.horizontal,
      );
    }

    if (y != null && dy != null) {
      final RxnDouble yPrimaryOffset =
          y == ScaleModeY.top ? secondaryTop : secondaryBottom;
      final RxnDouble ySecondaryOffset =
          y == ScaleModeY.top ? secondaryBottom : secondaryTop;

      _updateSecondaryAxisOffset(
        primary: yPrimaryOffset,
        secondary: ySecondaryOffset,
        axis: Axis.vertical,
      );

      _updateSecondarySize(
        sideOffset: yPrimaryOffset,
        applyOffset: y == ScaleModeY.top ? _applySTop : _applySBottom,
        delta: dy,
        axis: Axis.vertical,
      );
    }

    applySecondaryConstraints();
  }

  /// Scales secondary according to the [constraints] and [_lastConstraints]
  /// difference.
  void scaleSecondary(BoxConstraints constraints) {
    if (_lastConstraints == constraints) {
      return;
    }

    if (_lastConstraints != null) {
      final dif = (constraints.maxWidth + constraints.maxHeight) -
          (_lastConstraints!.maxWidth + _lastConstraints!.maxHeight);

      secondaryWidth.value = _applySWidth(secondaryWidth.value + dif * 0.07);
      secondaryHeight.value = _applySHeight(secondaryHeight.value + dif * 0.07);
    }

    _lastConstraints = constraints;
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

  /// Updates the [primary] and [secondary] offsets according to the current
  /// [size].
  void _updateSecondaryAxisOffset({
    required RxnDouble primary,
    required RxnDouble secondary,
    required Axis axis,
  }) {
    final double parentEmptySpace = axis == Axis.horizontal
        ? size.width - secondaryWidth.value
        : size.height - secondaryHeight.value;

    primary.value ??= parentEmptySpace - (secondary.value ?? 0);

    // Nullify the [secondary] offset.
    secondary.value = null;
  }

  /// Updates the secondary panel size and translates it, if necessary.
  void _updateSecondarySize({
    required RxnDouble sideOffset,
    required double? Function(double?) applyOffset,
    required double delta,
    required Axis axis,
  }) {
    late RxDouble sizeAxis;
    late double parentAxisSize;
    late double Function(double) applyAxisSize;

    switch (axis) {
      case Axis.horizontal:
        sizeAxis = secondaryWidth;
        parentAxisSize = size.width;
        applyAxisSize = _applySWidth;
        break;

      case Axis.vertical:
        sizeAxis = secondaryHeight;
        parentAxisSize = size.height;
        applyAxisSize = _applySHeight;
        break;

      default:
        return;
    }

    final double newSize = applyAxisSize(sizeAxis.value - delta);

    if (sizeAxis.value - delta == newSize) {
      double? offset =
          applyOffset(sideOffset.value! + (sizeAxis.value - newSize));

      if (sideOffset.value! + (sizeAxis.value - newSize) == offset) {
        sideOffset.value = offset;
        sizeAxis.value = newSize;
      } else if (offset == parentAxisSize - sizeAxis.value) {
        sideOffset.value = parentAxisSize - newSize;
        sizeAxis.value = newSize;
      }
    }
  }

  /// Invokes [minimize], if not [minimized] already.
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo __) {
    if (minimized.isFalse) {
      minimize();
      return true;
    }

    return false;
  }

  /// Puts [participant] from its `default` group to [list].
  void _putVideoTo(Participant participant, RxList<Participant> list) {
    if (participant.member.owner == MediaOwnerKind.local &&
        participant.video.value?.source == MediaSourceKind.Display) {
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
    switch (participant.member.owner) {
      case MediaOwnerKind.local:
        // Movement of [MediaSourceKind.Display] to [locals] is prohibited.
        if (participant.video.value?.source == MediaSourceKind.Display) {
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

    applySecondaryConstraints();
  }

  /// Returns all [Participant]s identified by an [id] and [source].
  Iterable<Participant> _findParticipants(
    CallMemberId id, [
    MediaSourceKind? source,
  ]) {
    source ??= MediaSourceKind.Device;
    return [
      ...locals.where((e) => e.member.id == id && e.source == source),
      ...remotes.where((e) => e.member.id == id && e.source == source),
      ...paneled.where((e) => e.member.id == id && e.source == source),
      ...focused.where((e) => e.member.id == id && e.source == source),
    ];
  }

  /// Puts the [CallMember.tracks] to the according [Participant].
  void _putMember(CallMember member) {
    if (member.tracks.none((t) => t.source == MediaSourceKind.Device)) {
      _putParticipant(member, null);
    }

    for (Track t in member.tracks) {
      _putParticipant(member, t);
    }
  }

  /// Puts the provided [track] to the [Participant] this [member] represents.
  ///
  /// If no suitable [Participant]s for this [track] are found, then a new
  /// [Participant] with this [track] is added.
  void _putParticipant(CallMember member, Track? track) {
    final Iterable<Participant> participants =
        _findParticipants(member.id, track?.source);

    if (track?.source == MediaSourceKind.Display ||
        participants.isEmpty ||
        (track != null &&
            participants.none((e) => track.kind == MediaKind.Video
                ? e.video.value == null
                : e.audio.value == null &&
                    e.video.value?.source != MediaSourceKind.Display))) {
      final Participant participant = Participant(
        member,
        video: track?.kind == MediaKind.Video ? track : null,
        audio: track?.kind == MediaKind.Audio ? track : null,
      );

      _userService
          .get(member.id.userId)
          .then((u) => participant.user.value = u ?? participant.user.value);

      switch (member.owner) {
        case MediaOwnerKind.local:
          if (isGroup || isMonolog) {
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

          if (state.value == OngoingCallState.local || outgoing) {
            SchedulerBinding.instance
                .addPostFrameCallback((_) => relocateSecondary());
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
      if (track != null) {
        final Participant participant = participants.firstWhere((e) =>
            track.kind == MediaKind.Video
                ? e.video.value == null
                : e.audio.value == null &&
                    e.video.value?.source != MediaSourceKind.Display);
        if (track.kind == MediaKind.Video) {
          participant.video.value = track;
        } else {
          participant.audio.value = track;
        }
      }
    }
  }

  /// Removes [Participant] this [member] represents with the provided [track].
  void _removeParticipant(CallMember member, Track track) {
    final Iterable<Participant> participants =
        _findParticipants(member.id, track.source);

    if (track.kind == MediaKind.Video) {
      if (participants.length == 1 && track.source == MediaSourceKind.Device) {
        participants.first.video.value = null;
      } else {
        final Participant? participant =
            participants.firstWhereOrNull((p) => p.video.value == track);
        if (participant != null) {
          locals.remove(participant);
          remotes.remove(participant);
          paneled.remove(participant);
          focused.remove(participant);
        }
      }
    } else {
      final Participant? participant =
          participants.firstWhereOrNull((p) => p.audio.value == track);
      participant?.audio.value = null;
    }
  }

  /// Invokes [toggleFullscreen], if [fullscreen] is `true`.
  ///
  /// Intended to be used as a [HardwareKeyboard] handler, thus returns `true`,
  /// if [LogicalKeyboardKey.escape] key should be intercepted, or otherwise
  /// returns `false`.
  bool _onKey(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape && fullscreen.isTrue) {
      toggleFullscreen();
      return true;
    }

    return false;
  }

  /// Ensures [OngoingCall.outputDevice] is a speakerphone, if video is enabled.
  Future<void> _ensureSpeakerphone() async {
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      if (_currentCall.value.videoState.value == LocalTrackState.enabled ||
          _currentCall.value.videoState.value == LocalTrackState.enabling) {
        final bool ear;

        if (PlatformUtils.isIOS) {
          ear = _currentCall.value.outputDevice.value == 'ear-piece' ||
              (_currentCall.value.outputDevice.value == null &&
                  _currentCall.value.devices.output().firstOrNull?.deviceId() ==
                      'ear-piece');
        } else {
          ear = _currentCall.value.outputDevice.value == 'ear-speaker' ||
              (_currentCall.value.outputDevice.value == null &&
                  _currentCall.value.devices.output().firstOrNull?.deviceId() ==
                      'ear-speaker');
        }

        if (ear) {
          await toggleSpeaker();
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
    this.member, {
    Track? video,
    Track? audio,
    RxUser? user,
  })  : user = Rx(user),
        video = Rx(video),
        audio = Rx(audio);

  /// [CallMember] this [Participant] represents.
  CallMember member;

  /// [User] this [Participant] represents.
  final Rx<RxUser?> user;

  /// Reactive video track of this [Participant].
  final Rx<Track?> video;

  /// Reactive audio track of this [Participant].
  final Rx<Track?> audio;

  /// [GlobalKey] of this [Participant]'s [VideoView].
  final GlobalKey videoKey = GlobalKey();
  final GlobalKey redialingKey = GlobalKey();
  final GlobalKey containerKey = GlobalKey();

  /// Returns the [MediaSourceKind] of this [Participant].
  MediaSourceKind get source =>
      video.value?.source ?? audio.value?.source ?? MediaSourceKind.Device;
}
