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
      (style.fonts.displayLarge, 'displayLarge', '0 uses by this color'),
      (style.fonts.displayLargeOnPrimary, 'displayLarge', '"CallTitle" title'),

      // Display medium
      (style.fonts.displayMedium, 'displayMedium', '0 uses by this color'),
      (
        style.fonts.displayMediumSecondary,
        'displayMedium',
        '"Messenger" on auth page'
      ),

      // Display small
      (style.fonts.displaySmall, 'displaySmall', '0 uses by this color'),
      (
        style.fonts.displaySmallSecondary,
        'displaySmall',
        '"UnreadCounter" when dimmed and inverted'
      ),
      (
        style.fonts.displaySmallOnPrimary,
        'displaySmall',
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
        'headlineLarge',
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
        'headlineMedium',
        '"CallTitle" state \n"ConfirmDialogVariant"'
      ),

      // Headline small
      (style.fonts.headlineSmall, 'headlineSmall', '0 uses of this color'),
      (
        style.fonts.headlineSmallSecondary,
        'headlineSmall',
        '"time" in MessageFieldView \nlabel_forwarded_messages \nlabel_kb'
      ),
      (
        style.fonts.headlineSmallOnPrimary,
        'headlineSmall',
        '"RoundFloatingButton" and "RtcVideoView" label \nCurrent video position and duration'
      ),
      (
        style.fonts.headlineSmallShadowed,
        'headlineSmall',
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
        'titleLarge',
        'alert_are_you_sure_want_to_log_out'
      ),
      (
        style.fonts.titleLargeOnPrimary,
        'titleLarge',
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
        'titleMedium',
        '"CallSettingsView" fields \nMyUser "FieldButton"s \nActionButton'
      ),
      (
        style.fonts.titleMediumSecondary,
        'titleMedium',
        '"_repliedMessage" label \nMyUser unconfirmed emails and phones'
      ),
      (style.fonts.titleMediumSecondary, 'titleMedium', 'AnimatedDots'),

      // Title small
      (fonts.titleSmall!, 'titleSmall', '0 uses of this color'),
      (
        style.fonts.titleSmallOnPrimary,
        'titleSmall',
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
        'labelLarge',
        '"by Gapopa" on auth page \n"ChatItem" time \n"RecentChatTile" updated at \n'
            'label_password_set \nlabel_password_not_set \nConfirmDialog description \n'
            'LoginViewStage labels'
      ),
      (
        style.fonts.labelLargeOnPrimary,
        'labelLarge',
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
      (style.fonts.labelMediumPrimary, 'labelMedium', 'label_typing'),
      (
        style.fonts.labelMediumSecondary,
        'labelMedium',
        '"CupertinoButton" label, \nlabel_synchronization \nSearchUserTile label \n'
            '"ContactsTabView" subtitle \nMenuTabView status'
      ),
      (
        style.fonts.labelMediumOnPrimary,
        'labelMedium',
        'Desktop Call title \nDraggable label \nInverted label_typing \nInverted SearchUserTile label \n'
            'Inverted "ContactsTabView" subtitle \nInverted "MenuButton" subtitle'
      ),

      // Label small
      (style.fonts.labelSmall, 'labelSmall', '0 uses of this color'),
      (
        style.fonts.labelSmallPrimary,
        'labelSmall',
        'label_details \n"MyProfileView" btn_upload and btn_delete \nlabel_nobody'
      ),
      (
        style.fonts.labelSmallSecondary,
        'labelSmall',
        'Hint of "CallButton" \n"MessageTimestamp" \n"SwipeableStatus" \nlabel_transition_count \n'
            'label_login_visible'
      ),
      (
        style.fonts.labelSmallSecondaryAuxiliary,
        'labelSmall',
        'Inverted "MessageTimestamp"'
      ),
      (style.fonts.labelSmallOnPrimary, 'labelSmall', 'Hint of "CallButton"'),

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
        'bodyLarge',
        'label_edit \n"MessageFieldView" preview'
      ),

      // Body medium
      (
        style.fonts.bodyMedium,
        'bodyMedium',
        'IntroductionView "ReactiveTextField"s \nlabel_introduction_description \n'
      ),
      (style.fonts.bodyMediumPrimary, 'bodyMedium', '"bigButton" title'),
      (
        style.fonts.bodyMediumSecondary,
        'bodyMedium',
        'label_password_set \nAddEmailView, AddPhoneView labels \nlabel_direct_chat_link_description \n'
            'ChangePasswordView labels and buttons \nRecentChatTile subtitle'
      ),

      (
        style.fonts.bodyMediumOnPrimary,
        'bodyMedium',
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
        'bodySmall',
        'btn_upload \nbtn_delete \nlabel_phone_visible \nlabel_nobody \nbtn_unblock_short \n'
            'btn_forgot_password'
      ),
      (
        style.fonts.bodySmallSecondary,
        'bodySmall',
        'label_kb \nChatSubtitle labels \nlabel_read_at \nUserView subtitle'
      ),
      (
        style.fonts.bodySmallSecondaryOpacity87,
        'bodySmall',
        '"HintWidget" labels'
      ),
      (
        style.fonts.bodySmallOnPrimary,
        'bodySmall',
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
          (e) => FontStyleWidget(e, inverted: inverted),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
