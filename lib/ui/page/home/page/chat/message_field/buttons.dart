import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/round_button.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/controller.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/overlay.dart';
import 'package:messenger/ui/page/home/page/chat/widget/attachment_selector.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

abstract class ChatButton {
  const ChatButton(this.c);

  final MessageFieldController c;

  /// Indicates whether this [CallButton] can be removed from the [Dock].
  bool get isRemovable => true;

  /// Returns a text-represented hint for this [CallButton].
  String get hint;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ChatButton && runtimeType == other.runtimeType;

  /// Returns a styled [RoundFloatingButton] with the provided parameters.
  Widget common({
    required String asset,
    VoidCallback? onPressed,
    bool hinted = true,
    bool expanded = true,
    bool withBlur = false,
    Color color = const Color(0x794E5A78),
    double assetWidth = 60,
    BoxBorder? border,
  }) {
    return RoundFloatingButton(
      asset: asset,
      assetWidth: assetWidth,
      color: color,
      hint: !expanded && hinted ? hint : null,
      text: expanded ? hint : null,
      withBlur: withBlur,
      border: border,
      onPressed: () {
        onPressed?.call();
        c.entry?.remove();
        c.entry = null;
      },
      inverted: true,
      style: TextStyle(
        color: Colors.black,
        fontSize: 11,
      ),
    );
  }

  /// Builds the [Widget] representation of this [CallButton].
  Widget build({bool hinted = true});
}

class AudioMessageButton extends ChatButton {
  const AudioMessageButton(super.c);

  @override
  Widget build({bool hinted = true}) {
    return common(
      asset: 'microphone_on',
      hinted: hinted,
      expanded: !hinted,
    );
  }

  @override
  String get hint => 'Аудио сообщение';
}

class VideoMessageButton extends ChatButton {
  const VideoMessageButton(super.c);

  @override
  Widget build({bool hinted = true}) {
    return common(
      asset: 'video_on',
      hinted: hinted,
      expanded: !hinted,
    );
  }

  @override
  String get hint => 'Видео сообщение';
}

class AttachmentButton extends ChatButton {
  const AttachmentButton(super.c);

  @override
  Widget build({bool hinted = true}) {
    return common(
      asset: 'attach_white',
      assetWidth: 24,
      hinted: hinted,
      expanded: !hinted,
      onPressed: () async {
        if (!PlatformUtils.isMobile || PlatformUtils.isWeb) {
          await c.pickFile();
        } else {
          c.field.focus.unfocus();
          await AttachmentSourceSelector.show(
            router.context!,
            onPickFile: c.pickFile,
            onTakePhoto: c.pickImageFromCamera,
            onPickMedia: c.pickMedia,
            onTakeVideo: c.pickVideoFromCamera,
          );
        }
      },
    );
  }

  @override
  String get hint => 'Прикрепление';
}

class DonateButton extends ChatButton {
  const DonateButton(super.c);

  @override
  Widget build({bool hinted = true}) {
    return common(
      asset: 'video_on',
      hinted: hinted,
      expanded: !hinted,
    );
  }

  @override
  String get hint => 'Донат';
}

class ContactButton extends ChatButton {
  const ContactButton(super.c);

  @override
  Widget build({bool hinted = true}) {
    return common(
      asset: 'video_on',
      hinted: hinted,
      expanded: !hinted,
    );
  }

  @override
  String get hint => 'Контакт';
}

class GeopositionButton extends ChatButton {
  const GeopositionButton(super.c);

  @override
  Widget build({bool hinted = true}) {
    return common(
      asset: 'video_on',
      hinted: hinted,
      expanded: !hinted,
    );
  }

  @override
  String get hint => 'Геопозиция';
}

class MoreButton extends ChatButton {
  const MoreButton(super.c);

  @override
  bool get isRemovable => false;

  @override
  Widget build({bool hinted = true}) {
    return common(
      asset: 'more_white',
      hinted: false,
      expanded: false,
      onPressed: () {
        c.entry?.remove();
        c.entry = null;

        c.entry = OverlayEntry(builder: (context) {
          return MessageFieldOverlay(c);
        });

        router.overlay!.insert(c.entry!);
      },
    );
  }

  @override
  String get hint => throw Exception('Unreachable');
}

class FieldButton extends ChatButton {
  const FieldButton(super.c);

  @override
  bool get isRemovable => false;

  @override
  Widget build({bool hinted = true}) {
    final Style style = Theme.of(router.context!).extension<Style>()!;

    return Padding(
      padding: EdgeInsets.only(
        top: 5 + (PlatformUtils.isMobile ? 0 : 8),
        bottom: 13,
      ),
      child: Transform.translate(
        offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
        child: ReactiveTextField(
          key: const Key('MessageField'),
          state: c.field,
          hint: 'label_send_message_hint'.l10n,
          minLines: 1,
          maxLines: 7,
          filled: false,
          dense: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          style: style.boldBody.copyWith(fontSize: 17),
          type: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
      ),
    );
  }

  @override
  String get hint => throw Exception('Unreachable');
}

class SendButton extends ChatButton {
  const SendButton(super.c);

  @override
  bool get isRemovable => false;

  @override
  Widget build({bool hinted = true}) {
    final Style style = Theme.of(router.context!).extension<Style>()!;

    return Obx(() {
      return GestureDetector(
        onLongPress: c.forwarding.toggle,
        child: WidgetButton(
          onPressed: () {
            if (c.editing.value) {
              c.field.unsubmit();
            }
            c.field.submit();
          },
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: AnimatedSwitcher(
                duration: 300.milliseconds,
                child: c.forwarding.value
                    ? SvgImage.asset(
                        'assets/icons/forward.svg',
                        width: 26,
                        height: 22,
                      )
                    : c.field.isEmpty.value
                        ? Icon(
                            Icons.emoji_emotions_outlined,
                            color: style.colors.primary,
                            size: 28,
                          )
                        : SvgImage.asset(
                            'assets/icons/send.svg',
                            key: const Key('Send'),
                            height: 22.85,
                            width: 25.18,
                          ),
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  String get hint => throw Exception('Unreachable');
}
