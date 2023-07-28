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

import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/page/style/page/typography/widget/font_schema.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/family.dart';
import 'widget/font.dart';
import 'widget/style.dart';

/// View of the [StyleTab.typography] page.
class TypographyView extends StatelessWidget {
  const TypographyView({
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this view should be compact, meaning minimal [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    final Iterable<(TextStyle, String)> styles = [
      (fonts.displayLarge!, 'displayLarge'),
      (fonts.displayMedium!, 'displayMedium'),
      (fonts.displaySmall!, 'displaySmall'),
      (fonts.headlineLarge!, 'headlineLarge'),
      (fonts.headlineMedium!, 'headlineMedium'),
      (fonts.headlineSmall!, 'headlineSmall'),
      (fonts.titleLarge!, 'titleLarge'),
      (fonts.titleMedium!, 'titleMedium'),
      (fonts.titleSmall!, 'titleSmall'),
      (fonts.labelLarge!, 'labelLarge'),
      (fonts.labelMedium!, 'labelMedium'),
      (fonts.labelSmall!, 'labelSmall'),
      (fonts.bodyLarge!, 'bodyLarge'),
      (fonts.bodyMedium!, 'bodyMedium'),
      (fonts.bodySmall!, 'bodySmall'),
    ];

    final Iterable<(TextStyle, String, String)> schema = [
      // Display large
      (fonts.displayLarge!, 'displayLarge', '0 uses by this color'),
      (
        fonts.displayLarge!.copyWith(color: style.colors.onPrimary),
        'displayLarge',
        '"CallTitle" title'
      ),

      // Display medium
      (fonts.displayMedium!, 'displayMedium', '0 uses by this color'),
      (
        fonts.displayMedium!.copyWith(color: style.colors.secondary),
        'displayMedium',
        '"Messenger" on auth page'
      ),

      // Display small
      (fonts.displaySmall!, 'displaySmall', '0 uses by this color'),
      (
        fonts.displaySmall!.copyWith(color: style.colors.secondary),
        'displaySmall',
        '"UnreadCounter" when dimmed and inverted'
      ),
      (
        fonts.displaySmall!.copyWith(color: style.colors.onPrimary),
        'displaySmall',
        '"UnreadCounter" by default or when dimmed and not inverted'
      ),

      // Headline large
      (
        fonts.headlineLarge!,
        'headlineLarge',
        '"MenuButton", "ChatTile", "ContactTile" title'
      ),
      (
        fonts.headlineLarge!.copyWith(color: style.colors.onPrimary),
        'headlineLarge',
        'Mobile title of chat during call \nInverted "MenuButton" title \n'
            'Selected "ChatTile" and "ContactTile" title'
      ),

      // Headline medium
      (
        fonts.headlineMedium!,
        'headlineMedium',
        'btn_set_password \n"NumCopyable" \n"_repliedMessage" error \nlabel_visible_to \n'
            'MenuTab user name \nlabel_presence \n"CustomAppBar" title \n"Block" title'
      ),

      (
        fonts.headlineMedium!.copyWith(color: style.colors.onPrimary),
        'headlineMedium',
        '"CallTitle" state \n"ConfirmDialogVariant"'
      ),

      // Headline small
      (fonts.headlineSmall!, 'headlineSmall', '0 uses of this color'),
      (
        fonts.headlineSmall!.copyWith(color: style.colors.secondary),
        'headlineSmall',
        '"time" in MessageFieldView \nlabel_forwarded_messages \nlabel_kb'
      ),
      (
        fonts.headlineSmall!.copyWith(color: style.colors.onPrimary),
        'headlineSmall',
        '"RoundFloatingButton" and "RtcVideoView" label \nCurrent video position and duration'
      ),
      (
        fonts.headlineSmall!.copyWith(
          color: style.colors.onPrimary,
          shadows: [
            Shadow(blurRadius: 6, color: style.colors.onBackground),
            Shadow(blurRadius: 6, color: style.colors.onBackground),
          ],
        ),
        'headlineSmall',
        '"RoundFloatingButton" and "TooltipButton" hint'
      ),

      // Title large
      (
        fonts.titleLarge!,
        'titleLarge',
        'ShadowedRoundedButton label \n"ConfirmLogoutView" user \n"PrimaryButton"'
      ),
      (
        fonts.titleLarge!.copyWith(color: style.colors.secondary),
        'titleLarge',
        'alert_are_you_sure_want_to_log_out'
      ),
      (
        fonts.titleLarge!.copyWith(color: style.colors.onPrimary),
        'titleLarge',
        '"OutlinedRoundedButton" and "ShadowedRoundedButton" label with `primary` or inverted color'
      ),

      // Title medium
      (
        fonts.titleMedium!,
        'titleMedium',
        'SearchTextField \nAttachmentSelector \nStatusField \nPasswordField \nRepeatPasswordField'
      ),
      (
        fonts.titleMedium!.copyWith(color: style.colors.primary),
        'titleMedium',
        '"CallSettingsView" fields \nMyUser "FieldButton"s \nActionButton'
      ),
      (
        fonts.titleMedium!.copyWith(color: style.colors.secondary),
        'titleMedium',
        '"_repliedMessage" label \nMyUser unconfirmed emails and phones'
      ),
      (
        fonts.titleMedium!.copyWith(color: style.colors.onPrimary),
        'titleMedium',
        'AnimatedDots'
      ),

      // Title small
      (fonts.titleSmall!, 'titleSmall', '0 uses of this color'),
      (
        fonts.titleSmall!.copyWith(color: style.colors.onPrimary),
        'titleSmall',
        '"CallCoverWidget" title \nLabel or title of "AvatarWidget"'
      ),

      // Label large
      (
        fonts.labelLarge!,
        'labelLarge',
        '"ChatInfoView" and "UserView" Popups \n"SearchCategory" names'
      ),
      (
        fonts.labelLarge!.copyWith(color: style.colors.secondary),
        'labelLarge',
        '"by Gapopa" on auth page \n"ChatItem" time \n"RecentChatTile" updated at \n'
            'label_password_set \nlabel_password_not_set \nConfirmDialog description \n'
            'LoginViewStage labels'
      ),
      (
        fonts.labelLarge!.copyWith(color: style.colors.onPrimary),
        'labelLarge',
        'Mobile title of chat contains information about current call \n'
            'Add call participants label \nInverted "RecentChatTile" updated at \n'
            '"RectangleButton" label'
      ),

      // Label medium
      (
        fonts.labelMedium!,
        'labelMedium',
        'NoMessages \nlabel_nothing_found \nMenuButton subtitle'
      ),
      (
        fonts.labelMedium!.copyWith(color: style.colors.primary),
        'labelMedium',
        'label_typing'
      ),
      (
        fonts.labelMedium!.copyWith(color: style.colors.secondary),
        'labelMedium',
        '"CupertinoButton" label, \nlabel_synchronization \nSearchUserTile label \n'
            '"ContactsTabView" subtitle \nMenuTabView status'
      ),
      (
        fonts.labelMedium!.copyWith(color: style.colors.onPrimary),
        'labelMedium',
        'Desktop Call title \nDraggable label \nInverted label_typing \nInverted SearchUserTile label \n'
            'Inverted "ContactsTabView" subtitle \nInverted "MenuButton" subtitle'
      ),

      // Label small
      (fonts.labelSmall!, 'labelSmall', '0 uses of this color'),
      (
        fonts.labelSmall!.copyWith(color: style.colors.primary),
        'labelSmall',
        'label_details \n"MyProfileView" btn_upload and btn_delete \nlabel_nobody'
      ),
      (
        fonts.labelSmall!.copyWith(color: style.colors.secondary),
        'labelSmall',
        'Hint of "CallButton" \n"MessageTimestamp" \n"SwipeableStatus" \nlabel_transition_count \n'
            'label_login_visible \n '
      ),
      (
        fonts.labelSmall!.copyWith(color: style.colors.secondaryHighlightDark),
        'labelSmall',
        'Inverted "MessageTimestamp"'
      ),
      (
        fonts.labelSmall!.copyWith(color: style.colors.onPrimary),
        'labelSmall',
        'Hint of "CallButton" \n'
      ),

      // Body large
      (
        fonts.bodyLarge!,
        'bodyLarge',
        'label_send_message_hint \n Text of the "ChatMessage" \n'
            'label_forwarded_message \nerr_unknown \n'
            '"ChatForwardWidget" and "ChatItem" default style \n'
            '"ChatForwardWidget" and "ChatItem" SelectionText, time, quote, _note, title \n'
            '"DataAttachment" labels \nSearchField, \nProfileTab.background messages \n'
            'btn_unblock'
      ),
      (
        fonts.bodyLarge!.copyWith(color: style.colors.primary),
        'bodyLarge',
        'label_edit \n"MessageFieldView" preview'
      ),

      // Body medium
      (
        fonts.bodyMedium!,
        'bodyMedium',
        'IntroductionView "ReactiveTextField"s \nlabel_introduction_description \n'
      ),
      (
        fonts.bodyMedium!.copyWith(color: style.colors.primary),
        'bodyMedium',
        '"bigButton" title'
      ),
      (
        fonts.bodyMedium!.copyWith(color: style.colors.secondary),
        'bodyMedium',
        'label_password_set \nAddEmailView, AddPhoneView labels \nlabel_direct_chat_link_description \n'
            'ChangePasswordView labels and buttons \nRecentChatTile subtitle'
      ),

      (
        fonts.bodyMedium!.copyWith(color: style.colors.onPrimary),
        'bodyMedium',
        'label_reconnecting_ellipsis \nbtn_share \n"CallNotificationWidget" title \n'
            '"ParticipantOverlayWidget" name \nRewindIndicator label \n Video player error \n'
            'btn_set_password \nSharableTextField \nAddEmailView, AddPhoneView labels \nbtn_proceed \n'
            'Inverted RecentChatTile subtitle \nRectangularCallButton duration \nAvatarWidget title \n'
            'ConfirmDialog label'
      ),

      // Body small
      (
        fonts.bodySmall!,
        'bodySmall',
        'MessageFiledView content \nMessageInfo ID \nlabel_delete_contact'
      ),
      (
        fonts.bodySmall!.copyWith(color: style.colors.primary),
        'bodySmall',
        'btn_upload \nbtn_delete \nlabel_phone_visible \nlabel_nobody \nbtn_unblock_short \n'
            'btn_forgot_password'
      ),
      (
        fonts.bodySmall!.copyWith(color: style.colors.secondary),
        'bodySmall',
        'label_kb \nChatSubtitle labels \nlabel_read_at \nUserView subtitle'
      ),
      (
        fonts.bodySmall!.copyWith(color: style.colors.onPrimary),
        'bodySmall',
        '"CallButton" description \nlabel_required \nCustomNavigationBarItem'
      ),
      (
        fonts.bodySmall!.copyWith(color: style.colors.secondaryOpacity87),
        'bodySmall',
        '"HintWidget" labels'
      ),
    ];

    final List<(FontWeight, String)> families = [
      (FontWeight.w300, 'SFUI-Light'),
      (FontWeight.w400, 'SFUI-Regular'),
      (FontWeight.w700, 'SFUI-Bold'),
    ];

    return ScrollableColumn(
      children: [
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Header('Typography'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SubHeader('Fonts'),
        ),
        BuilderWrap(
          styles,
          inverted: inverted,
          dense: dense,
          (e) => FontWidget(e, inverted: inverted, dense: dense),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SubHeader('Font schema'),
        ),
        FontSchema(schema, inverted: inverted, dense: dense),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SubHeader('Families'),
        ),
        BuilderWrap(
          families,
          inverted: inverted,
          dense: dense,
          (e) => FontFamily(e, inverted: inverted, dense: dense),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SubHeader('Styles'),
        ),
        BuilderWrap(
          styles,
          inverted: inverted,
          dense: dense,
          (e) => FontStyle(e, inverted: inverted),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
