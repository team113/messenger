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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/domain/service/balance.dart';
import 'package:messenger/domain/service/partner.dart';
import 'package:messenger/util/message_popup.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/application_settings.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/routes.dart';
import '/ui/page/home/introduction/view.dart';
import 'introduction/controller.dart';

export 'view.dart';

/// [Routes.home] page controller.
class HomeController extends GetxController {
  HomeController(
    this._auth,
    this._myUserService,
    this._settings,
    this._balanceService,
    this._partnerService, {
    this.signedUp = false,
  });

  /// Indicator whether the [IntroductionView] should be displayed with
  /// [IntroductionViewStage.signUp] initial stage.
  final bool signedUp;

  /// Maximal percentage of the screen's width which side bar can occupy.
  static const double sideBarMaxWidthPercentage = 0.5;

  /// Minimal width of the side bar.
  static const double sideBarMinWidth = 250;

  /// Current width of the side bar.
  late final RxDouble sideBarWidth;

  /// Controller of the [PageView] tab.
  late PageController pages;

  /// Current [pages] [HomeTab] value.
  late final Rx<HomeTab> page;

  /// Reactive [MyUser.unreadChatsCount] value.
  final Rx<int> unreadChatsCount = Rx<int>(0);

  /// [Timer] for discarding any horizontal movement in a [PageView] when
  /// non-`null`.
  ///
  /// Indicates currently ongoing vertical scroll of a view.
  final Rx<Timer?> verticalScrollTimer = Rx(null);

  /// [GlobalKey] of an [AvatarWidget] in the navigation bar.
  ///
  /// Used to position a status changing [Selector] properly.
  final GlobalKey profileKey = GlobalKey();

  /// [GlobalKey] of a [Chat]s button in the navigation bar.
  final GlobalKey chatsKey = GlobalKey();

  final GlobalKey publicsKey = GlobalKey();
  final GlobalKey partnerKey = GlobalKey();
  final GlobalKey balanceKey = GlobalKey();

  final RxBool publicsToggle = RxBool(false);

  final Map<HomeTab, GlobalKey> keys = Map.fromEntries(
    List.generate(
      HomeTab.values.length,
      (i) => MapEntry(HomeTab.values[i], GlobalKey()),
    ),
  );

  /// Authentication service to determine auth status.
  final AuthService _auth;

  /// [MyUserService] to listen to the [MyUser] changes.
  final MyUserService _myUserService;

  /// [AbstractSettingsRepository] containing the [ApplicationSettings] used to
  /// determine whether an [IntroductionView] was already shown.
  final AbstractSettingsRepository _settings;

  final BalanceService _balanceService;
  final PartnerService _partnerService;

  /// Subscription to the [MyUser] changes.
  late final StreamSubscription _myUserSubscription;

  /// Returns user authentication status.
  Rx<RxStatus> get authStatus => _auth.status;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the width side bar is allowed to occupy.
  double get sideBarAllowedWidth =>
      _settings.applicationSettings.value?.sideBarWidth ?? 350;

  bool get displayFunds =>
      _settings.applicationSettings.value?.displayFunds ?? true;

  bool get displayTransactions =>
      _settings.applicationSettings.value?.displayTransactions ?? true;

  /// Returns the background's [Uint8List].
  Rx<Uint8List?> get background => _settings.background;

  RxDouble get balance => _balanceService.balance;
  RxList<Transaction> get transactions => _partnerService.transactions;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings => _settings.applicationSettings;

