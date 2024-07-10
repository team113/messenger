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

import 'package:get/get.dart';

import '../util/log.dart';
import '/domain/model/chat_item.dart';
import '/domain/repository/chat.dart';
import '/provider/drift/chat_item.dart';
import '/provider/drift/chat.dart';
import '/store/model/chat_item.dart';
import 'chat.dart';
import 'chat_rx.dart';

/// [RxChat] implementation backed by local storage.
class RxChatItemImpl extends RxChatItem {
  RxChatItemImpl(
    this._chat,
    this._driftItems,
    DtoChatItem dto,
  ) : rx = Rx<ChatItem>(dto.value);

  @override
  final Rx<ChatItem> rx;

  /// [ChatRepository] used to cooperate with the other [RxChatImpl]s.
  final RxChatImpl _chat;

  /// [ChatItem]s local storage.
  final ChatItemDriftProvider _driftItems;

  /// [ChatDriftProvider.watch] subscription.
  StreamSubscription? _localSubscription;

  void init() {
    _initLocalSubscription();
  }

  void dispose() {
    _localSubscription?.cancel();
  }

  /// Initializes the [_localSubscription].
  void _initLocalSubscription() {
    // _localSubscription?.cancel();
    // _localSubscription = _driftItems.watchSingle(id).listen(
    //   (e) async {
    //     Log.info('$e', '$runtimeType($id)');

    //     if (e != null) {
    //       rx.value = e.value;
    //     } else {
    //       await _chat.remove(id);
    //     }
    //   },
    // );
  }
}
