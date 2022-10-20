import 'package:flutter/material.dart';

import '../controller.dart';
import '/l10n/l10n.dart';
import '/ui/page/call/widget/round_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// Buttons for select attachments on mobile.
class AttachmentsSelection extends StatelessWidget {
  const AttachmentsSelection(this.c, {Key? key}) : super(key: key);

  /// [ChatController] of this [AttachmentsSelection].
  final ChatController c;

  /// Displays a [AttachmentsSelection] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, ChatController c) {
    return ModalPopup.show(
      context: context,
      mobileConstraints: const BoxConstraints(),
      mobilePadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      desktopConstraints: const BoxConstraints(maxWidth: 400),
      child: AttachmentsSelection(c),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      Widget button({
        required String text,
        IconData? icon,
        Widget? child,
        void Function()? onPressed,
      }) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: RoundFloatingButton(
            text: text,
            withBlur: false,
            onPressed: () {
              onPressed?.call();
              Navigator.of(context).pop();
            },
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
            color: const Color(0xFF63B4FF),
            child: SizedBox(
              width: 60,
              height: 60,
              child: child ?? Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        );
      }

      bool isAndroid = PlatformUtils.isAndroid;

      List<Widget> children = [
        button(
          text: isAndroid ? 'label_photo'.l10n : 'label_camera'.l10n,
          onPressed: c.pickImageFromCamera,
          child: SvgLoader.asset(
            'assets/icons/make_photo.svg',
            width: 60,
            height: 60,
          ),
        ),
        if (isAndroid)
          button(
            text: 'label_video'.l10n,
            onPressed: c.pickVideoFromCamera,
            child: SvgLoader.asset(
              'assets/icons/video_on.svg',
              width: 60,
              height: 60,
            ),
          ),
        button(
          text: 'label_gallery'.l10n,
          onPressed: c.pickMedia,
          child: SvgLoader.asset(
            'assets/icons/gallery.svg',
            width: 60,
            height: 60,
          ),
        ),
        button(
          text: 'label_file'.l10n,
          onPressed: c.pickFile,
          child: SvgLoader.asset(
            'assets/icons/file.svg',
            width: 60,
            height: 60,
          ),
        ),
      ];

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
          const SizedBox(height: 40),
          OutlinedRoundedButton(
            key: const Key('CloseButton'),
            title: Text('btn_close'.l10n),
            onPressed: Navigator.of(context).pop,
            color: const Color(0xFFEEEEEE),
          ),
          const SizedBox(height: 10),
        ],
      );
    });
  }
}
