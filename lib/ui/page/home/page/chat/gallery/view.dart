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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/sliver_app_bar.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/chat/widget/data_attachment.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the [Routes.chat] [Routes.files] or [Routes.media] page.
class GalleryView extends StatelessWidget {
  const GalleryView({
    super.key,
    required this.chatId,
    required this.viewMode,
    required this.chatService,
  });

  /// View of the [Routes.chat][gallery] page in media mode.
  const GalleryView.media({
    super.key,
    required this.chatId,
    required this.chatService,
  }) : viewMode = GalleryViewMode.media;

  /// View of the [Routes.chat][gallery] page in files mode.
  const GalleryView.files({
    super.key,
    required this.chatId,
    required this.chatService,
  }) : viewMode = GalleryViewMode.files;

  /// ID of this [сhat].
  final ChatId chatId;

  /// Current [Gallery] view.
  final GalleryViewMode viewMode;

  /// [ChatService] maintaining the [chat].
  final ChatService chatService;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).style;
    return GetBuilder(
      init: GalleryController(
        chatService: chatService,
        chatId: chatId,
        viewMode: viewMode,
      ),
      tag: chatId.val,
      global: !Get.isRegistered<GalleryController>(tag: chatId.val),
      builder: (c) {
        return Obx(() {
          if (!c.chatStatus.value.isSuccess) {
            return Scaffold(
              appBar: CustomAppBar(
                padding: EdgeInsets.only(left: 4, right: 4),
                leading: [StyledBackButton()],
              ),
              body: Center(
                child: c.chatStatus.value.isEmpty
                    ? Text('label_no_chat_found'.l10n)
                    : const CustomProgressIndicator(),
              ),
            );
          }
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: NestedScrollView(
              headerSliverBuilder: (context, value) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: SliverSafeArea(
                      top: false,
                      left: false,
                      right: false,
                      bottom: false,
                      sliver: _appBar(context, c),
                    ),
                  ),
                ];
              },
              body: Container(
                color: PlatformUtils.isMobile ? style.colors.onPrimary : null,
                child: ContextMenuInterceptor(
                  child: Obx(
                    () => c.itemsStatus.value.isLoading
                        ? Center(child: const CustomProgressIndicator())
                        : c.items.isEmpty
                        ? _emptyBody(context, c)
                        : _body(context, c),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Returns a [SliverAppBar] to build on the page.
  Widget _appBar(BuildContext context, GalleryController c) {
    final Style style = Theme.of(context).style;

    final Widget title = Row(
      children: [
        StyledBackButton(),
        AvatarWidget.fromRxChat(c.chat.value, radius: AvatarRadius.big),
        SizedBox(width: 10),
        Flexible(
          child: DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Obx(() {
                        return Text(
                          c.chat.value!.title(),
                          style: style.fonts.big.regular.onBackground,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      }),
                    ),
                  ],
                ),
                Text(
                  c.viewMode == GalleryViewMode.files
                      ? 'label_files'.l10n
                      : 'label_media'.l10n,
                  style: style.fonts.small.regular.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return CustomSliverAppBar(
      title: title,
      extended: 60,
      actions: _actions(context, c),
      hasFlexible: false,
      hideSystemLeading: true,
    );
  }

  /// Opens a confirmation popup reporting this [Chat].
  Future<void> _reportChat(BuildContext context, GalleryController c) async {
    final Style style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_report'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_reported1'.l10n),
        TextSpan(
          text: c.chat.value?.title(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_chat_will_be_reported2'.l10n),
      ],
      additional: [
        const SizedBox(height: 25),
        ReactiveTextField(
          key: const Key('ReportField'),
          state: c.reporting,
          label: 'label_reason'.l10n,
          hint: 'label_reason_hint'.l10n,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ],
      button: (context) {
        return Obx(() {
          final bool enabled = !c.reporting.isEmpty.value;

          return PrimaryButton(
            key: enabled ? const Key('SendReportButton') : null,
            title: 'btn_proceed'.l10n,
            onPressed: enabled ? () => Navigator.of(context).pop(true) : null,
            leading: SvgIcon(
              enabled ? SvgIcons.reportWhite : SvgIcons.reportGrey,
            ),
          );
        });
      },
    );

    if (result == true) {
      await c.reportChat();
    }
  }

  /// Builds [body] for this page.
  Widget _body(BuildContext context, GalleryController c) {
    return c.viewMode == GalleryViewMode.files
        ? _filesBody(context, c)
        : _mediaBody(context, c);
  }

  /// Builds empty [body] for this page.
  Widget _emptyBody(BuildContext context, GalleryController c) {
    final Style style = Theme.of(context).style;
    return Column(
      mainAxisAlignment: PlatformUtils.isMobile
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (PlatformUtils.isMobile) SizedBox(height: 30),
        SvgIcon(
          c.viewMode == GalleryViewMode.files
              ? SvgIcons.galleryNoFiles
              : SvgIcons.galleryNoMedia,
        ),
        SizedBox(height: 20),
        Text(
          (c.viewMode == GalleryViewMode.files
                  ? 'label_no_files'
                  : 'label_no_media')
              .l10n,
          textAlign: TextAlign.center,
          style: style.fonts.medium.regular.secondary,
        ),
      ],
    );
  }

  /// Returns avaliable [actions] for [menu].
  List<Widget> _actions(BuildContext context, GalleryController c) => [
    ContextMenuRegion(
      actions: [
        ContextMenuButton(
          label: 'btn_go_to_chat'.l10n,
          trailing: const SvgIcon(SvgIcons.chat19),
          inverted: const SvgIcon(SvgIcons.chat19White),
          onPressed: c.goToChat,
        ),
        ContextMenuButton(
          label: 'btn_report'.l10n,
          trailing: const SvgIcon(SvgIcons.report),
          inverted: const SvgIcon(SvgIcons.reportWhite),
          onPressed: () => _reportChat(context, c),
        ),
      ],
      enablePrimaryTap: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        child: SvgIcon(SvgIcons.more),
      ),
    ),
  ];

  /// Returns [body] for file [attachment]s view.
  Widget _filesBody(BuildContext context, GalleryController c) {
    final Style style = Theme.of(context).style;

    final Widget itemsList = Obx(
      () => ListView.separated(
        controller: c.scrollController,
        padding: const EdgeInsets.all(10),
        itemBuilder: (BuildContext context, int index) => DataAttachment(
          c.items[index],
          onPressed: () => c.downloadFile(c.items[index] as FileAttachment),
        ),
        separatorBuilder: (BuildContext context, int index) => Divider(),
        itemCount: c.items.length,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => !PlatformUtils.isMobile
          ? Block(
              expanded: false,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.all(12),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'label_files'.l10n,
                  textAlign: TextAlign.center,
                  style: style.fonts.large.regular.onBackground,
                ),
                SizedBox(height: 20),
                Expanded(child: itemsList),
              ],
            )
          : SizedBox.expand(child: itemsList),
    );
  }

  /// Returns [body] for media [attachment]s view.
  Widget _mediaBody(BuildContext context, GalleryController c) => LayoutBuilder(
    builder: (context, constraints) => GridView.count(
      controller: c.scrollController,
      padding: EdgeInsets.zero,
      crossAxisCount: switch (constraints.maxWidth) {
        <= 300 => 2,
        <= 450 => 3,
        <= 800 => constraints.maxWidth ~/ 150,
        (_) => constraints.maxWidth ~/ 200,
      },
      mainAxisSpacing: 1,
      crossAxisSpacing: 1,
      children: c.items
          .map<Widget>(
            (e) => WidgetButton(
              onPressed: () => c.showMediaPlayer(context, e),
              child: MediaAttachment(
                key: c.thumbnails[e.id.val] ??= GlobalKey(),
                attachment: e,
                fit: BoxFit.cover,
              ),
            ),
          )
          .toList(),
    ),
  );
}
