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
          await Share.share(share);
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

class CopyOnlyButton extends StatelessWidget {
  const CopyOnlyButton(this.share, {super.key, this.onPressed});

  /// Text to share or copy.
  final String share;

  /// Callback, called when this [CopyOrShareButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: () async {
        onPressed?.call();

        PlatformUtils.copy(text: share);
        MessagePopup.success('label_copied'.l10n);
      },
      child: const SvgIcon(SvgIcons.copySmall),
    );
  }
}
