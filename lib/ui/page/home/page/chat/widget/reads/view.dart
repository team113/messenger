import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';

import '/ui/widget/modal_popup.dart';
import 'controller.dart';

class ChatItemReadsView extends StatelessWidget {
  const ChatItemReadsView({
    super.key,
    required this.item,
    required this.chat,
    this.getUser,
  });

  final Rx<ChatItem> item;
  final Rx<Chat?> chat;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  /// Displays a [ChatItemReadsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Rx<ChatItem> item,
    required Rx<Chat?> chat,
    Future<RxUser?> Function(UserId userId)? getUser,
  }) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: ChatItemReadsView(item: item, chat: chat, getUser: getUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: ChatItemReadsController(),
      builder: (ChatItemReadsController c) {
        return ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 16 - 12),
            ModalPopupHeader(
              header: Center(
                child: Text(
                  'Read by'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 25 - 12),
            ...(chat.value?.lastReads ?? []).map(
              (e) {
                if (e.at == item.value.at) {
                  return Padding(
                    padding: ModalPopup.padding(context),
                    child: FutureBuilder<RxUser?>(
                      future: getUser?.call(e.memberId),
                      builder: (context, snapshot) {
                        return ContactTile(
                          user: snapshot.data,
                          darken: 0.05,
                          onTap: () {
                            Navigator.of(context).pop();
                            router.user(e.memberId, push: true);
                          },
                        );
                      },
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
