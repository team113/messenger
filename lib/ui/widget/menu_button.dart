// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import 'svg/svg.dart';

/// Rounded button with an [icon], [title] and [subtitle] intended to be used in
/// a menu list.
class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.icon,
    this.onPressed,
    this.inverted = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.trailing,
    this.reversed = false,
    this.dense = false,
    this.child,
  });

  MenuButton.tab(
    ProfileTab tab, {
    Key? key,
    this.inverted = false,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.trailing,
  })  : reversed = false,
        dense = false,
        icon = null,
        child = null,
        title = switch (tab) {
          ProfileTab.public => 'label_profile'.l10n,
          ProfileTab.signing => 'label_login_options'.l10n,
          ProfileTab.link => 'label_link_to_chat'.l10n,
          ProfileTab.verification => 'Верификация аккаунта'.l10n,
          ProfileTab.background => 'label_background'.l10n,
          ProfileTab.chats => 'label_chats'.l10n,
          ProfileTab.calls => 'label_calls'.l10n,
          ProfileTab.media => 'label_media'.l10n,
          ProfileTab.welcome => 'label_welcome_message'.l10n,
          ProfileTab.money => 'Монетизация (входящие)'.l10n,
          ProfileTab.moneylist => 'Монетизация (входящие)'.l10n,
          ProfileTab.donates => 'Монетизация (донаты)'.l10n,
          ProfileTab.notifications => 'label_notifications'.l10n,
          ProfileTab.storage => 'label_storage'.l10n,
          ProfileTab.language => 'label_language'.l10n,
          ProfileTab.blocklist => 'label_blocked_users'.l10n,
          ProfileTab.devices => 'label_linked_devices'.l10n,
          ProfileTab.sections => 'label_show_sections'.l10n,
          ProfileTab.download => 'label_download'.l10n,
          ProfileTab.danger => 'label_danger_zone'.l10n,
          ProfileTab.legal => 'btn_legal_info'.l10n,
          ProfileTab.styles => 'Styles'.l10n,
          ProfileTab.logout => 'btn_logout'.l10n,
        },
        subtitle = switch (tab) {
          ProfileTab.public => 'label_public_section_hint'.l10n,
          ProfileTab.signing => 'label_login_section_hint'.l10n,
          ProfileTab.verification => 'Верификация'.l10n,
          ProfileTab.link => 'label_your_direct_link_section'.l10n,
          ProfileTab.background => 'label_app_background'.l10n,
          ProfileTab.chats => 'label_media_buttons_position'.l10n,
          ProfileTab.calls => 'label_calls_displaying'.l10n,
          ProfileTab.media => 'label_media_section_hint'.l10n,
          ProfileTab.welcome => 'label_add_edit_delete'.l10n,
          ProfileTab.money => 'Все пользователи и контакты'.l10n,
          ProfileTab.moneylist => 'Индивидуальные пользователи'.l10n,
          ProfileTab.donates => 'Донаты'.l10n,
          ProfileTab.notifications => 'label_sound_and_vibrations'.l10n,
          ProfileTab.storage => 'label_cache_and_downloads'.l10n,
          ProfileTab.language =>
            L10n.chosen.value?.name ?? 'label_current_language'.l10n,
          ProfileTab.blocklist => 'label_your_blocklist'.l10n,
          ProfileTab.devices => 'label_devices_section'.l10n,
          ProfileTab.sections => 'label_configure_navigation_panel'.l10n,
          ProfileTab.download => 'label_application'.l10n,
          ProfileTab.danger => 'label_delete_account'.l10n,
          ProfileTab.legal => 'btn_legal_info_description'.l10n,
          ProfileTab.styles => 'Colors, typography, elements'.l10n,
          ProfileTab.logout => 'label_end_session'.l10n,
        },
        leading = switch (tab) {
          ProfileTab.public => const SvgIcon(SvgIcons.menuProfile),
          ProfileTab.background => const SvgIcon(SvgIcons.menuBackground),
          ProfileTab.verification => const SvgIcon(SvgIcons.menuCalls),
          ProfileTab.blocklist => const SvgIcon(SvgIcons.menuBlocklist),
          ProfileTab.calls => const SvgIcon(SvgIcons.menuCalls),
          ProfileTab.chats => const SvgIcon(SvgIcons.menuChats),
          ProfileTab.danger => const SvgIcon(SvgIcons.menuDanger),
          ProfileTab.devices => const SvgIcon(SvgIcons.menuDevices),
          ProfileTab.donates => const SvgIcon(SvgIcons.menuDonate),
          ProfileTab.download => const SvgIcon(SvgIcons.menuDownload),
          ProfileTab.language => const SvgIcon(SvgIcons.menuLanguage),
          ProfileTab.link => const SvgIcon(SvgIcons.menuLink),
          ProfileTab.logout => const SvgIcon(SvgIcons.menuLogout),
          ProfileTab.media => const SvgIcon(SvgIcons.menuMedia),
          ProfileTab.notifications => const SvgIcon(SvgIcons.menuNotifications),
          ProfileTab.money => const SvgIcon(SvgIcons.menuPayment),
          ProfileTab.moneylist => const SvgIcon(SvgIcons.menuPayment),
          ProfileTab.signing => const SvgIcon(SvgIcons.menuSigning),
          ProfileTab.storage => const SvgIcon(SvgIcons.menuStorage),
          ProfileTab.styles => const SvgIcon(SvgIcons.menuStyle),
          ProfileTab.welcome => const SvgIcon(SvgIcons.menuWelcome),
          ProfileTab.sections => const SvgIcon(SvgIcons.menuNav),
          ProfileTab.legal => const SvgIcon(SvgIcons.menuNav),
        },
        super(
          key: key ??
              switch (tab) {
                ProfileTab.public => const Key('PublicInformation'),
                ProfileTab.signing => const Key('Signing'),
                ProfileTab.verification => const Key('Verification'),
                ProfileTab.link => const Key('Link'),
                ProfileTab.background => const Key('Background'),
                ProfileTab.chats => const Key('Chats'),
                ProfileTab.calls => const Key('Calls'),
                ProfileTab.media => const Key('Media'),
                ProfileTab.welcome => const Key('Welcome'),
                ProfileTab.money => const Key('Money'),
                ProfileTab.moneylist => const Key('Moneylist'),
                ProfileTab.donates => const Key('Donates'),
                ProfileTab.notifications => const Key('Notifications'),
                ProfileTab.storage => const Key('Storage'),
                ProfileTab.language => const Key('Language'),
                ProfileTab.blocklist => const Key('Blocklist'),
                ProfileTab.devices => const Key('Devices'),
                ProfileTab.sections => const Key('Vacancies'),
                ProfileTab.download => const Key('Download'),
                ProfileTab.danger => const Key('Danger'),
                ProfileTab.styles => const Key('Styles'),
                ProfileTab.logout => const Key('Logout'),
                ProfileTab.legal => const Key('Legal'),
              },
        );

  /// Optional title of this [MenuButton].
  final String? title;

  /// Optional subtitle of this [MenuButton].
  final String? subtitle;

  /// Optional icon of this [MenuButton].
  final IconData? icon;

  /// Optional leading to display before the [title].
  final Widget? leading;

  /// Callback, called when this [MenuButton] is tapped.
  final void Function()? onPressed;

  /// Indicator whether this [MenuButton] should have its contents inverted.
  final bool inverted;

  final Widget? trailing;
  final EdgeInsets padding;

  final bool reversed;
  final bool dense;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final primaryStyle = inverted
        ? style.fonts.big.regular.onPrimary
        : style.fonts.big.regular.onBackground;
    final secondaryStyle = inverted
        ? style.fonts.small.regular.onPrimary
        : style.fonts.small.regular.secondary;

    return Padding(
      padding: padding,
      child: SizedBox(
        height: dense ? 54 : 73,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            border: style.cardBorder,
            color: style.colors.transparent,
          ),
          child: Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius,
            color: inverted ? style.colors.primary : style.cardColor,
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: onPressed,
              hoverColor:
                  inverted ? style.colors.primary : style.cardHoveredColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(width: 6.5),
                    if (leading != null) leading!,
                    if (icon != null)
                      Icon(
                        icon,
                        color: inverted
                            ? style.colors.onPrimary
                            : style.colors.primary,
                      ),
                    if (leading != null || icon != null)
                      const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (child != null) child!,
                          if (title != null)
                            DefaultTextStyle(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: reversed ? secondaryStyle : primaryStyle,
                              child: Text(title!),
                            ),
                          if (title != null && subtitle != null)
                            const SizedBox(height: 6),
                          if (subtitle != null)
                            DefaultTextStyle.merge(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: reversed ? primaryStyle : secondaryStyle,
                              child: Row(
                                children: [
                                  Expanded(child: Text(subtitle!)),
                                  if (trailing != null) trailing!,
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (subtitle == null && trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RectangleIcon extends StatelessWidget {
  const RectangleIcon(this.icon, {super.key, this.color});
  RectangleIcon.tab(ProfileTab tab, {super.key})
      : color = Colors.primaries[tab.index % Colors.primaries.length],
        icon = switch (tab) {
          ProfileTab.public => Icons.person,
          ProfileTab.signing => Icons.lock,
          ProfileTab.link => Icons.link,
          ProfileTab.verification => Icons.image,
          ProfileTab.background => Icons.image,
          ProfileTab.chats => Icons.chat_bubble,
          ProfileTab.calls => Icons.call,
          ProfileTab.media => Icons.video_call,
          ProfileTab.welcome => Icons.message,
          ProfileTab.money => Icons.paid,
          ProfileTab.moneylist => Icons.paid,
          ProfileTab.donates => Icons.donut_small,
          ProfileTab.notifications => Icons.notifications,
          ProfileTab.storage => Icons.storage,
          ProfileTab.language => Icons.language,
          ProfileTab.blocklist => Icons.block,
          ProfileTab.devices => Icons.devices,
          ProfileTab.sections => Icons.work,
          ProfileTab.download => Icons.download,
          ProfileTab.danger => Icons.dangerous,
          ProfileTab.styles => Icons.style,
          ProfileTab.logout => Icons.logout,
          ProfileTab.legal => Icons.label,
        };

  final Color? color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Icon(icon, color: style.colors.onPrimary, size: 20),
      ],
    );
  }
}
