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
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/family.dart';
import 'widget/font.dart';
import 'widget/font_schema.dart';
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
    final style = Theme.of(context).style;

    final Iterable<(TextStyle, String)> styles = [
      (style.fonts.displayLarge, 'displayLarge'),
      (style.fonts.displayMedium, 'displayMedium'),
      (style.fonts.displaySmall, 'displaySmall'),
      (style.fonts.headlineLarge, 'headlineLarge'),
      (style.fonts.headlineMedium, 'headlineMedium'),
      (style.fonts.headlineSmall, 'headlineSmall'),
      (style.fonts.titleLarge, 'titleLarge'),
      (style.fonts.titleMedium, 'titleMedium'),
      (style.fonts.titleSmall, 'titleSmall'),
      (style.fonts.labelLarge, 'labelLarge'),
      (style.fonts.labelMedium, 'labelMedium'),
      (style.fonts.labelSmall, 'labelSmall'),
      (style.fonts.bodyLarge, 'bodyLarge'),
      (style.fonts.bodyMedium, 'bodyMedium'),
      (style.fonts.bodySmall, 'bodySmall'),
    ];

    final Iterable<(TextStyle, String, String)> schema = [
      // Display large
      (style.fonts.displayLarge, 'displayLarge', 'Unused'),
      (
        style.fonts.displayLargeOnPrimary,
        'displayLargeOnPrimary',
        '"CallTitle" title'
      ),

      // Display medium
      (style.fonts.displayMedium, 'displayMedium', 'Unused'),
      (
        style.fonts.displayMediumSecondary,
        'displayMediumSecondary',
        '"Messenger" on auth page'
      ),

      // Display small
      (style.fonts.displaySmall, 'displaySmall', 'Unused'),
      (
        style.fonts.displaySmallSecondary,
        'displaySmallSecondary',
        '"UnreadCounter" when dimmed and inverted'
      ),
      (
        style.fonts.displaySmallOnPrimary,
        'displaySmallOnPrimary',
        '"UnreadCounter" by default or when dimmed and not inverted'
      ),

      // Headline large
      (
        style.fonts.headlineLarge,
        'headlineLarge',
        '"MenuButton", "ChatTile", "ContactTile" title'
      ),
      (
        style.fonts.headlineLargeOnPrimary,
        'headlineLargeOnPrimary',
        'Mobile title of chat during call \nInverted "MenuButton" title \n'
            'Selected "ChatTile" and "ContactTile" title'
      ),

      // Headline medium
      (
        style.fonts.headlineMedium,
        'headlineMedium',
        'btn_set_password \n"NumCopyable" \n"_repliedMessage" error \nlabel_visible_to \n'
            'MenuTab user name \nlabel_presence \n"CustomAppBar" title \n"Block" title'
      ),

      (
        style.fonts.headlineMediumOnPrimary,
        'headlineMediumOnPrimary',
        '"CallTitle" state \n"ConfirmDialogVariant"'
      ),

      // Headline small
      (style.fonts.headlineSmall, 'headlineSmall', 'Unused'),
      (
        style.fonts.headlineSmallSecondary,
        'headlineSmallSecondary',
        '"time" in MessageFieldView \nlabel_forwarded_messages \nlabel_kb'
      ),
      (
        style.fonts.headlineSmallOnPrimary,
        'headlineSmallOnPrimary',
        '"RoundFloatingButton" and "RtcVideoView" label \nCurrent video position and duration'
      ),
      (
        style.fonts.headlineSmallOnPrimary.copyWith(
          shadows: [
            Shadow(blurRadius: 6, color: style.colors.onBackground),
            Shadow(blurRadius: 6, color: style.colors.onBackground),
          ],
        ),
        'headlineSmallOnPrimary',
        '"RoundFloatingButton" and "TooltipButton" hint'
      ),

      // Title large
      (
        style.fonts.titleLarge,
        'titleLarge',
        'ShadowedRoundedButton label \n"ConfirmLogoutView" user \n"PrimaryButton"'
      ),
      (
        style.fonts.titleLargeSecondary,
        'titleLargeSecondary',
        'alert_are_you_sure_want_to_log_out'
      ),
      (
        style.fonts.titleLargeOnPrimary,
        'titleLargeOnPrimary',
        '"OutlinedRoundedButton" and "ShadowedRoundedButton" label with `primary` or inverted color'
      ),

      // Title medium
      (
        style.fonts.titleMedium,
        'titleMedium',
        'SearchTextField \nAttachmentSelector \nStatusField \nPasswordField \nRepeatPasswordField'
      ),
      (
        style.fonts.titleMediumPrimary,
        'titleMediumPrimary',
        '"CallSettingsView" fields \nMyUser "FieldButton"s \nActionButton'
      ),
      (
        style.fonts.titleMediumSecondary,
        'titleMediumSecondary',
        '"_repliedMessage" label \nMyUser unconfirmed emails and phones'
      ),
      (
        style.fonts.titleMediumSecondary,
        'titleMediumSecondary',
        'AnimatedDots'
      ),

      // Title small
      (style.fonts.titleSmall, 'titleSmall', 'Unused'),
      (
        style.fonts.titleSmallOnPrimary,
        'titleSmallOnPrimary',
        '"CallCoverWidget" title \nLabel or title of "AvatarWidget"'
      ),

      // Label large
      (
        style.fonts.labelLarge,
        'labelLarge',
        '"ChatInfoView" and "UserView" Popups \n"SearchCategory" names'
      ),
      (
        style.fonts.labelLargeSecondary,
        'labelLargeSecondary',
        '"by Gapopa" on auth page \n"ChatItem" time \n"RecentChatTile" updated at \n'
            'label_password_set \nlabel_password_not_set \nConfirmDialog description \n'
            'LoginViewStage labels'
      ),
      (
        style.fonts.labelLargeOnPrimary,
        'labelLargeOnPrimary',
        'Mobile title of chat contains information about current call \n'
            'Add call participants label \nInverted "RecentChatTile" updated at \n'
            '"RectangleButton" label'
      ),

      // Label medium
      (
        style.fonts.labelMedium,
        'labelMedium',
        'NoMessages \nlabel_nothing_found \nMenuButton subtitle'
      ),
      (style.fonts.labelMediumPrimary, 'labelMediumPrimary', 'label_typing'),
      (
        style.fonts.labelMediumSecondary,
        'labelMediumSecondary',
        '"CupertinoButton" label, \nlabel_synchronization \nSearchUserTile label \n'
            '"ContactsTabView" subtitle \nMenuTabView status'
      ),
      (
        style.fonts.labelMediumOnPrimary,
        'labelMediumOnPrimary',
        'Desktop Call title \nDraggable label \nInverted label_typing \nInverted SearchUserTile label \n'
            'Inverted "ContactsTabView" subtitle \nInverted "MenuButton" subtitle'
      ),

      // Label small
      (style.fonts.labelSmall, 'labelSmall', 'Unused'),
      (
        style.fonts.labelSmallPrimary,
        'labelSmallPrimary',
        'label_details \n"MyProfileView" btn_upload and btn_delete \nlabel_nobody'
      ),
      (
        style.fonts.labelSmallSecondary,
        'labelSmallSecondary',
        'Hint of "CallButton" \n"MessageTimestamp" \n"SwipeableStatus" \nlabel_transition_count \n'
            'label_login_visible'
      ),
      (
        style.fonts.labelSmallSecondary.copyWith(
          color: style.colors.secondaryHighlightDark,
        ),
        'labelSmallSecondary',
        'Inverted "MessageTimestamp"'
      ),
      (
        style.fonts.labelSmallOnPrimary,
        'labelSmallOnPrimary',
        'Hint of "CallButton"'
      ),

      // Body large
      (
        style.fonts.bodyLarge,
        'bodyLarge',
        'label_send_message_hint \n Text of the "ChatMessage" \n'
            'label_forwarded_message \nerr_unknown \n'
            '"ChatForwardWidget" and "ChatItem" default style \n'
            '"ChatForwardWidget" and "ChatItem" SelectionText, time, quote, _note, title \n'
            '"DataAttachment" labels \nSearchField, \nProfileTab.background messages \n'
            'btn_unblock'
      ),
      (
        style.fonts.bodyLargePrimary,
        'bodyLargePrimary',
        'label_edit \n"MessageFieldView" preview'
      ),

      // Body medium
      (
        style.fonts.bodyMedium,
        'bodyMedium',
        'IntroductionView "ReactiveTextField"s \nlabel_introduction_description \n'
      ),
      (style.fonts.bodyMediumPrimary, 'bodyMediumPrimary', '"bigButton" title'),
      (
        style.fonts.bodyMediumSecondary,
        'bodyMediumSecondary',
        'label_password_set \nAddEmailView, AddPhoneView labels \nlabel_direct_chat_link_description \n'
            'ChangePasswordView labels and buttons \nRecentChatTile subtitle'
      ),

      (
        style.fonts.bodyMediumOnPrimary,
        'bodyMediumOnPrimary',
        'label_reconnecting_ellipsis \nbtn_share \n"CallNotificationWidget" title \n'
            '"ParticipantOverlayWidget" name \nRewindIndicator label \n Video player error \n'
            'btn_set_password \nSharableTextField \nAddEmailView, AddPhoneView labels \nbtn_proceed \n'
            'Inverted RecentChatTile subtitle \nRectangularCallButton duration \nAvatarWidget title \n'
            'ConfirmDialog label'
      ),

      // Body small
      (
        style.fonts.bodySmall,
        'bodySmall',
        'MessageFiledView content \nMessageInfo ID \nlabel_delete_contact'
      ),
      (
        style.fonts.bodySmallPrimary,
        'bodySmallPrimary',
        'btn_upload \nbtn_delete \nlabel_phone_visible \nlabel_nobody \nbtn_unblock_short \n'
            'btn_forgot_password'
      ),
      (
        style.fonts.bodySmallSecondary,
        'bodySmallSecondary',
        'label_kb \nChatSubtitle labels \nlabel_read_at \nUserView subtitle'
      ),

      (
        style.fonts.bodySmallOnPrimary,
        'bodySmallOnPrimary',
        '"CallButton" description \nlabel_required \nCustomNavigationBarItem'
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
        const Header('Typography'),
        const SubHeader('Fonts'),
        FontSchema(schema, inverted: inverted, dense: dense),
        const SubHeader('Schema'),
        BuilderWrap(
          styles,
          inverted: inverted,
          dense: dense,
          (e) => FontWidget(e, inverted: inverted, dense: dense),
        ),
        const SubHeader('Families'),
        BuilderWrap(
          families,
          inverted: inverted,
          dense: dense,
          (e) => FontFamily(e, inverted: inverted, dense: dense),
        ),
        const SubHeader('Styles'),
        BuilderWrap(
          styles,
          inverted: inverted,
          dense: dense,
          (e) => FontStyleWidget(e, inverted: inverted),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
