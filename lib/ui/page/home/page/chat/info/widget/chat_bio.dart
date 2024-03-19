import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';

class ChatBioField extends StatefulWidget {
  const ChatBioField(
    this.bio, {
    super.key,
    this.editing,
    this.onSubmit,
    this.onEditing,
  });

  final String? bio;
  final bool? editing;
  final void Function(bool)? onEditing;

  /// Callback, called when [ChatDirectLinkSlug] is submitted.
  final Future<void> Function(String?)? onSubmit;

  @override
  State<ChatBioField> createState() => _ChatBioFieldState();
}

class _ChatBioFieldState extends State<ChatBioField> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state;

  bool _editing = false;

  @override
  void initState() {
    _state = TextFieldState(
      text: widget.bio,
      submitted: widget.bio != null,
      onChanged: (s) async {
        s.error.value = null;

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await widget.onSubmit?.call(s.text);
            s.status.value = RxStatus.success();
            await Future.delayed(const Duration(seconds: 1));
            s.status.value = RxStatus.empty();
          } catch (e) {
            s.status.value = RxStatus.empty();
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    if (widget.bio == null) {
      _editing = widget.editing ?? false;
    }

    if (widget.editing != false) {
      _editing = true;
    }

    super.initState();
  }

  @override
  void didUpdateWidget(ChatBioField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
        _state.editable.value) {
      _state.unchecked = widget.bio;

      if (oldWidget.bio != widget.bio && widget.editing != true) {
        _editing = widget.bio == null;
      }
    }

    if (widget.editing == true) {
      _state.unchecked = widget.bio ?? '';

      if (widget.bio == null) {
        _state.unsubmit();
        _state.changed.value = true;
      }
    }

    _editing = widget.editing ?? _editing;

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Widget child;

    if (_editing) {
      child = Column(
        key: const Key('Profile'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            key: const Key('Editing'),
            padding: const EdgeInsets.only(top: 8.0),
            child: SelectionContainer.disabled(
              child: ReactiveTextField(
                key: const Key('LinkField'),
                state: _state,
                clearable: true,
                maxLines: null,
                label: 'Описание',
              ),
            ),
          ),
          const SizedBox(height: 12),
          WidgetButton(
            onPressed: () {
              setState(() => _editing = false);
              widget.onEditing?.call(_editing);
            },
            child: SelectionContainer.disabled(
              child: Text(
                'Готово',
                style: style.fonts.small.regular.primary,
              ),
            ),
          ),
        ],
      );
    } else if (_state.isEmpty.value || widget.bio == null) {
      child = SelectionContainer.disabled(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: WidgetButton(
                onPressed: () {
                  setState(() => _editing = true);
                  widget.onEditing?.call(_editing);
                },
                child: Text(
                  'Добавить описание',
                  style: style.fonts.normal.regular.primary,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      child = Column(
        key: const Key('Edit'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _state.text,
              style: style.fonts.normal.regular.secondary,
            ),
          ),
          const SizedBox(height: 12),
          WidgetButton(
            onPressed: () {
              setState(() => _editing = true);
              widget.onEditing?.call(_editing);
            },
            child: SelectionContainer.disabled(
              child: Text(
                'Изменить',
                style: style.fonts.small.regular.primary,
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedSizeAndFade(
      sizeDuration: const Duration(milliseconds: 300),
      fadeDuration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}
