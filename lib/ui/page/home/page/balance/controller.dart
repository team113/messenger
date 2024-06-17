// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/domain/service/balance.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'widget/currency_field.dart';

class BalanceProviderController extends GetxController {
  BalanceProviderController(this._balanceService, this._myUserService);

  final Rx<WebViewController?> webController = Rx(null);

  final List<TextFieldState> states =
      BalanceProvider.values.map((e) => TextFieldState()).toList();
  final List<RxInt> prices =
      BalanceProvider.values.map((e) => RxInt(0)).toList();

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [ItemScrollController] of the profile's [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();

  /// [ItemPositionsListener] of the profile's [ScrollablePositionedList].
  final ItemPositionsListener positionsListener =
      ItemPositionsListener.create();

  final RxnInt highlightIndex = RxnInt(null);

  late final Map<BalanceProvider, RxInt> nominal = {
    for (var e in BalanceProvider.values) e: RxInt(0)
  };

  int listInitIndex = 0;

  final Rx<CurrencyKind> swiftCurrency = Rx(CurrencyKind.usd);
  final RxInt swiftPrice = RxInt(0);
  final RxInt sepaPrice = RxInt(0);

  final BalanceService _balanceService;
  final MyUserService _myUserService;

  /// [Duration] of the highlighting.
  static const Duration _highlightTimeout = Duration(seconds: 1);

  /// [Timer] resetting the [highlightIndex] value after the [_highlightTimeout]
  /// has passed.
  Timer? _highlightTimer;
  Worker? _balanceWorker;

  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    listInitIndex = router.balanceSection.value?.index ?? 0;

    bool ignoreWorker = false;
    bool ignorePositions = false;

    _balanceWorker = ever(
      router.balanceSection,
      (BalanceProvider? tab) async {
        if (ignoreWorker) {
          ignoreWorker = false;
        } else {
          ignorePositions = true;
          await itemScrollController.scrollTo(
            index: tab?.index ?? 0,
            duration: 200.milliseconds,
            curve: Curves.ease,
          );
          Future.delayed(Duration.zero, () => ignorePositions = false);

          highlight(tab);
        }
      },
    );

    positionsListener.itemPositions.addListener(() {
      if (!ignorePositions) {
        final ItemPosition? position =
            positionsListener.itemPositions.value.firstOrNull;

        if (position != null) {
          final BalanceProvider tab = BalanceProvider.values[position.index];
          if (router.balanceSection.value != tab) {
            ignoreWorker = true;
            router.balanceSection.value = tab;
            Future.delayed(Duration.zero, () => ignoreWorker = false);
          }
        }
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    _balanceWorker?.dispose();
    _highlightTimer?.cancel();
  }

  void add(Transaction transaction) {
    _balanceService.add(transaction.amount);
  }

  /// Highlights the provided [provider].
  Future<void> highlight(BalanceProvider? provider) async {
    highlightIndex.value = provider?.index;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightTimeout, () {
      highlightIndex.value = null;
    });
  }
}
