import 'package:flutter/material.dart';

import '/domain/model/my_user.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/routes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/widget_button.dart';

/// [ContactTile] intended to be used as a selectable tile representing the
/// provided [User], [ChatContact] or [MyUser].
class SelectedUserTile extends StatelessWidget {
  const SelectedUserTile({
    super.key,
    this.user,
    this.myUser,
    this.contact,
    this.selected = false,
    this.subtitle = const [],
    this.onTap,
  });

  /// [RxUser] this [SelectedUserTile] is about.
  final RxUser? user;

  /// [MyUser] this [SelectedUserTile] is about.
  final MyUser? myUser;

  /// [RxChatContact] this [SelectedUserTile] is about.
  final RxChatContact? contact;

  /// Indicator whether this [SelectedUserTile] is selected.
  final bool selected;

  /// Optional subtitle [Widget]s to put into [ContactTile.subtitle].
  final List<Widget> subtitle;

  /// Callback, called when this [SelectedUserTile] is pressed.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Stack(
        children: [
          ContactTile(
            contact: contact,
            user: user,
            myUser: myUser,
            selected: selected,
            subtitle: subtitle,
            trailing: [
              if (myUser == null)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selected
                        ? CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            radius: 12,
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD7D7D7),
                                width: 1,
                              ),
                            ),
                            width: 24,
                            height: 24,
                          ),
                  ),
                ),
            ],
          ),
          Positioned.fill(
            child: Row(
              children: [
                WidgetButton(
                  onPressed: () => router.user(
                    user?.id ?? contact?.user.value?.id ?? myUser!.id,
                  ),
                  child: const SizedBox(width: 60, height: double.infinity),
                ),
                Expanded(
                  child: WidgetButton(onPressed: onTap, child: Container()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
