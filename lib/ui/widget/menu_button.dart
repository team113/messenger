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
  });

  MenuButton.tab(
    ProfileTab tab, {
    Key? key,
    this.inverted = false,
    this.onPressed,
  })  : icon = null,
        title = switch (tab) {
          ProfileTab.public => 'label_profile'.l10n,
          ProfileTab.signing => 'label_login_options'.l10n,
          ProfileTab.link => 'label_link_to_chat'.l10n,
          ProfileTab.background => 'label_background'.l10n,
          ProfileTab.chats => 'label_chats'.l10n,
          ProfileTab.calls => 'label_calls'.l10n,
          ProfileTab.media => 'label_media'.l10n,
          ProfileTab.notifications => 'label_notifications'.l10n,
          ProfileTab.storage => 'label_storage'.l10n,
          ProfileTab.language => 'label_language'.l10n,
          ProfileTab.blocklist => 'label_blocked_users'.l10n,
          ProfileTab.download => 'label_download'.l10n,
          ProfileTab.danger => 'label_danger_zone'.l10n,
          ProfileTab.logout => 'btn_logout'.l10n,
        },
        subtitle = switch (tab) {
          ProfileTab.public => 'label_public_section_hint'.l10n,
          ProfileTab.signing => 'label_login_section_hint'.l10n,
          ProfileTab.link => 'label_your_direct_link'.l10n,
          ProfileTab.background => 'label_app_background'.l10n,
          ProfileTab.chats => 'label_timeline_style'.l10n,
          ProfileTab.calls => 'label_calls_displaying'.l10n,
          ProfileTab.media => 'label_media_section_hint'.l10n,
          ProfileTab.notifications => 'label_sound_and_vibrations'.l10n,
          ProfileTab.storage => 'label_cache_and_downloads'.l10n,
          ProfileTab.language =>
            L10n.chosen.value?.name ?? 'label_current_language'.l10n,
          ProfileTab.blocklist => 'label_your_blacklist'.l10n,
          ProfileTab.download => 'label_application'.l10n,
          ProfileTab.danger => 'label_delete_account'.l10n,
          ProfileTab.logout => 'label_end_session'.l10n,
        },
        leading = switch (tab) {
          ProfileTab.public => const SvgIcon(SvgIcons.menuProfile),
          ProfileTab.background => const SvgIcon(SvgIcons.menuBackground),
          ProfileTab.blocklist => const SvgIcon(SvgIcons.menuBlocklist),
          ProfileTab.calls => const SvgIcon(SvgIcons.menuCalls),
          ProfileTab.chats => const SvgIcon(SvgIcons.menuChats),
          ProfileTab.danger => const SvgIcon(SvgIcons.menuDanger),
          ProfileTab.download => const SvgIcon(SvgIcons.menuDownload),
          ProfileTab.language => const SvgIcon(SvgIcons.menuLanguage),
          ProfileTab.link => const SvgIcon(SvgIcons.menuLink),
          ProfileTab.logout => const SvgIcon(SvgIcons.menuLogout),
          ProfileTab.media => const SvgIcon(SvgIcons.menuMedia),
          ProfileTab.notifications => const SvgIcon(SvgIcons.menuNotifications),
          ProfileTab.signing => const SvgIcon(SvgIcons.menuSigning),
          ProfileTab.storage => const SvgIcon(SvgIcons.menuStorage),
        },
        super(
          key: key ??
              switch (tab) {
                ProfileTab.public => const Key('PublicInformation'),
                ProfileTab.signing => const Key('Signing'),
                ProfileTab.link => const Key('Link'),
                ProfileTab.background => const Key('Background'),
                ProfileTab.chats => const Key('Chats'),
                ProfileTab.calls => const Key('Calls'),
                ProfileTab.media => const Key('Media'),
                ProfileTab.notifications => const Key('Notifications'),
                ProfileTab.storage => const Key('Storage'),
                ProfileTab.language => const Key('Language'),
                ProfileTab.blocklist => const Key('Blocklist'),
                ProfileTab.download => const Key('Download'),
                ProfileTab.danger => const Key('DangerZone'),
                ProfileTab.logout => const Key('LogoutButton'),
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

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 73),
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
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          DefaultTextStyle(
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: inverted
                                ? style.fonts.big.regular.onPrimary
                                : style.fonts.big.regular.onBackground,
                            child: Text(title!),
                          ),
                        if (title != null && subtitle != null)
                          const SizedBox(height: 6),
                        if (subtitle != null)
                          DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inverted
                                ? style.fonts.small.regular.onPrimary
                                : style.fonts.small.regular.onBackground,
                            child: Text(subtitle!),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
