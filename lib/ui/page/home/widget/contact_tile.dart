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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';

class ContactTile extends StatelessWidget {
  const ContactTile({
    Key? key,
    this.contact,
    this.user,
    this.myUser,
    this.leading = const [],
    this.trailing = const [],
    this.onTap,
    this.selected = false,
    this.darken = 0.05,
    this.actions,
    this.canDelete = false,
    this.onDelete,
    this.folded = false,
    this.subtitle = const [],
    this.preventContextMenu = false,
    this.radius = 26,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
  }) : super(key: key);

  final RxChatContact? contact;
  final RxUser? user;
  final MyUser? myUser;

  final List<Widget> leading;
  final List<Widget> trailing;

  final bool canDelete;
  final void Function()? onDelete;

  final void Function()? onTap;
  final bool selected;
  final double darken;
  final bool folded;

  final bool preventContextMenu;
  final List<ContextMenuButton>? actions;
  final EdgeInsets margin;

  final List<Widget> subtitle;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;

    return Container(
      margin: margin,
      child: ContextMenuRegion(
        key: contact != null || user != null
            ? Key('ContextMenuRegion_${contact?.id ?? user?.id ?? myUser?.id}')
            : null,
        preventContextMenu: preventContextMenu,
        actions: actions,
        child: ClipPath(
          clipper: folded
              ? _FoldedClipper(radius: style.cardRadius.topLeft.x)
              : null,
          child: Stack(
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 76),
                decoration: BoxDecoration(
                  borderRadius: style.cardRadius,
                  border: style.cardBorder,
                  color: Colors.transparent,
                ),
                child: Material(
                  type: MaterialType.card,
                  borderRadius: style.cardRadius,
                  color: selected
                      ? const Color(0xFFD7ECFF).withOpacity(0.8)
                      : style.cardColor.darken(darken),
                  child: InkWell(
                    borderRadius: style.cardRadius,
                    onTap: onTap,
                    hoverColor: selected
                        ? const Color(0x00D7ECFF)
                        : const Color.fromARGB(255, 244, 249, 255),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        children: [
                          ...leading,
                          if (contact != null)
                            AvatarWidget.fromRxContact(contact, radius: radius)
                          else if (user != null)
                            AvatarWidget.fromRxUser(user, radius: radius)
                          else
                            AvatarWidget.fromMyUser(myUser, radius: radius),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        contact?.contact.value.name.val ??
                                            contact?.user.value?.user.value.name
                                                ?.val ??
                                            contact?.user.value?.user.value.num
                                                .val ??
                                            user?.user.value.name?.val ??
                                            user?.user.value.num.val ??
                                            myUser?.name?.val ??
                                            myUser?.num.val ??
                                            (myUser == null
                                                ? '...'
                                                : 'btn_your_profile'.l10n),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5,
                                      ),
                                    ),
                                  ],
                                ),
                                ...subtitle,
                              ],
                            ),
                          ),
                          ...trailing,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (folded)
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(5),
                    ),
                    boxShadow: [
                      CustomBoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        blurStyle: BlurStyle.outer,
                      )
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  const _QuadPainter({this.color = Colors.black});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double width = 15;
    final Paint paint = Paint()..color = color;

    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, width);
    path.lineTo(width, width);
    path.lineTo(width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _FoldedClipper extends CustomClipper<Path> {
  const _FoldedClipper({this.radius = 10});

  final double radius;

  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(size.width - radius, 0);

    path.cubicTo(
      size.width - radius,
      0,
      size.width,
      0,
      size.width,
      radius,
    );

    path.lineTo(
      size.width,
      size.height - radius,
    );

    path.cubicTo(
      size.width,
      size.height - radius,
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );

    path.lineTo(radius, size.height);

    path.cubicTo(
      radius,
      size.height,
      0,
      size.height,
      0,
      size.height - radius,
    );

    path.lineTo(0, radius);
    path.lineTo(radius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
