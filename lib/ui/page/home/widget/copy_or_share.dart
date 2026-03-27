// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:share_plus/share_plus.dart';

import '/l10n/l10n.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [AnimatedButton] displaying a share or copy button, depending on the
/// platform.
class CopyOrShareButton extends StatelessWidget {
  const CopyOrShareButton(this.share, {super.key, this.onPressed});

  /// Text to share or copy.
  final String share;

  /// Callback, called when this [CopyOrShareButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: () async {
        onPressed?.call();

        if (PlatformUtils.isMobile) {
          await SharePlus.instance.share(ShareParams(text: share));
        } else {
          PlatformUtils.copy(text: share);
          MessagePopup.success('label_copied'.l10n);
        }
      },
      child: PlatformUtils.isMobile
          ? const SvgIcon(SvgIcons.share)
          : const SvgIcon(SvgIcons.copy),
    );
  }
}
