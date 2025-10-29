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

import 'dart:async';
import 'dart:math';

import 'package:all_sensors/all_sensors.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' show VideoView;
import 'package:medea_jason/medea_jason.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '/config.dart';
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
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/call/participant/controller.dart';
import '/util/audio_utils.dart';
import '/util/fixed_timer.dart';
import '/util/global_key.dart';
import '/util/log.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'component/common.dart';
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
    this._settingsRepository,
  );

  /// Duration of the current ongoing call.
  final Rx<Duration> duration = Rx<Duration>(Duration.zero);

  /// Reactive [Chat] that this [OngoingCall] is happening in.
  final Rx<RxChat?> chat = Rx<RxChat?>(null);

  /// Indicator whether the view is minimized or maximized.
  late final RxBool minimized;

  /// Indicator whether the view is in fullscreen.
  late final RxBool fullscreen;

  /// Indicator whether the UI is shown.
  final RxBool showUi = RxBool(true);

  /// Indicator whether the info header of desktop design is currently shown.
  final RxBool showHeader = RxBool(true);

  /// Indicator whether the info header of desktop design is currently hovered.
  ///
  /// Used to prevent [showHeader] turning off in [keepUi], when it's actually
  /// hovered by a pointer.
  bool headerHovered = false;

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
  ///
  /// [hoveredParticipant] not being `null` means the whole space available for
  /// [Participant] is being hovered, not accounting the possible paddings, etc.
  final Rx<Participant?> hoveredParticipant = Rx<Participant?>(null);

  /// [Participant], whose visible part is being hovered right now.
  ///
  /// Used to show [CustomMouseCursors.grab] over [RtcVideoView], as it may not
  /// take the whole [Participant]'s space.
  final Rx<Participant?> hoveredRenderer = Rx<Participant?>(null);

  /// Timeout of a [hoveredParticipant] used to hide it.
  int hoveredParticipantTimeout = 0;

  /// Minimized view current width.
  final RxDouble width = RxDouble(200);

  /// Minimized view current height.
  final RxDouble height = RxDouble(200);

  /// Minimized view current top position.
  final RxDouble top = RxDouble(0);

  /// Minimized view current left position.
  final RxDouble left = RxDouble(0);

  /// Indicator whether the view shouldn't be visible.
  ///
  /// Used to prevent [width], [height], [left] and [top] flickering.
  final RxBool hidden = RxBool(true);

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

  /// Indicator whether [draggedButton] is from [Launchpad].
  bool draggedFromDock = false;

  /// [AnimationController] of a [MinimizableView] used to change the
  /// [minimized] value.
  AnimationController? minimizedAnimation;

  /// Maximum size a single [CallButton] is allowed to occupy in the [Dock].
  static const double buttonSize = 48.0;

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

  /// [List] of the currently active [CallNotification]s.
  final RxList<CallNotification> notifications = RxList<CallNotification>();

  /// Height of the title bar.
  static const double titleHeight = 30;

  /// Indicator whether the [MinimizableView] is being minimized.
  final RxBool minimizing = RxBool(false);

  /// Indicator whether the [relocateSecondary] is already invoked during the
  /// current frame.
  bool _secondaryRelocated = false;

  /// [StreamSubscription] for canceling a reconnection sound.
  StreamSubscription? _reconnectAudio;

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

  /// [Duration] to display a single [CallNotification].
  static const Duration _notificationDuration = Duration(seconds: 6);

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

  /// [FixedTimer] for updating [duration] of the call.
  ///
  /// Starts once the [state] becomes [OngoingCallState.active].
  FixedTimer? _durationTimer;

  /// [Timer] toggling [showUi] value.
  Timer? _uiTimer;

  /// Worker capturing any [buttons] changes to update the
  /// [ApplicationSettings.callButtons] value.
  Worker? _buttonsWorker;

  /// Worker capturing any [ApplicationSettings.callButtons] changes to update
  /// the [buttons] value.
  Worker? _settingsWorker;

  /// Worker capturing any [OngoingCall.connectionLost] changes to play
  /// reconnect sound.
  Worker? _reconnectWorker;

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

  /// [Worker]s reacting on [CallMember.isConnected] or [CallMember.joinedAt]
  /// changes playing the [_connected] sound.
  final Map<CallMemberId, Worker> _memberWorkers = {};

  /// Subscription for [OngoingCall.members] changes updating the title.
  StreamSubscription? _titleSubscription;

  /// Subscription for [duration] changes updating the title.
  StreamSubscription? _durationSubscription;

  /// Subscription for [OngoingCall.notifications] updating the [notifications].
  StreamSubscription? _notificationsSubscription;

  /// Subscription for the [chat] changes.
  StreamSubscription? _chatSubscription;

  /// Subscription for the [proximityEvents] dimming the screen.
  StreamSubscription? _proximitySubscription;

  /// [Worker] reacting on [OngoingCall.chatId] changes to fetch the new [chat].
  late final Worker _chatWorker;

  /// [Timer]s removing items from the [notifications] after the
  /// [_notificationDuration].
  final List<Timer> _notificationTimers = [];

  /// [Sentry] transaction monitoring this [CallController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.call.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  );

  /// [Timer] setting [hidden] to `false` on timeout.
  Timer? _hiddenTimer;

  /// Returns the [ChatId] of the [Chat] this [OngoingCall] is taking place in.
  Rx<ChatId> get chatId => _currentCall.value.chatId;

  /// State of the current [OngoingCall] progression.
  Rx<OngoingCallState> get state => _currentCall.value.state;

  /// Returns a [CallMember] of the currently authorized [MyUser].
  CallMember get me => _currentCall.value.me;

  /// Indicates whether the current authorized [MyUser] is the caller.
  bool get outgoing => _currentCall.value.outgoing;

  /// Indicates whether the current [OngoingCall] has started or not.
  bool get started => _currentCall.value.conversationStartedAt != null;

  /// Indicates whether the current [OngoingCall] is with video or not.
  bool get withVideo => _currentCall.value.withVideo ?? false;

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
  String? get callerName => _currentCall.value.caller?.title();

  /// Indicates whether the connection to the [OngoingCall] updates was lost and
  /// an ongoing reconnection is happening.
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
        final Size size = router.context!.mediaQuerySize;
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

  /// Returns the [AudioSpeakerKind] of the used output device.
  AudioSpeakerKind get speaker =>
      _currentCall.value.outputDevice.value?.speaker ??
      _currentCall.value.devices.output().firstOrNull?.speaker ??
      AudioSpeakerKind.earpiece;

  /// Constructs the arguments to pass to [L10nExtension.l10nfmt] to get the
  /// title of this [OngoingCall].
  Map<String, String> get titleArguments {
    final Map<String, String> args = {
      'title': chat.value?.title() ?? ('dot'.l10n * 3),
      'state': state.value.name,
    };

    bool isOutgoing =
        (outgoing || state.value == OngoingCallState.local) && !started;
    if (isOutgoing) {
      args['type'] = 'outgoing';
    } else if (withVideo) {
      args['type'] = 'video';
    } else {
      args['type'] = 'audio';
    }

    switch (state.value) {
      case OngoingCallState.local:
      case OngoingCallState.pending:
        // No-op.
        break;

      case OngoingCallState.active:
        final Set<UserId> actualMembers = members.keys
            .where((e) => e.deviceId != null)
            .map((k) => k.userId)
            .toSet();
        args['members'] = '${actualMembers.length}';
        args['allMembers'] = '${chat.value?.chat.value.membersCount ?? 1}';

        if (Config.disableInfiniteAnimations) {
          args['duration'] = Duration.zero.hhMmSs();
        } else {
          args['duration'] = duration.value.hhMmSs();
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

  /// Returns the name of an end call sound asset.
  String get _endCall => 'end_call.wav';

  /// Returns the name of a new connection sound asset.
  String get _connected => 'connected.mp3';

  /// Returns the name of a reconnect sound asset.
  String get _reconnect => 'reconnect.mp3';

  @override
  void onInit() {
    ISentrySpan span = _ready.startChild('init');

    super.onInit();

    _currentCall.value.init(getChat: _chatService.get);

    HardwareKeyboard.instance.addHandler(_onKey);
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    speakerSwitched = RxBool(!PlatformUtils.isIOS);

    fullscreen = RxBool(false);
    minimized = RxBool(!PlatformUtils.isMobile && !WebUtils.isPopup);
    isMobile = PlatformUtils.isMobile;

    _hiddenTimer = Timer(const Duration(seconds: 1), () {
      if (hidden.value) {
        hidden.value = false;
        refresh();
      }
    });

    _applyRect(null);
    _settingsRepository.getCallRect(_currentCall.value.chatId.value).then((v) {
      if (hidden.value) {
        hidden.value = false;
        refresh();
      }
      _applyRect(v);
    });

    final double secondarySize = (size.shortestSide * secondaryRatio).clamp(
      _minSHeight,
      250,
    );
    secondaryWidth = RxDouble(secondarySize);
    secondaryHeight = RxDouble(secondarySize);

    _chatWorker = ever(_currentCall.value.chatId, (ChatId id) {
      final FutureOr<RxChat?> chatOrFuture = _chatService.get(id);

      if (chatOrFuture is RxChat?) {
        _updateChat(chatOrFuture);
      } else {
        chatOrFuture.then(_updateChat);
      }
    });

    _stateWorker = ever(state, (OngoingCallState state) {
      switch (state) {
        case OngoingCallState.active:
          if (_durationTimer == null) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              dockRect.value = dockKey.globalPaintBounds;
              relocateSecondary();
            });
            DateTime begunAt = DateTime.now();
            _durationTimer = FixedTimer.periodic(
              const Duration(seconds: 1),
              () {
                duration.value = DateTime.now().difference(begunAt);
                if (hoveredParticipantTimeout > 0 &&
                    draggedRenderer.value == null) {
                  --hoveredParticipantTimeout;
                  if (hoveredParticipantTimeout == 0) {
                    hoveredParticipant.value = null;
                    isCursorHidden.value = true;
                  }
                }
              },
            );

            keepUi();
            _ensureNotEarpiece();
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
        hoveredParticipant.value = null;
        if (_uiTimer?.isActive != true) {
          if (displayMore.isTrue) {
            keepUi();
          } else {
            keepUi(false);
          }
        }
      }
    });

    // Constructs a list of [CallButton]s from the provided [list] of [String]s.
    List<CallButton> toButtons(List<String>? list) {
      Set<CallButton>? persisted = list
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
          .nonNulls
          .toSet();

      // Add default [CallButton]s, if none are persisted.
      if (persisted?.isNotEmpty != true) {
        persisted = {
          ScreenButton(this),
          AudioButton(this),
          VideoButton(this),
          MoreButton(this),
          EndCallButton(this),
        };
      }

      // Ensure [EndCallButton] is always in the list.
      if (persisted!.whereType<EndCallButton>().isEmpty) {
        persisted.add(EndCallButton(this));
      }

      // Ensure [MoreButton] is always in the list.
      if (persisted.whereType<MoreButton>().isEmpty) {
        persisted.add(MoreButton(this));
      }

      return persisted.toList();
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

    List<CallButton> previousButtons = buttons.toList();
    _buttonsWorker = ever(buttons, (List<CallButton> buttons) {
      if (!const ListEquality().equals(previousButtons, buttons)) {
        previousButtons = buttons.toList();
        _settingsRepository.setCallButtons(
          buttons.map((e) => e.runtimeType.toString()).toList(),
        );
      }
    });

    List<String>? previous =
        _settingsRepository.applicationSettings.value?.callButtons;
    _settingsWorker = ever(_settingsRepository.applicationSettings, (
      ApplicationSettings? settings,
    ) {
      if (!const ListEquality().equals(settings?.callButtons, previous)) {
        if (settings != null) {
          buttons.value = toButtons(settings.callButtons);
        }
        previous = settings?.callButtons;
      }
    });

    _showUiWorker = ever(showUi, (bool showUi) {
      if (displayMore.value && !showUi) {
        displayMore.value = false;
      }
    });

    _notificationsSubscription = _currentCall.value.notifications.listen((e) {
      notifications.add(e);
      _notificationTimers.add(
        Timer(_notificationDuration, () => notifications.remove(e)),
      );
    });

    _reconnectWorker = ever(_currentCall.value.connectionLost, (b) {
      if (b) {
        _reconnectAudio = AudioUtils.play(
          AudioSource.asset('audio/$_reconnect'),
        );
      } else {
        _reconnectAudio?.cancel();
      }
    });

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      try {
        _proximitySubscription = proximityEvents?.listen((e) {
          Log.debug('[debug] proximityEvents: ${e.getValue()}');
        });
      } catch (e) {
        Log.warning(
          'Failed to initialize proximity sensor: $e',
          '$runtimeType',
        );
      }
    }

    span.finish();
    span = _ready.startChild('chat');
    _initChat();
  }

  @override
  Future<void> onReady() async {
    await CustomMouseCursors.ensureInitialized();
    super.onReady();
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
    _notificationsSubscription?.cancel();
    _buttonsWorker?.dispose();
    _settingsWorker?.dispose();
    _reconnectAudio?.cancel();
    _reconnectWorker?.dispose();
    _hiddenTimer?.cancel();

    secondaryEntry?.remove();

    _settingsRepository.setCallRect(
      chat.value!.id,
      Rect.fromLTWH(left.value, top.value, width.value, height.value),
    );

    if (fullscreen.value) {
      PlatformUtils.exitFullscreen();
    }

    HardwareKeyboard.instance.removeHandler(_onKey);
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.remove(_onBack);
    }

    _membersTracksSubscriptions.forEach((_, v) => v.cancel());
    _memberWorkers.forEach((_, v) => v.dispose());
    _membersSubscription.cancel();

    for (final Timer e in _notificationTimers) {
      e.cancel();
    }
    _notificationTimers.clear();
    _chatSubscription?.cancel();
    _proximitySubscription?.cancel();
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
  }) => _currentCall.value.join(
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
        final MediaDisplayDetails? display = await ScreenShareView.show(
          router.context!,
          _currentCall,
        );

        if (display != null) {
          await _currentCall.value.setScreenShareEnabled(true, device: display);
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
    await _ensureNotEarpiece();
  }

  /// Changes the local video device to the next one from the
  /// [OngoingCall.devices] list.
  Future<void> switchCamera() async {
    if (PlatformUtils.isMobile) {
      keepUi();
    }

    final List<DeviceDetails> cameras = _currentCall.value.devices
        .video()
        .toList();
    if (cameras.length > 1) {
      final DeviceDetails? videoDevice = _currentCall.value.videoDevice.value;
      int selected = videoDevice == null
          ? 0
          : cameras.indexWhere((e) => e.deviceId() == videoDevice.deviceId());
      selected += 1;
      cameraSwitched.toggle();
      await _currentCall.value.setVideoDevice(
        cameras[selected % cameras.length],
      );
    }
  }

  /// Toggles between the speakerphone, earpiece and headphones output.
  Future<void> toggleSpeaker() async {
    if (PlatformUtils.isMobile) {
      keepUi();
    }

    final List<DeviceDetails> outputs = _currentCall.value.devices
        .output()
        .where((e) => e.id() != 'default' && e.deviceId() != 'default')
        .toList();

    if (outputs.length > 1) {
      int index = outputs.indexWhere(
        (e) => e == _currentCall.value.outputDevice.value,
      );

      if (index == -1) {
        index = 0;
      }

      ++index;
      if (index >= outputs.length) {
        index = 0;
      }

      // iOS doesn't allow to use ear-piece, when there're any Bluetooth
      // devices connected.
      if (PlatformUtils.isIOS) {
        if (outputs.any((e) => e.speaker == AudioSpeakerKind.headphones)) {
          if (outputs[index].speaker == AudioSpeakerKind.earpiece) {
            ++index;
            if (index >= outputs.length) {
              index = 0;
            }
          }
        }
      }

      await _currentCall.value.setOutputDevice(outputs[index]);
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

    refresh();
  }

  /// Invokes [focusAll], moving every [Participant] to their `default`, or
  /// [primary], groups.
  void layoutAsPrimary() {
    focusAll();

    showHeader.value = true;
    isCursorHidden.value = false;
  }

  /// Invokes [unfocus] for the [Participant]s of [me], moving it to the
  /// [paneled] group.
  ///
  /// If [floating] is `true`, then sets the [secondaryAlignment] to `null`, or
  /// otherwise to [Alignment.centerRight].
  void layoutAsSecondary({bool floating = false}) {
    showHeader.value = true;
    isCursorHidden.value = false;

    final mine = [...locals, ...focused].where((e) => e.member == me);
    for (final Participant p in mine) {
      unfocus(p);
    }

    if (floating) {
      if (secondaryAlignment.value != null) {
        secondaryBottom.value = 10;
        secondaryRight.value = 10;
        secondaryLeft.value = null;
        secondaryTop.value = null;
        secondaryAlignment.value = null;
      }
    } else {
      secondaryAlignment.value = Alignment.centerRight;
    }
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

    if (!headerHovered) {
      showHeader.value = (enabled ?? true);
    }

    if (state.value == OngoingCallState.active &&
        enabled == null &&
        !isPanelOpen.value) {
      _uiTimer = Timer(const Duration(seconds: _uiDuration), () {
        showUi.value = false;
        showHeader.value = false;

        if (!headerHovered) {
          showHeader.value = false;
        }
      });
    }
  }

  /// Centers the [participant], which means [focus]ing the [participant] and
  /// [unfocus]ing every participant in [focused].
  void center(Participant participant) {
    paneled.remove(participant);
    locals.remove(participant);
    remotes.remove(participant);
    focused.remove(participant);

    for (Participant r in List.from(focused, growable: false)) {
      _putVideoFrom(r, focused);
    }

    focused.add(participant);
    _ensureCorrectGrouping();
  }

  /// Focuses [participant], which means putting in to the [focused].
  ///
  /// If [participant] is [paneled], then it will be placed to the [focused] if
  /// it's not empty, or to its `default` group otherwise.
  void focus(Participant participant) {
    if (focused.isNotEmpty) {
      if (paneled.contains(participant)) {
        focused.add(participant);
        paneled.remove(participant);
      } else {
        _putVideoTo(participant, focused);
      }

      _ensureCorrectGrouping();
    } else {
      if (paneled.contains(participant)) {
        _putVideoFrom(participant, paneled);
        _ensureCorrectGrouping();
      }
    }
  }

  /// Unfocuses [participant], which means putting it in its `default` group.
  void unfocus(Participant participant) {
    if (focused.contains(participant)) {
      _putVideoFrom(participant, focused);
      if (focused.isEmpty) {
        unfocusAll();
      }

      _ensureCorrectGrouping();
    } else {
      if (!paneled.contains(participant)) {
        _putVideoTo(participant, paneled);
        _ensureCorrectGrouping();
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

    _ensureCorrectGrouping();
  }

  /// [unfocus]es all [Participant]s, which means putting them in the [paneled]
  /// group.
  void unfocusAll() {
    for (Participant r in List.from([
      ...focused,
      ...locals,
      ...remotes,
    ], growable: false)) {
      _putVideoTo(r, paneled);
    }

    _ensureCorrectGrouping();
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
      initial: isGroup
          ? ParticipantsFlowStage.participants
          : ParticipantsFlowStage.search,
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
  FutureOr<RxUser?> getUser(UserId id) => _userService.get(id);

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
        secondaryBottomShifted ??=
            secondaryBottom.value ??
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
        double bottom =
            secondaryBottom.value ??
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

      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _secondaryRelocated = false,
      );
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
      secondaryTop.value =
          offset.dy -
          ((WebUtils.isPopup || router.context!.isMobile) ? 0 : titleHeight) -
          secondaryPanningOffset!.dy;
    } else if (WebUtils.isPopup) {
      secondaryLeft.value = offset.dx - secondaryPanningOffset!.dx;
      secondaryTop.value = offset.dy - secondaryPanningOffset!.dy;
    } else {
      secondaryLeft.value =
          offset.dx -
          (router.context!.isMobile ? 0 : left.value) -
          secondaryPanningOffset!.dx;
      secondaryTop.value =
          offset.dy -
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
      final RxnDouble xPrimaryOffset = x == ScaleModeX.left
          ? secondaryLeft
          : secondaryRight;
      final RxnDouble xSecondaryOffset = x == ScaleModeX.left
          ? secondaryRight
          : secondaryLeft;

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
      final RxnDouble yPrimaryOffset = y == ScaleModeY.top
          ? secondaryTop
          : secondaryBottom;
      final RxnDouble ySecondaryOffset = y == ScaleModeY.top
          ? secondaryBottom
          : secondaryTop;

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
      final dif =
          (constraints.maxWidth + constraints.maxHeight) -
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
    late double Function(double) applyAxisSize;

    switch (axis) {
      case Axis.horizontal:
        sizeAxis = secondaryWidth;
        applyAxisSize = _applySWidth;
        break;

      case Axis.vertical:
        sizeAxis = secondaryHeight;
        applyAxisSize = _applySHeight;
        break;
    }

    final double previousSize = sizeAxis.value;

    sizeAxis.value = applyAxisSize(sizeAxis.value - delta);
    sideOffset.value = applyOffset(
      sideOffset.value! + (previousSize - sizeAxis.value),
    );
  }

  /// Invokes [minimize], if not [minimized] already.
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo _) {
    if (minimized.isFalse) {
      minimize();
      return true;
    }

    return false;
  }

  /// Puts [participant] from its `default` group to [list].
  void _putVideoTo(Participant participant, RxList<Participant> list) {
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
        locals.addIf(!locals.contains(participant), participant);
        list.remove(participant);
        break;

      case MediaOwnerKind.remote:
        remotes.addIf(!remotes.contains(participant), participant);
        list.remove(participant);
        break;
    }
  }

  /// Ensures the [paneled] and [focused] are in correct state, and fixes the
  /// state if not.
  void _ensureCorrectGrouping() {
    if (locals.isEmpty && remotes.isEmpty) {
      // If every [RtcVideoRenderer] is in focus, then put everyone outside of
      // it.
      if (paneled.isEmpty && focused.isNotEmpty) {
        final List<Participant> copy = List.from(focused, growable: false);
        for (final Participant p in copy) {
          _putVideoFrom(p, focused);
        }
      }
    }

    locals.refresh();
    remotes.refresh();
    paneled.refresh();
    focused.refresh();

    primary.value = focused.isNotEmpty ? focused : [...locals, ...remotes];
    secondary.value = focused.isNotEmpty
        ? [...locals, ...paneled, ...remotes]
        : paneled;

    applySecondaryConstraints();
  }

  /// Returns all [Participant]s identified by an [id] and [source].
  Iterable<Participant> _findParticipants(
    CallMemberId id, [
    MediaSourceKind? source,
  ]) {
    source ??= MediaSourceKind.device;
    return [
      ...locals.where((e) => e.member.id == id && e.source == source),
      ...remotes.where((e) => e.member.id == id && e.source == source),
      ...paneled.where((e) => e.member.id == id && e.source == source),
      ...focused.where((e) => e.member.id == id && e.source == source),
    ];
  }

  /// Puts the [CallMember.tracks] to the according [Participant].
  void _putTracksFrom(CallMember member) {
    if (member.tracks.none((t) => t.source == MediaSourceKind.device)) {
      _putTrackFrom(member, null);
    }

    for (final Track track in member.tracks) {
      _putTrackFrom(member, track);
    }
  }

  /// Puts the provided [track] to the [Participant] this [member] represents.
  ///
  /// If no suitable [Participant]s for this [track] are found, then a new
  /// [Participant] with this [track] is added.
  void _putTrackFrom(CallMember member, Track? track) {
    final Iterable<Participant> participants = _findParticipants(
      member.id,
      track?.source,
    );

    if (participants.isEmpty) {
      final Participant participant = Participant(
        member,
        video: track?.kind == MediaKind.video ? track : null,
        audio: track?.kind == MediaKind.audio ? track : null,
      );

      final FutureOr<RxUser?> userOrFuture = _userService.get(member.id.userId);
      if (userOrFuture is RxUser?) {
        participant.user.value = userOrFuture ?? participant.user.value;
      } else {
        userOrFuture.then(
          (user) => participant.user.value = user ?? participant.user.value,
        );
      }

      switch (member.owner) {
        case MediaOwnerKind.local:
          if (isGroup || isMonolog) {
            switch (participant.source) {
              case MediaSourceKind.device:
                locals.add(participant);
                break;

              case MediaSourceKind.display:
                paneled.add(participant);
                break;
            }
          } else {
            paneled.add(participant);
          }

          if (state.value == OngoingCallState.local || outgoing) {
            SchedulerBinding.instance.addPostFrameCallback(
              (_) => relocateSecondary(),
            );
          }
          break;

        case MediaOwnerKind.remote:
          switch (participant.source) {
            case MediaSourceKind.device:
              remotes.add(participant);
              break;

            case MediaSourceKind.display:
              focused.add(participant);
              break;
          }
          break;
      }
    } else {
      if (track != null) {
        final Participant participant = participants.first;
        participant.member = member;
        if (track.kind == MediaKind.video) {
          participant.video.value = track;
        } else {
          participant.audio.value = track;
        }
      }
    }
  }

  /// Removes [Participant] this [member] represents with the provided [track].
  void _removeParticipant(CallMember member, Track track) {
    final Iterable<Participant> participants = _findParticipants(
      member.id,
      track.source,
    );

    if (track.kind == MediaKind.video) {
      if (participants.length == 1 && track.source == MediaSourceKind.device) {
        participants.first.video.value = null;
      } else {
        final Participant? participant = participants.firstWhereOrNull(
          (p) => p.video.value == track,
        );
        if (participant != null) {
          locals.remove(participant);
          remotes.remove(participant);
          paneled.remove(participant);
          focused.remove(participant);
        }
      }
    } else {
      final Participant? participant = participants.firstWhereOrNull(
        (p) => p.audio.value == track,
      );
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

  /// Ensures [OngoingCall.outputDevice] is not an earpiece, if [videoState] is
  /// enabled.
  ///
  /// Only meaningful on mobile devices.
  Future<void> _ensureNotEarpiece() async {
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      if (videoState.value.isEnabled && speaker == AudioSpeakerKind.earpiece) {
        final List<DeviceDetails> outputs = _currentCall.value.devices
            .output()
            .where((e) => e.id() != 'default' && e.deviceId() != 'default')
            .toList();

        final DeviceDetails? speakerphone = outputs.firstWhereOrNull(
          (e) => e.speaker == AudioSpeakerKind.speaker,
        );

        if (speakerphone != null) {
          await _currentCall.value.setOutputDevice(speakerphone);
        }
      }
    }
  }

  /// Initializes the [chat] and adds the [CallMember] afterwards.
  Future<void> _initChat() async {
    try {
      final FutureOr<RxChat?> chatOrFuture = _chatService.get(chatId.value);
      if (chatOrFuture is RxChat?) {
        _updateChat(chatOrFuture);
      } else {
        _updateChat(await chatOrFuture);
      }
    } catch (e) {
      _ready.throwable = e;
      _ready.finish(status: const SpanStatus.internalError());
      rethrow;
    } finally {
      SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());

      void onTracksChanged(
        CallMember member,
        ListChangeNotification<Track> track,
      ) {
        switch (track.op) {
          case OperationKind.added:
            _putTrackFrom(member, track.element);
            _ensureCorrectGrouping();
            break;

          case OperationKind.removed:
            _removeParticipant(member, track.element);
            _ensureCorrectGrouping();
            break;

          case OperationKind.updated:
            // No-op.
            break;
        }
      }

      _membersTracksSubscriptions = members.map(
        (k, v) =>
            MapEntry(k, v.tracks.changes.listen((c) => onTracksChanged(v, c))),
      );

      _membersSubscription = members.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
            _putTracksFrom(e.value!);
            _membersTracksSubscriptions[e.key!] = e.value!.tracks.changes
                .listen((c) => onTracksChanged(e.value!, c));

            _ensureCorrectGrouping();
            _playConnected(e.value!);
            break;

          case OperationKind.removed:
            bool wasNotEmpty = primary.isNotEmpty;
            paneled.removeWhere((m) => m.member.id == e.key);
            locals.removeWhere((m) => m.member.id == e.key);
            focused.removeWhere((m) => m.member.id == e.key);
            remotes.removeWhere((m) => m.member.id == e.key);
            _membersTracksSubscriptions.remove(e.key)?.cancel();
            _memberWorkers.remove(e.key)?.dispose();
            _ensureCorrectGrouping();
            if (wasNotEmpty && primary.isEmpty) {
              focusAll();
            }

            // Play a sound when the last connected [CallMember] except [MyUser]
            // leaves the call.
            final bool isActiveCall =
                _currentCall.value.state.value == OngoingCallState.active;
            final bool myUserIsAlone =
                members.values.where((m) => m.isConnected.value).length == 1;

            // React to removal of connected [CallMember]s only.
            final bool wasConnected = e.value?.isConnected.value ?? false;
            if (isGroup && isActiveCall && wasConnected && myUserIsAlone) {
              AudioUtils.once(AudioSource.asset('audio/$_endCall'));
            }
            break;

          case OperationKind.updated:
            _ensureCorrectGrouping();
            break;
        }
      });

      members.forEach((_, value) {
        _putTracksFrom(value);
        _playConnected(value);
      });

      _ensureCorrectGrouping();
    }
  }

  /// Plays the [_connected] sound or initializes [_memberWorkers] for the
  /// provided [member].
  Future<void> _playConnected(CallMember member) async {
    final CallMember me = _currentCall.value.me;

    if (member.isConnected.isFalse) {
      _listenToConnected(member);
    } else if (member.joinedAt.value == null) {
      _listenToJoinedAt(member);
    } else if (_currentCall.value.state.value == OngoingCallState.active &&
        me.joinedAt.value != null &&
        member.joinedAt.value!.isAfter(me.joinedAt.value!)) {
      await AudioUtils.once(AudioSource.asset('audio/$_connected'));
    }
  }

  /// Initializes [_memberWorkers] for the provided [CallMember.isConnected].
  void _listenToConnected(CallMember member) {
    _memberWorkers.remove(member.id)?.dispose();
    _memberWorkers[member.id] = ever(member.isConnected, (connected) async {
      if (connected) {
        _memberWorkers.remove(member.id)?.dispose();
        await _playConnected(member);
      }
    });
  }

  /// Initializes [_memberWorkers] for the provided [CallMember.joinedAt].
  void _listenToJoinedAt(CallMember member) {
    _memberWorkers.remove(member.id)?.dispose();
    _memberWorkers[member.id] = ever(member.joinedAt, (joinedAt) async {
      if (joinedAt != null) {
        _memberWorkers.remove(member.id)?.dispose();
        await _playConnected(member);
      }
    });
  }

  /// Sets the [chat] to the provided value, updating the title.
  void _updateChat(RxChat? v) {
    _chatSubscription?.cancel();
    chat.value = v;
    _chatSubscription = chat.value?.updates.listen((_) {});
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
            '\u205f​​​ \u205f​​​${'label_call_title'.l10nfmt(titleArguments)}\u205f​​​ \u205f​​​',
          );
        }

        updateTitle();

        _titleSubscription = members.listen((_) => updateTitle());
        _durationSubscription = duration.listen((_) => updateTitle());
      }
    }
  }

  /// Applies the [prefs] to form [width], [height], [left] and [top] positions.
  void _applyRect(Rect? prefs) {
    final Size size = router.context!.mediaQuerySize;

    if (isMobile) {
      final Size size = router.context!.mediaQuerySize;
      width.value = prefs?.width ?? size.width;
      height.value = prefs?.height ?? size.height;
    } else {
      width.value =
          prefs?.width ??
          min(
            max(min(500, size.shortestSide * _maxWidth), _minWidth),
            size.height * _maxHeight,
          );
      height.value = prefs?.height ?? width.value;
    }

    left.value = size.width - width.value - 50 > 0
        ? prefs?.left ?? size.width - width.value - 50
        : prefs?.left ?? size.width / 2 - width.value / 2;
    top.value = height.value + 50 < size.height
        ? prefs?.top ?? 50
        : prefs?.top ?? size.height / 2 - height.value / 2;
  }
}

/// X-axis scale mode.
enum ScaleModeX { left, right }

/// Y-axis scale mode.
enum ScaleModeY { top, bottom }

/// Separate call entity participating in a call.
class Participant {
  Participant(this.member, {Track? video, Track? audio, RxUser? user})
    : user = Rx(user),
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

  /// [BoxFit] this [Participant] is rendered with.
  final Rx<BoxFit?> fit = Rx(null);

  /// Returns the [MediaSourceKind] of this [Participant].
  MediaSourceKind get source =>
      video.value?.source ?? audio.value?.source ?? MediaSourceKind.device;
}
