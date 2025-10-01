// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
    this.trailing,
  });

  MenuButton.tab(
    ProfileTab tab, {
    Key? key,
    this.inverted = false,
    this.onPressed,
  }) : icon = null,
       title = tab.l10n,
       trailing = null,
       subtitle = switch (tab) {
         ProfileTab.public => 'label_public_section_hint'.l10n,
         ProfileTab.signing => 'label_login_section_hint'.l10n,
         ProfileTab.link => 'label_your_direct_link'.l10n,
         ProfileTab.media => 'label_media_section_hint'.l10n,
         ProfileTab.welcome => 'label_welcome_message_hint'.l10n,
         ProfileTab.notifications => 'label_mute_or_unmute_chats'.l10n,
         ProfileTab.storage => 'label_set_cache_limits'.l10n,
         ProfileTab.confidential => 'label_blocked_users'.l10n,
         ProfileTab.interface => 'label_language_and_background'.l10n,
         ProfileTab.devices => 'label_active_sessions'.l10n,
         ProfileTab.download => 'label_ios_android_windows_macos_linux'.l10n,
         ProfileTab.danger => null,
         ProfileTab.legal => null,
         ProfileTab.logout => null,
       },
       leading = switch (tab) {
         ProfileTab.public => const SvgIcon(SvgIcons.menuProfile),
         ProfileTab.signing => const SvgIcon(SvgIcons.menuSigning),
         ProfileTab.link => const SvgIcon(SvgIcons.menuLink),
         ProfileTab.interface => const SvgIcon(SvgIcons.menuBackground),
         ProfileTab.media => const SvgIcon(SvgIcons.menuMedia),
         ProfileTab.welcome => const SvgIcon(SvgIcons.menuWelcome),
         ProfileTab.notifications => const SvgIcon(SvgIcons.menuNotifications),
         ProfileTab.storage => const SvgIcon(SvgIcons.menuStorage),
         ProfileTab.confidential => const SvgIcon(SvgIcons.menuConfidentiality),
         ProfileTab.devices => const SvgIcon(SvgIcons.menuDevices),
         ProfileTab.download => const SvgIcon(SvgIcons.menuDownload),
         ProfileTab.danger => const SvgIcon(SvgIcons.menuDanger),
         ProfileTab.legal => const SvgIcon(SvgIcons.menuLegal),
         ProfileTab.logout => const SvgIcon(SvgIcons.menuLogout),
       },
       super(
         key:
             key ??
             switch (tab) {
               ProfileTab.public => const Key('PublicInformation'),
               ProfileTab.signing => const Key('Signing'),
               ProfileTab.link => const Key('Link'),
               ProfileTab.interface => const Key('Interface'),
               ProfileTab.media => const Key('Media'),
               ProfileTab.welcome => const Key('WelcomeMessage'),
               ProfileTab.notifications => const Key('Notifications'),
               ProfileTab.storage => const Key('Storage'),
               ProfileTab.confidential => const Key('Blocklist'),
               ProfileTab.devices => const Key('Devices'),
               ProfileTab.download => const Key('Download'),
               ProfileTab.danger => const Key('DangerZone'),
               ProfileTab.legal => const Key('Legal'),
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

  /// Optional trailing to display after everything.
  final Widget? trailing;

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
            hoverColor: inverted
                ? style.colors.primary
                : style.cardHoveredColor,
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
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