  @override
  void onInit() {
    super.onInit();
    page = Rx<HomeTab>(router.tab);
    pages = PageController(initialPage: page.value.index, keepPage: true);

    unreadChatsCount.value = _myUserService.myUser.value?.unreadChatsCount ?? 0;
    _myUserSubscription = _myUserService.myUser.listen((u) =>
        unreadChatsCount.value = u?.unreadChatsCount ?? unreadChatsCount.value);

    sideBarWidth =
        RxDouble(_settings.applicationSettings.value?.sideBarWidth ?? 350);

    bool partner = settings.value?.partnerTabEnabled != false;
    bool balance = settings.value?.balanceTabEnabled != false;

    ever(settings, (ApplicationSettings? settings) {
      if (partner != settings?.partnerTabEnabled) {
        partner = settings?.partnerTabEnabled ?? false;

        if (partner) {
          if (router.tab.index < HomeTab.work.index) {
          } else {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              pages.jumpToPage(
                min(router.tab.index + 1, HomeTab.values.length - 1),
              );
            });
          }
        } else {
          if (router.tab.index <= HomeTab.work.index) {
          } else {
            pages.jumpToPage(max(router.tab.index - 1, 0));
          }
        }
      }

      if (balance != settings?.balanceTabEnabled) {
        balance = settings?.balanceTabEnabled ?? false;
      }
    });

    router.addListener(_onRouterChanged);
  }

  @override
  void onReady() {
    super.onReady();
    pages.jumpToPage(router.tab.index);
    refresh();

    if (_settings.applicationSettings.value?.showIntroduction ?? true) {
      if (_myUserService.myUser.value != null) {
        _displayIntroduction(_myUserService.myUser.value!);
      } else {
        Worker? worker;
        worker = ever(
          _myUserService.myUser,
          (MyUser? myUser) {
            if (myUser != null && worker != null) {
              _displayIntroduction(myUser);
              worker?.dispose();
              worker = null;
            }
          },
        );
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
    router.removeListener(_onRouterChanged);
    _myUserSubscription.cancel();
  }

  /// Returns corrected according to the side bar constraints [width] value.
  double applySideBarWidth(double width) {
    double maxWidth = router.context!.width * sideBarMaxWidthPercentage;

    if (maxWidth < sideBarMinWidth) {
      maxWidth = sideBarMinWidth;
    }

    return width.clamp(sideBarMinWidth, maxWidth);
  }

  /// Sets the current [sideBarWidth] as the [sideBarAllowedWidth].
  Future<void> setSideBarWidth() =>
      _settings.setSideBarWidth(sideBarWidth.value);

  /// Sets the [MyUser.presence] to the provided value.
  Future<void> setPresence(Presence presence) =>
      _myUserService.updateUserPresence(presence);

  /// Indicator whether there's an ongoing [toggleMute] happening.
  ///
  /// Used to discard repeated toggling.
  final RxBool isMuting = RxBool(false);

  /// Toggles the [MyUser.muted] status.
  Future<void> toggleMute(bool enabled) async {
    if (!isMuting.value) {
      isMuting.value = true;

      try {
        await _myUserService.toggleMute(
          enabled ? null : MuteDuration.forever(),
        );
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      } finally {
        isMuting.value = false;
      }
    }
  }

  void setDisplayTransactions(bool b) => _settings.setDisplayTransactions(b);

  void setDisplayFunds(bool b) => _settings.setDisplayFunds(b);

  void setPartnerTabEnabled(bool b) => _settings.setPartnerTabEnabled(b);
  void setBalanceTabEnabled(bool b) => _settings.setBalanceTabEnabled(b);
  void setPublicsTabEnabled(bool b) => _settings.setPublicsTabEnabled(b);

  /// Refreshes the controller on [router] change.
  ///
  /// Required in order for the [BottomNavigatorBar] to rebuild.
  void _onRouterChanged() {
    if (pages.hasClients) {
      if (pages.page?.round() != router.tab.index) {
        pages.jumpToPage(router.tab.index);
      }
      refresh();
    }
  }

  /// Displays an [IntroductionView] if [MyUser.hasPassword] is `false`.
  void _displayIntroduction(MyUser myUser) {
    IntroductionViewStage? stage;

    if (!myUser.hasPassword &&
        myUser.emails.confirmed.isEmpty &&
        myUser.phones.confirmed.isEmpty) {
      stage = IntroductionViewStage.oneTime;
    } else if (signedUp) {
      stage = IntroductionViewStage.signUp;
    }

    if (stage != null) {
      IntroductionView.show(router.context!, initial: stage)
          .then((_) => _settings.setShowIntroduction(false));
    } else {
      _settings.setShowIntroduction(false);
    }
  }
}
