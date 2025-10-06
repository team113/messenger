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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller.dart';
import '/domain/model/attachment.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// View for displaying [Post]s in a [GridView].
class GalleryView extends StatelessWidget {
  const GalleryView(this.controller, {super.key});

  /// [PlayerController] controlling the [Post]s.
  final PlayerController controller;

  /// Displays a [GalleryView] in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required PlayerController controller,
  }) async {
    final style = Theme.of(context).style;

    final ModalRoute<T> route = MaterialPageRoute<T>(
      builder: (BuildContext context) {
        return Material(
          type: MaterialType.canvas,
          color: style.colors.onBackground,
          child: Scaffold(
            backgroundColor: style.colors.onBackground,
            body: GalleryView(controller),
          ),
        );
      },
    );

    router.obscuring.add(route);

    try {
      return await Navigator.of(context, rootNavigator: true).push<T>(route);
    } finally {
      router.obscuring.remove(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: controller,
      builder: (PlayerController c) {
        final EdgeInsets padding = MediaQuery.of(context).padding;

        return LayoutBuilder(
          builder: (context, constraints) {
            final Widget selectedSpacer = Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: SvgIcon(SvgIcons.sentBlue),
            );

            final Widget selectedInverted = Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: SvgIcon(SvgIcons.sentWhite),
            );

            final int photos = c.source.values
                .expand((e) => e.attachments)
                .whereType<ImageAttachment>()
                .length;

            final int videos = c.source.values
                .expand((e) => e.attachments)
                .whereType<FileAttachment>()
                .length;

            return Container(
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              padding: EdgeInsets.fromLTRB(
                padding.left,
                padding.top,
                padding.right,
                0,
              ),
              decoration: BoxDecoration(color: style.colors.background),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 6),
                      Expanded(child: _header(context, c)),
                      Obx(() {
                        return ContextMenuRegion(
                          actions: [
                            ContextMenuButton(
                              label: 'label_photos_semicolon_amount'.l10nfmt({
                                'amount': photos,
                              }),
                              onPressed: c.includePhotos.toggle,
                              spacer: c.includePhotos.value
                                  ? selectedSpacer
                                  : null,
                              spacerInverted: c.includePhotos.value
                                  ? selectedInverted
                                  : null,
                            ),
                            ContextMenuButton(
                              label: 'label_videos_semicolon_amount'.l10nfmt({
                                'amount': videos,
                              }),
                              onPressed: c.includeVideos.toggle,
                              spacer: c.includeVideos.value
                                  ? selectedSpacer
                                  : null,
                              spacerInverted: c.includeVideos.value
                                  ? selectedInverted
                                  : null,
                            ),
                          ],
                          enablePrimaryTap: true,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                            child: SvgIcon(SvgIcons.more),
                          ),
                        );
                      }),
                    ],
                  ),
                  Expanded(
                    child: Obx(() {
                      final Iterable<Widget> medias = c.posts
                          .where((e) {
                            final PostItem? item = e.items.firstOrNull;
                            if (item == null) {
                              return false;
                            }

                            if (item.attachment is ImageAttachment) {
                              return c.includePhotos.value;
                            } else {
                              return c.includeVideos.value;
                            }
                          })
                          .mapIndexed((i, e) {
                            return Obx(() {
                              final PostItem? item = e.items.firstOrNull;
                              if (item == null) {
                                return const SizedBox();
                              }

                              return WidgetButton(
                                onPressed: () {
                                  c.side.value = false;

                                  c.vertical.animateToPage(
                                    i,
                                    duration: Duration(milliseconds: 250),
                                    curve: Curves.ease,
                                  );

                                  Navigator.of(context).pop();
                                },
                                child: MediaAttachment(
                                  key: c.thumbnails[e.id] ??= GlobalKey(),
                                  attachment: item.attachment,
                                  fit: BoxFit.cover,
                                  width: constraints.maxWidth,
                                  height: constraints.maxWidth,
                                  onError: () async => await c.reload(e),
                                ),
                              );
                            });
                          });

                      if (medias.isEmpty) {
                        return Center(
                          child: Text(
                            'label_nothing_found'.l10n,
                            style: style.fonts.small.regular.secondary,
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: switch (constraints.maxWidth) {
                            <= 300 => 2,
                            <= 450 => 3,
                            <= 800 => constraints.maxWidth ~/ 150,
                            (_) => constraints.maxWidth ~/ 200,
                          },
                        ),
                        itemCount: medias.length,
                        itemBuilder: (context, i) {
                          return Padding(
                            padding: const EdgeInsets.all(1),
                            child: medias.elementAt(i),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the header of this [GalleryView].
  Widget _header(BuildContext context, PlayerController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Widget avatar;
      final Widget title;

      final RxChat? chat = c.resource.chat.value;
      if (chat != null) {
        avatar = AvatarWidget.fromRxChat(chat, radius: AvatarRadius.medium);
        title = Text(
          chat.title(),
          style: style.fonts.medium.regular.onBackground,
        );
      } else {
        avatar = AvatarWidget(
          title: 'Gl',
          color: 0,
          radius: AvatarRadius.medium,
        );

        title = Text(
          'btn_gallery'.l10n,
          style: style.fonts.medium.regular.onBackground,
        );
      }

      return Row(
        children: [
          WidgetButton(
            onPressed: Navigator.of(context).pop,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(children: [SvgIcon(SvgIcons.back)]),
            ),
          ),
          avatar,
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                SizedBox(height: 2),
                Text(
                  'label_media_semicolon_amount'.l10nfmt({
                    'amount': c.posts.length,
                  }),
                  style: style.fonts.small.regular.secondary,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
