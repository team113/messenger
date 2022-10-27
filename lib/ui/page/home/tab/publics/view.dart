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

import 'dart:math';
import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:badges/badges.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show ChatMemberInfoAction;
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/ui/page/home/page/chat/widget/init_callback.dart';
import 'package:messenger/ui/page/home/tab/chats/search/view.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/hovered_ink.dart';
import 'package:messenger/ui/page/home/widget/animated_typing.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/controller.dart' show ChatCallFinishReasonL10n;
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// View of the `HomeTab.publics` tab.
class PublicsTabView extends StatelessWidget {
  const PublicsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('PublicsTab'),
      init: PublicsTabController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (PublicsTabController c) {
        Widget tile({
          RxUser? user,
          RxChatContact? contact,
          void Function()? onTap,
          bool selected = false,
        }) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ContactTile(
              contact: contact,
              user: user,
              darken: 0,
              onTap: () {
                onTap?.call();
              },
              subtitle: [
                const SizedBox(height: 5),
                Text(
                  'Gapopa ID: ${(contact?.user.value?.user.value.num.val ?? user?.user.value.num.val)?.replaceAllMapped(
                    RegExp(r'.{4}'),
                    (match) => '${match.group(0)} ',
                  )}',
                  style: const TextStyle(color: Color(0xFF888888)),
                ),
              ],
              selected: selected,
            ),
          );
        }

        Widget selectedTile({
          RxUser? user,
          RxChatContact? contact,
          MyUser? myUser,
          void Function()? onTap,
          bool selected = false,
          List<Widget> subtitle = const [],
        }) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
            child: Stack(
              children: [
                ContactTile(
                  contact: contact,
                  user: user,
                  myUser: myUser,
                  darken: 0,
                  selected: selected,
                  margin: const EdgeInsets.symmetric(vertical: 0),
                  subtitle: subtitle,
                  trailing: [
                    if (myUser == null)
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: AnimatedSwitcher(
                          duration: 200.milliseconds,
                          child: selected
                              ? const CircleAvatar(
                                  backgroundColor: Color(0xFF63B4FF),
                                  radius: 12,
                                  child: Icon(
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
                          user?.id ?? contact!.user.value?.id ?? myUser!.id,
                        ),
                        child: const SizedBox(
                          width: 60,
                          height: double.infinity,
                        ),
                      ),
                      Expanded(
                        child: WidgetButton(
                          onPressed: onTap,
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Widget selectedChat({
          required RxChat chat,
          void Function()? onTap,
          bool selected = false,
        }) {
          Style style = Theme.of(context).extension<Style>()!;
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
            child: Stack(
              children: [
                SizedBox(
                  height: 72,
                  child: ContextMenuRegion(
                    key: Key('ContextMenuRegion_${chat.chat.value.id}'),
                    child: Container(
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
                            : style.cardColor,
                        child: InkWell(
                          borderRadius: style.cardRadius,
                          onTap: onTap,
                          hoverColor: selected
                              ? const Color(0x00D7ECFF)
                              : const Color.fromARGB(255, 244, 249, 255),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                            child: Row(
                              children: [
                                AvatarWidget.fromRxChat(chat, radius: 26),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    chat.title.value,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style:
                                        Theme.of(context).textTheme.headline5,
                                  ),
                                ),
                                SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: AnimatedSwitcher(
                                    duration: 200.milliseconds,
                                    child: selected
                                        ? const CircleAvatar(
                                            backgroundColor: Color(0xFF63B4FF),
                                            radius: 12,
                                            child: Icon(
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
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      WidgetButton(
                        onPressed: () => router.user(
                          chat.members.values
                              .firstWhere((e) => e.id != c.me)
                              .id,
                        ),
                        child: const SizedBox(
                          width: 60,
                          height: double.infinity,
                        ),
                      ),
                      Expanded(
                        child: WidgetButton(
                          onPressed: onTap,
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Widget createGroupButton() {
          return Obx(() {
            Widget child = const SizedBox();

            if (c.groupCreating.value) {
              // bool enabled = (c.selectedContacts.isNotEmpty ||
              //         c.selectedUsers.isNotEmpty ||
              //         c.selectedChats.isNotEmpty) &&
              //     c.creatingStatus.value.isEmpty;

              Widget button({
                Key? key,
                Widget? leading,
                required Widget child,
                void Function()? onPressed,
                Color? color,
              }) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 6),
                    // height: 56,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        CustomBoxShadow(
                          blurRadius: 8,
                          color: Color(0x22000000),
                          blurStyle: BlurStyle.outer,
                        ),
                      ],
                    ),
                    child: OutlinedRoundedButton(
                      key: key,
                      maxWidth: null,
                      leading: leading,
                      title: child,
                      onPressed: onPressed,
                      color: color ?? Colors.white,
                    ),
                  ),
                );
              }

              child = Container(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Row(
                  children: [
                    button(
                      child: const Text(
                        'Close',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: c.closeSearch,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    button(
                      child: const Text(
                        'Create group',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: c.createGroup,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              );
            }

            return AnimatedSwitcher(
              duration: 250.milliseconds,
              child: child,
            );
          });
        }

        return Stack(
          children: [
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: CustomAppBar.from(
                context: context,
                title: Obx(() {
                  Widget child;

                  if (c.searching.value) {
                    Style style = Theme.of(context).extension<Style>()!;
                    child = Theme(
                      data: Theme.of(context).copyWith(
                        shadowColor: const Color(0x55000000),
                        iconTheme: const IconThemeData(color: Colors.blue),
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusColor: Colors.white,
                          fillColor: Colors.white,
                          hoverColor: Colors.transparent,
                          filled: true,
                          isDense: true,
                          contentPadding: EdgeInsets.fromLTRB(
                            15,
                            PlatformUtils.isDesktop ? 30 : 23,
                            15,
                            0,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Transform.translate(
                          offset: const Offset(0, 1),
                          child: ReactiveTextField(
                            state: c.search,
                            hint: 'Search',
                            maxLines: 1,
                            filled: false,
                            dense: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            style: style.boldBody.copyWith(fontSize: 17),
                            onChanged: () => c.query.value = c.search.text,
                          ),
                        ),
                      ),
                    );
                  } else if (c.groupCreating.value) {
                    child = WidgetButton(
                      onPressed: () {
                        c.searching.value = true;
                        Future.delayed(
                          Duration.zero,
                          c.search.focus.requestFocus,
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: Text(
                            'Create public'.l10n,
                            key: const Key('1'),
                          ),
                        ),
                      ),
                    );
                  } else {
                    child = Text('Publics'.l10n, key: const Key('2'));
                  }

                  return AnimatedSwitcher(
                    duration: 250.milliseconds,
                    child: child,
                  );
                }),
                leading: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: Obx(() {
                      return AnimatedSwitcher(
                        duration: 250.milliseconds,
                        child: WidgetButton(
                          onPressed: c.searching.value
                              ? null
                              : () {
                                  c.searching.value = true;
                                  Future.delayed(
                                    Duration.zero,
                                    c.search.focus.requestFocus,
                                  );
                                },
                          child: SvgLoader.asset(
                            'assets/icons/search_green.svg',
                            width: 17.77,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 18),
                    child: Obx(() {
                      Widget child;

                      if (c.searching.value || c.groupCreating.value) {
                        child = WidgetButton(
                          key: const Key('CloseSearch'),
                          onPressed: () => c.closeSearch(false),
                          child: SvgLoader.asset(
                            'assets/icons/close_primary.svg',
                            height: 15,
                          ),
                        );
                      } else {
                        Style style = Theme.of(context).extension<Style>()!;

                        child = WidgetButton(
                          onPressed: c.searching.value || c.groupCreating.value
                              ? null
                              : () {
                                  if (c.groupCreating.value) {
                                    if (c.selectedChats.isEmpty &&
                                        c.selectedContacts.isEmpty &&
                                        c.selectedUsers.isEmpty &&
                                        c.query.value?.isEmpty != false) {
                                      c.search.clear();
                                      c.query.value = null;
                                      c.searchResults.value = null;
                                      c.searchStatus.value = RxStatus.empty();
                                      c.searching.value = false;
                                      c.groupCreating.value = false;
                                      router.navigation.value = null;
                                      c.selectedChats.clear();
                                      c.selectedUsers.clear();
                                      c.selectedContacts.clear();
                                      c.populate();
                                    }
                                  } else if (c.groupCreating.isFalse) {
                                    c.groupCreating.value = true;
                                    router.navigation.value = const SizedBox();
                                    // router.navigation.value =
                                    // createGroupButton();
                                    // Future.delayed(
                                    //   Duration.zero,
                                    //   c.search.focus.requestFocus,
                                    // );
                                    c.populate();
                                  }
                                },
                          child: SizedBox(
                            child: SvgLoader.asset(
                              'assets/icons/add_green.svg',
                              width: 17,
                              height: 17,
                            ),
                            // width: 21.77,
                            // child: Icon(
                            //   Icons.add_rounded,
                            //   color: style.green,
                            //   size: 26,
                            // ),
                            // child: SvgLoader.asset(
                            //   'assets/icons/group.svg',
                            //   width: 21.77,
                            //   height: 18.44,
                            // ),
                          ),
                        );
                      }

                      return SizedBox(
                        width: 21.77,
                        child: AnimatedSwitcher(
                          duration: 250.milliseconds,
                          child: child,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              body: Obx(() {
                if (c.chatsReady.value) {
                  Widget? center;

                  if (c.query.isNotEmpty != true &&
                      (c.chats.isEmpty &&
                          c.users.isEmpty &&
                          c.contacts.isEmpty)) {
                    center = Center(child: Text('label_no_chats'.l10n));
                  } else if (c.query.isNotEmpty == true &&
                      c.chats.isEmpty &&
                      c.contacts.isEmpty &&
                      c.users.isEmpty) {
                    if (c.searchStatus.value.isSuccess) {
                      center = Center(child: Text('No user found'.l10n));
                    } else {
                      center = const Center(child: CircularProgressIndicator());
                    }
                  } else {
                    if ((!c.searching.value ||
                            c.query.value?.isEmpty != false) &&
                        !c.groupCreating.value) {
                      center = AnimationLimiter(
                        child: ListView.builder(
                          controller: ScrollController(),
                          itemCount: c.chats.length,
                          itemBuilder: (BuildContext context, int i) {
                            RxChat e = c.sortedChats[i];
                            return AnimationConfiguration.staggeredList(
                              position: i,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: i == 0 ? 5 : 0,
                                      left: 10,
                                      right: 10,
                                      bottom: i == c.chats.length - 1 ? 5 : 0,
                                    ),
                                    child: buildChatTile(context, c, e),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  }

                  ThemeData theme = Theme.of(context);
                  final TextStyle? thin =
                      theme.textTheme.bodyText1?.copyWith(color: Colors.black);
                  Style style = Theme.of(context).extension<Style>()!;

                  Widget chip(Widget child) {
                    return DefaultTextStyle(
                      style: style.systemMessageTextStyle.copyWith(
                        fontSize: 11,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                        // margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          // border: style.systemMessageBorder,
                          color: Colors.white,
                        ),
                        child: child,
                      ),
                    );
                  }

                  return Column(
                    children: [
                      AnimatedSizeAndFade.showHide(
                        fadeDuration: 300.milliseconds,
                        sizeDuration: 300.milliseconds,
                        show: false,
                        // show: c.groupCreating.value,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            shadowColor: const Color(0x55000000),
                            iconTheme: const IconThemeData(color: Colors.blue),
                            inputDecorationTheme: InputDecorationTheme(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              focusColor: Colors.white,
                              fillColor: Colors.white,
                              hoverColor: Colors.transparent,
                              filled: true,
                              isDense: true,
                              contentPadding: EdgeInsets.fromLTRB(
                                15,
                                PlatformUtils.isDesktop ? 30 : 23,
                                15,
                                0,
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(10, 12, 10, 2),
                            child: ReactiveTextField(
                              state: c.search,
                              hint: 'Search',
                              maxLines: 1,
                              filled: true,
                              // dense: true,
                              // padding: const EdgeInsets.symmetric(vertical: 8),
                              style: style.boldBody.copyWith(fontSize: 17),
                              onChanged: () => c.query.value = c.search.text,
                            ),
                          ),
                        ),
                      ),
                      // AnimatedSizeAndFade.showHide(
                      //   fadeDuration: 300.milliseconds,
                      //   sizeDuration: 300.milliseconds,
                      //   show:
                      //       (c.searching.value && c.query.isNotEmpty == true ||
                      //           c.groupCreating.value),
                      //   child: Container(
                      // margin: const EdgeInsets.fromLTRB(2, 12, 2, 2),
                      // height: 30,
                      //     child: Row(
                      //       mainAxisAlignment: c.groupCreating.value
                      //           ? MainAxisAlignment.start
                      //           : MainAxisAlignment.spaceEvenly,
                      //       children: [
                      //         if (c.groupCreating.value)
                      //           const SizedBox(width: 10),
                      //         WidgetButton(
                      //           onPressed: () => c.jumpTo(0),
                      //           child: Obx(() {
                      //             return chip(
                      //               Text(
                      //                 'Chats',
                      //                 style:
                      //                     style.systemMessageTextStyle.copyWith(
                      //                   fontSize: 15,
                      //                   color: c.selected.value == 0
                      //                       ? const Color(0xFF63B4FF)
                      //                       : Colors.black,
                      //                 ),
                      //               ),
                      //             );
                      //           }),
                      //         ),
                      //         const SizedBox(width: 8),
                      //         WidgetButton(
                      //           onPressed: () => c.jumpTo(1),
                      //           child: Obx(() {
                      //             return chip(
                      //               Text(
                      //                 'Contacts',
                      //                 style:
                      //                     style.systemMessageTextStyle.copyWith(
                      //                   fontSize: 15,
                      //                   color: c.selected.value == 1
                      //                       ? const Color(0xFF63B4FF)
                      //                       : Colors.black,
                      //                 ),
                      //               ),
                      //             );
                      //           }),
                      //         ),
                      //         const SizedBox(width: 8),
                      //         WidgetButton(
                      //           onPressed: () => c.jumpTo(2),
                      //           child: Obx(() {
                      //             return chip(Text(
                      //               'Users',
                      //               style:
                      //                   style.systemMessageTextStyle.copyWith(
                      //                 fontSize: 15,
                      //                 color: c.selected.value == 2
                      //                     ? const Color(0xFF63B4FF)
                      //                     : Colors.black,
                      //               ),
                      //             ));
                      //           }),
                      //         ),
                      //         if (!c.groupCreating.value) ...[
                      //           const SizedBox(width: 8),
                      //           WidgetButton(
                      //             onPressed: () => c.jumpTo(2),
                      //             child: Obx(() {
                      //               return chip(Text(
                      //                 'Messages',
                      //                 style:
                      //                     style.systemMessageTextStyle.copyWith(
                      //                   fontSize: 15,
                      //                   color: c.selected.value == 3
                      //                       ? const Color(0xFF63B4FF)
                      //                       : Colors.black,
                      //                 ),
                      //               ));
                      //             }),
                      //           ),
                      //         ] else ...[
                      //           const Spacer(),
                      //           Obx(() {
                      //             return Row(
                      //               mainAxisSize: MainAxisSize.min,
                      //               children: [
                      //                 // Text(
                      //                 //   'Selected: ',
                      //                 //   style: thin?.copyWith(fontSize: 15),
                      //                 // ),
                      //                 chip(Container(
                      //                   constraints:
                      //                       const BoxConstraints(minWidth: 10),
                      //                   child: Center(
                      //                     child: Text(
                      //                       '${c.selectedChats.length + c.selectedUsers.length + c.selectedContacts.length}',
                      //                       style: thin?.copyWith(fontSize: 15),
                      //                     ),
                      //                   ),
                      //                 )),
                      //               ],
                      //             );
                      //           }),
                      //           const SizedBox(width: 10),
                      //         ],
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      Expanded(
                        child: center ??
                            ContextMenuInterceptor(
                              child: FlutterListView(
                                controller: c.controller,
                                delegate: FlutterListViewDelegate(
                                  (context, i) {
                                    ListElement element = c.elements[i];
                                    Widget child = const SizedBox();

                                    if (element is ChatElement) {
                                      if (c.groupCreating.value) {
                                        child = Obx(() {
                                          return selectedChat(
                                            chat: element.chat,
                                            selected: c.selectedChats
                                                .contains(element.chat),
                                            onTap: () =>
                                                c.selectChat(element.chat),
                                          );
                                        });
                                      } else {
                                        child = Padding(
                                          padding: const EdgeInsets.only(
                                            left: 10,
                                            right: 10,
                                          ),
                                          child: buildChatTile(
                                            context,
                                            c,
                                            element.chat,
                                          ),
                                        );
                                      }
                                    } else if (element is ContactElement) {
                                      if (c.groupCreating.value) {
                                        child = Obx(() {
                                          return selectedTile(
                                            contact: element.contact,
                                            selected: c.selectedContacts
                                                .contains(element.contact),
                                            onTap: () => c
                                                .selectContact(element.contact),
                                          );
                                        });
                                      } else {
                                        child = tile(
                                          contact: element.contact,
                                          onTap: () {
                                            c.openChat(
                                              contact: element.contact,
                                            );
                                          },
                                        );
                                      }
                                    } else if (element is UserElement) {
                                      if (c.groupCreating.value) {
                                        child = Obx(() {
                                          return selectedTile(
                                            user: element.user,
                                            selected: c.selectedUsers
                                                .contains(element.user),
                                            onTap: () =>
                                                c.selectUser(element.user),
                                          );
                                        });
                                      } else {
                                        child = tile(
                                          user: element.user,
                                          onTap: () {
                                            c.openChat(user: element.user);
                                          },
                                        );
                                      }
                                    } else if (element is MyUserElement) {
                                      child = Obx(() {
                                        return selectedTile(
                                          myUser: c.myUser.value,
                                          selected: true,
                                          subtitle: [
                                            const SizedBox(height: 5),
                                            const Text(
                                              'Required',
                                              style: TextStyle(
                                                  color: Color(0xFF888888)),
                                            ),
                                          ],
                                        );
                                      });
                                    } else if (element is DividerElement) {
                                      child = Center(
                                        child: Container(
                                          margin: const EdgeInsets.fromLTRB(
                                            10,
                                            2,
                                            10,
                                            2,
                                          ),
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            10,
                                            12,
                                            6,
                                          ),
                                          width: double.infinity,
                                          // decoration: BoxDecoration(
                                          //   borderRadius:
                                          //       BorderRadius.circular(15),
                                          //   border: style.systemMessageBorder,
                                          //   color: style.systemMessageColor,
                                          // ),
                                          child: Center(
                                            child: Text(
                                              element.category.name
                                                  .capitalizeFirst!,
                                              style: style
                                                  .systemMessageTextStyle
                                                  .copyWith(
                                                color: Colors.black,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );

                                      // return Container(
                                      //   margin: const EdgeInsets.fromLTRB(
                                      //     0,
                                      //     20,
                                      //     0,
                                      //     4,
                                      //   ),
                                      //   child: Row(
                                      //     children: [
                                      //       const SizedBox(width: 8),
                                      //       Expanded(
                                      //         child: Container(
                                      //           width: double.infinity,
                                      //           padding:
                                      //               const EdgeInsets.fromLTRB(
                                      //             12,
                                      //             8,
                                      //             12,
                                      //             8,
                                      //           ),
                                      //           child: Row(
                                      //             children: [
                                      //               Expanded(
                                      //                 child: Container(
                                      //                   height: 0.5,
                                      //                   color: const Color(
                                      //                     0xFF000000,
                                      //                   ),
                                      //                 ),
                                      //               ),
                                      //               const SizedBox(width: 10),
                                      //               Text(
                                      //                 element.category.name
                                      //                     .capitalizeFirst!,
                                      //                 style: const TextStyle(
                                      //                   fontSize: 13,
                                      //                   color:
                                      //                       Color(0xFF000000),
                                      //                 ),
                                      //               ),
                                      //               const SizedBox(width: 10),
                                      //               Expanded(
                                      //                 child: Container(
                                      //                   height: 0.5,
                                      //                   color: const Color(
                                      //                     0xFF000000,
                                      //                   ),
                                      //                 ),
                                      //               ),
                                      //             ],
                                      //           ),
                                      //         ),
                                      //       ),
                                      //       const SizedBox(width: 8),
                                      //     ],
                                      //   ),
                                      // );
                                    }

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: i == 0 ? 3 : 0,
                                        bottom:
                                            i == c.elements.length - 1 ? 4 : 0,
                                      ),
                                      child: child,
                                    );
                                  },
                                  childCount: c.elements.length,
                                ),
                              ),
                            ),
                      ),
                    ],
                  );

                  return ContextMenuInterceptor(
                    child: AnimationLimiter(
                      child: ListView.builder(
                        controller: ScrollController(),
                        itemCount:
                            c.chats.length + c.contacts.length + c.users.length,
                        itemBuilder: (BuildContext context, int i) {
                          return Container();
                        },
                      ),
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              }),
              bottomNavigationBar: Obx(() {
                final Widget child;

                if (c.groupCreating.value) {
                  child = createGroupButton();
                } else {
                  child = const SizedBox();
                }

                return AnimatedSwitcher(
                  duration: 250.milliseconds,
                  child: child,
                );
              }),
            ),
            Obx(() {
              final Widget child;

              if (c.creatingStatus.value.isLoading) {
                child = Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0x33000000),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                child = const SizedBox();
              }

              return AnimatedSwitcher(duration: 200.milliseconds, child: child);
            }),
          ],
        );
      },
    );
  }

  /// Reactive [ListTile] with [RxChat]'s information.
  Widget buildChatTile(
    BuildContext context,
    PublicsTabController c,
    RxChat rxChat,
  ) {
    return Obx(() {
      Chat chat = rxChat.chat.value;

      ChatItem? item;
      if (rxChat.messages.isNotEmpty) {
        item = rxChat.messages.last.value;
      }
      item ??= chat.lastItem;

      const Color subtitleColor = Color(0xFF666666);
      List<Widget>? subtitle;

      Iterable<String> typings = rxChat.typingUsers
          .where((e) => e.id != c.me)
          .map((e) => e.name?.val ?? e.num.val);

      // if (chat.currentCall == null) {
      if (typings.isNotEmpty) {
        if (!rxChat.chat.value.isGroup) {
          subtitle = [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Печатает'.l10n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 3),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: AnimatedTyping(),
                ),
              ],
            ),
          ];
        } else {
          subtitle = [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      typings.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: AnimatedTyping(),
                  ),
                ],
              ),
            )
          ];
        }
      } else if (item != null) {
        if (item is ChatCall) {
          String description = 'label_chat_call_ended'.l10n;
          if (item.finishedAt == null && item.finishReason == null) {
            subtitle = [
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 2, 6, 2),
                child: Icon(Icons.call, size: 16, color: subtitleColor),
              ),
              Flexible(child: Text('label_call_active'.l10n, maxLines: 2)),
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
              //   child: ElevatedButton(
              //     onPressed: () => c.joinCall(chat.id),
              //     child: Text('btn_chat_join_call'.l10n),
              //   ),
              // ),
            ];
          } else {
            description =
                item.finishReason?.localizedString(item.authorId == c.me) ??
                    description;
            subtitle = [
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 2, 6, 2),
                child: Icon(Icons.call, size: 16, color: subtitleColor),
              ),
              Flexible(child: Text(description, maxLines: 2)),
            ];
          }
        } else if (item is ChatMessage) {
          var desc = StringBuffer();

          if (!chat.isGroup && item.authorId == c.me) {
            desc.write('${'label_you'.l10n}: ');
          }

          String? text = item.text?.val.replaceAll(' ', '');
          if (text?.isEmpty == true) {
            text = null;
          } else {
            text = item.text?.val;
          }

          if (text != null) {
            desc.write(text);
            if (item.attachments.isNotEmpty) {
              // desc.write(
              // ' [${item.attachments.length} ${'label_attachments'.l10n}]');
            }
          } else if (item.attachments.isNotEmpty) {
            // desc.write(
            // '[${item.attachments.length} ${'label_attachments'.l10n}]');
          } else {
            desc.write('[Quoted message]');
          }

          final List<Widget> images = [];

          if (item.attachments.whereType<ImageAttachment>().isNotEmpty) {
            Widget image(ImageAttachment e) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image.network(
                    '${Config.files}${e.medium.relativeRef}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return InitCallback(
                        callback: () {
                          if (chat.lastItem != null) {
                            rxChat.updateAttachments(chat.lastItem!);
                          }
                        },
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              );
            }

            if (text == null) {
              images.addAll(
                item.attachments.whereType<ImageAttachment>().map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: image(e),
                  );
                }),
              );
            } else {
              images.add(
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: image(
                      item.attachments.whereType<ImageAttachment>().first),
                ),
              );
            }

            // if (text == null) {
            //   images.addAll(
            //     item.attachments.whereType<ImageAttachment>().map((e) {
            //       return SizedBox(
            //         width: 40,
            //         height: 40,
            //         child: Image.network(
            //           '${Config.files}${e.medium.relativeRef}',
            //           fit: BoxFit.cover,
            //         ),
            //       );
            //     }),
            //   );
            // }
          }

          subtitle = [
            ...images,
            // if (chat.isGroup)
            //   Padding(
            //     padding: const EdgeInsets.only(right: 5),
            //     child: FutureBuilder<RxUser?>(
            //       future: c.getUser(item.authorId),
            //       builder: (_, snapshot) => AvatarWidget.fromRxUser(
            //         snapshot.data,
            //         radius: 10,
            //       ),
            //     ),
            //   ),
            Flexible(child: Text(desc.toString(), maxLines: 2)),
          ];
        } else if (item is ChatForward) {
          subtitle = [
            // if (chat.isGroup)
            //   Padding(
            //     padding: const EdgeInsets.only(right: 5),
            //     child: FutureBuilder<RxUser?>(
            //       future: c.getUser(item.authorId),
            //       builder: (_, snapshot) => snapshot.data != null
            //           ? Obx(
            //               () => AvatarWidget.fromUser(
            //                 snapshot.data!.user.value,
            //                 radius: 10,
            //               ),
            //             )
            //           : AvatarWidget.fromUser(
            //               chat.getUser(item!.authorId),
            //               radius: 10,
            //             ),
            //     ),
            //   ),
            Flexible(child: Text('[${'label_forwarded_message'.l10n}]')),
          ];
        } else if (item is ChatMemberInfo) {
          final Widget content;

          switch (item.action) {
            case ChatMemberInfoAction.created:
              if (chat.isGroup) {
                content = Text('label_group_created'.l10n);
              } else {
                content = Text('label_dialog_created'.l10n);
              }
              break;

            case ChatMemberInfoAction.added:
              content = Text(
                'label_was_added'
                    .l10nfmt({'who': '${item.user.name ?? item.user.num}'}),
              );
              break;

            case ChatMemberInfoAction.removed:
              content = Text(
                'label_was_removed'
                    .l10nfmt({'who': '${item.user.name ?? item.user.num}'}),
              );
              break;

            case ChatMemberInfoAction.artemisUnknown:
              content = Text('${item.action}');
              break;
          }

          subtitle = [Flexible(child: content)];
        } else {
          subtitle = [
            Flexible(child: Text('label_empty_message'.l10n, maxLines: 2)),
          ];
        }
      }

      Widget circleButton({
        Key? key,
        void Function()? onPressed,
        Color? color,
        required Widget child,
      }) {
        return WidgetButton(
          key: key,
          onPressed: onPressed,
          child: Container(
            key: key,
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color ?? const Color(0xFF63B4FF),
              shape: BoxShape.circle,
            ),
            child: Center(child: child),
          ),
        );
      }

      Style style = Theme.of(context).extension<Style>()!;

      bool selected = router.routes
              .lastWhereOrNull((e) => e.startsWith(Routes.public))
              ?.startsWith('${Routes.public}/${chat.id}') ==
          true;

      final List<Widget> additional = [];
      // if (item?.authorId == c.me) {
      //   bool isSent = item?.status.value == SendingStatus.sent;

      //   bool isRead = false;
      //   isRead = chat.lastReads.firstWhereOrNull(
      //               (e) => e.memberId != c.me && !e.at.isBefore(item!.at)) !=
      //           null &&
      //       isSent;

      //   bool isDelivered = isSent && !chat.lastDelivery.isBefore(item!.at);
      //   bool isError = item?.status.value == SendingStatus.error;
      //   bool isSending = item?.status.value == SendingStatus.sending;

      //   if (isSent || isDelivered || isRead || isSending || isError) {
      //     additional.addAll([
      //       const SizedBox(width: 10),
      //       Icon(
      //         (isRead || isDelivered)
      //             ? Icons.done_all
      //             : isSending
      //                 ? Icons.access_alarm
      //                 : isError
      //                     ? Icons.error_outline
      //                     : Icons.done,
      //         color: isRead
      //             ? const Color(0xFF63B4FF)
      //             : isError
      //                 ? Colors.red
      //                 : const Color(0xFF888888),
      //         size: 16,
      //       ),
      //     ]);
      //   }
      // }

      return ContextMenuRegion(
        key: Key('ContextMenuRegion_${chat.id}'),
        preventContextMenu: false,
        actions: [
          ContextMenuButton(
            key: const Key('ButtonHideChat'),
            label: 'btn_hide_chat'.l10n,
            onPressed: () => c.hideChat(chat.id),
          ),
          if (chat.isGroup)
            ContextMenuButton(
              key: const Key('ButtonLeaveChat'),
              label: 'btn_leave_chat'.l10n,
              onPressed: () => c.leaveChat(chat.id),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
          child: ConditionalBackdropFilter(
            condition: false,
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            borderRadius:
                context.isMobile ? BorderRadius.zero : style.cardRadius,
            child: InkWellWithHover(
              selectedColor: const Color(0xFFD7ECFF).withOpacity(0.8),
              unselectedColor: style.cardColor,
              isSelected: selected,
              hoveredBorder: selected
                  ? Border.all(
                      color: const Color(0xFFB9D9FA),
                      width: 0.5,
                    )
                  : Border.all(
                      color: const Color(0xFFDAEDFF),
                      width: 0.5,
                    ),
              unhoveredBorder:
                  selected ? style.primaryBorder : style.cardBorder,
              borderRadius: style.cardRadius,
              onTap: () => router.public(chat.id),
              unselectedHoverColor: const Color.fromARGB(255, 244, 249, 255),
              // unselectedHoverColor: const Color.fromRGBO(230, 241, 254, 1),
              selectedHoverColor: const Color(0xFFD7ECFF).withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  children: [
                    AvatarWidget.fromRxChat(rxChat, radius: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rxChat.title.value,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (chat.ongoingCall == null)
                                Text(
                                  chat.ongoingCall == null ? '10:10' : '32:02',
                                  // : '${chat.currentCall?.conversationStartedAt?.val.minute}:${chat.currentCall?.conversationStartedAt?.val.second}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      ?.copyWith(
                                        color: chat.ongoingCall == null
                                            ? null
                                            : const Color(0xFF63B4FF),
                                      ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const SizedBox(height: 3),
                              Expanded(
                                child: DefaultTextStyle(
                                  style: Theme.of(context).textTheme.subtitle2!,
                                  overflow: TextOverflow.ellipsis,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: ClipRect(
                                      child: Row(children: subtitle ?? []),
                                    ),
                                  ),
                                ),
                              ),
                              ...additional,
                              if (chat.unreadCount != 0) ...[
                                const SizedBox(width: 10),
                                Badge(
                                  toAnimate: false,
                                  elevation: 0,
                                  badgeContent: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Text(
                                      '${chat.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (chat.ongoingCall != null) ...[
                      const SizedBox(width: 10),
                      AnimatedSwitcher(
                        key: const Key('ActiveCallButton'),
                        duration: 300.milliseconds,
                        child: c.isInCall(chat.id)
                            ? circleButton(
                                key: const Key('Drop'),
                                onPressed: () => c.dropCall(chat.id),
                                color: Colors.red,
                                child: SvgLoader.asset(
                                  'assets/icons/call_end.svg',
                                  width: 38,
                                  height: 38,
                                ),
                              )
                            : circleButton(
                                key: const Key('Join'),
                                onPressed: () => c.joinCall(chat.id),
                                child: SvgLoader.asset(
                                  'assets/icons/audio_call_start.svg',
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
