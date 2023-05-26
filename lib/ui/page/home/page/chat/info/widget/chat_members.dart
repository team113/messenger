import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/info/add_member/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// [Widget] which returns a list of [Chat.members].
class ChatMembers extends StatelessWidget {
  const ChatMembers(
    this.id, {
    super.key,
    required this.removeChatCallMember,
    required this.redialChatCallMember,
    this.chat,
    this.me,
    this.removeChatMember,
  });

  /// Reactive [Chat] with chat items.
  final RxChat? chat;

  /// ID of the current user.
  final UserId? me;

  /// ID of the current chat.
  final ChatId id;

  /// Redials the [User] identified by its [userId].
  final void Function(UserId userId) removeChatCallMember;

  /// Removes the specified [User] from a [OngoingCall] happening in the
  /// [chat].
  final void Function(UserId userId) redialChatCallMember;

  /// Opens a confirmation popup removing the provided [user].
  final void Function()? removeChatMember;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final RxUser? rxMe = chat!.members[me];
      final List<RxUser> members = [];

      for (var u in chat!.members.entries) {
        if (u.key != me) {
          members.add(u.value);
        }
      }

      if (rxMe != null) {
        members.insert(0, rxMe);
      }

      final Style style = Theme.of(context).extension<Style>()!;

      Widget bigButton({
        Key? key,
        Widget? leading,
        required Widget title,
        void Function()? onTap,
      }) {
        return SizedBox(
          key: key,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              border: style.cardBorder,
              color: style.colors.transparent,
            ),
            child: Material(
              type: MaterialType.card,
              borderRadius: style.cardRadius,
              color: style.cardColor.darken(0.05),
              child: InkWell(
                borderRadius: style.cardRadius,
                onTap: onTap,
                hoverColor: style.cardColor.darken(0.08),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: DefaultTextStyle(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 15,
                            color: style.colors.primary,
                            fontWeight: FontWeight.w300,
                          ),
                          child: title,
                        ),
                      ),
                      if (leading != null) ...[
                        const SizedBox(width: 12),
                        leading,
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bigButton(
            key: const Key('AddMemberButton'),
            leading: Icon(
              Icons.people,
              color: style.colors.primary,
            ),
            title: Text('btn_add_member'.l10n),
            onTap: () => AddChatMemberView.show(context, chatId: id),
          ),
          const SizedBox(height: 3),
          ...members.map((e) {
            final bool inCall = chat?.chat.value.ongoingCall?.members
                    .any((u) => u.user.id == e.id) ==
                true;

            return ContactTile(
              user: e,
              darken: 0.05,
              dense: true,
              onTap: () => router.user(e.id, push: true),
              trailing: [
                if (e.id != me && chat?.chat.value.ongoingCall != null) ...[
                  if (inCall)
                    WidgetButton(
                      key: const Key('Drop'),
                      onPressed: () => removeChatCallMember(e.id),
                      child: Container(
                        height: 22,
                        width: 22,
                        decoration: BoxDecoration(
                          color: style.colors.dangerColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgImage.asset(
                            'assets/icons/call_end.svg',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                    )
                  else
                    Material(
                      color: style.colors.primary,
                      type: MaterialType.circle,
                      child: InkWell(
                        onTap: () => redialChatCallMember(e.id),
                        borderRadius: BorderRadius.circular(60),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: Center(
                            child: SvgImage.asset(
                              'assets/icons/audio_call_start.svg',
                              width: 10,
                              height: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                ],
                if (e.id == me)
                  WidgetButton(
                    onPressed: () => removeChatMember,
                    child: Text(
                      'btn_leave'.l10n,
                      style:
                          TextStyle(color: style.colors.primary, fontSize: 15),
                    ),
                  )
                else
                  WidgetButton(
                    key: const Key('DeleteMemberButton'),
                    onPressed: () => removeChatMember,
                    child: SvgImage.asset(
                      'assets/icons/delete.svg',
                      height: 14 * 1.5,
                    ),
                  ),
                const SizedBox(width: 6),
              ],
            );
          }),
        ],
      );
    });
  }
}
