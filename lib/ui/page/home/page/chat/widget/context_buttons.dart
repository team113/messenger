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

import '/domain/model/chat_item.dart';
import '/l10n/l10n.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// [ContextMenuButton] for copying a [ChatItem].
class CopyContextMenuButton extends ContextMenuButton {
  CopyContextMenuButton({super.onPressed})
    : super(
        key: const Key('CopyButton'),
        label: PlatformUtils.isMobile ? 'btn_copy'.l10n : 'btn_copy_text'.l10n,
        trailing: const SvgIcon(SvgIcons.copy19),
        inverted: const SvgIcon(SvgIcons.copy19White),
      );
}

/// [ContextMenuButton] for deleting a [ChatItem].
class DeleteContextMenuButton extends ContextMenuButton {
  DeleteContextMenuButton({super.onPressed})
    : super(
        key: const Key('DeleteMessageButton'),
        label: PlatformUtils.isMobile
            ? 'btn_delete'.l10n
            : 'btn_delete_message'.l10n,
        trailing: const SvgIcon(SvgIcons.delete19),
        inverted: const SvgIcon(SvgIcons.delete19White),
      );
}

/// [ContextMenuButton] for editing a [ChatItem].
class EditContextMenuButton extends ContextMenuButton {
  EditContextMenuButton({super.onPressed})
    : super(
        key: const Key('EditMessageButton'),
        label: 'btn_edit'.l10n,
        trailing: const SvgIcon(SvgIcons.edit),
        inverted: const SvgIcon(SvgIcons.editWhite),
      );
}

/// [ContextMenuButton] for forwarding a [ChatItem].
class ForwardContextMenuButton extends ContextMenuButton {
  ForwardContextMenuButton({super.onPressed})
    : super(
        key: const Key('ForwardButton'),
        label: PlatformUtils.isMobile
            ? 'btn_forward'.l10n
            : 'btn_forward_message'.l10n,
        trailing: const SvgIcon(SvgIcons.forwardSmall),
        inverted: const SvgIcon(SvgIcons.forwardSmallWhite),
      );
}

/// [ContextMenuButton] for information about a [ChatItem].
class InformationContextMenuButton extends ContextMenuButton {
  InformationContextMenuButton({super.key, super.onPressed})
    : super(
        label: PlatformUtils.isMobile
            ? 'btn_info'.l10n
            : 'btn_message_info'.l10n,
        trailing: const SvgIcon(SvgIcons.info),
        inverted: const SvgIcon(SvgIcons.infoWhite),
      );
}

/// [ContextMenuButton] for replying to a [ChatItem].
class ReplyContextMenuButton extends ContextMenuButton {
  ReplyContextMenuButton({super.onPressed})
    : super(
        key: const Key('ReplyButton'),
        label: PlatformUtils.isMobile
            ? 'btn_reply'.l10n
            : 'btn_reply_message'.l10n,
        trailing: const SvgIcon(SvgIcons.reply),
        inverted: const SvgIcon(SvgIcons.replyWhite),
      );
}

/// [ContextMenuButton] for selecting a [ChatItem].
class SelectContextMenuButton extends ContextMenuButton {
  SelectContextMenuButton({super.onPressed})
    : super(
        key: const Key('Select'),
        label: 'btn_select_messages'.l10n,
        trailing: const SvgIcon(SvgIcons.select),
        inverted: const SvgIcon(SvgIcons.selectWhite),
      );
}
