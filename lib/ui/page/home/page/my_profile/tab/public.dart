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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/tab/menu/status/view.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Custom-styled [ReactiveTextField] to display editable [name].
class NameField extends StatefulWidget {
  const NameField(this.name, {super.key, this.onCreate});

  /// Name of an [User].
  final UserName? name;

  /// Callback, called when a `UserName` is spotted.
  final FutureOr<void> Function(UserName? name)? onCreate;

  @override
  State<NameField> createState() => _NameFieldState();
}

/// State of an [NameField] maintaining the [_state].
class _NameFieldState extends State<NameField> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.name?.val,
    approvable: true,
    onChanged: (s) async {
      s.error.value = null;
      try {
        if (s.text.isNotEmpty) {
          UserName(s.text);
        }
      } on FormatException catch (_) {
        s.error.value = 'err_incorrect_input'.l10n;
      }
    },
    onSubmitted: (s) async {
      s.error.value = null;
      try {
        if (s.text.isNotEmpty) {
          UserName(s.text);
        }
      } on FormatException catch (_) {
        s.error.value = 'err_incorrect_input'.l10n;
      }

      if (s.error.value == null) {
        s.editable.value = false;
        s.status.value = RxStatus.loading();
        try {
          await widget.onCreate?.call(
            s.text.isNotEmpty ? UserName(s.text) : null,
          );
          s.status.value = RxStatus.empty();
        } catch (e) {
          s.error.value = 'err_data_transfer'.l10n;
          s.status.value = RxStatus.empty();
          rethrow;
        } finally {
          s.editable.value = true;
        }
      }
    },
  );

  @override
  void didUpdateWidget(NameField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
        _state.editable.value) {
      _state.unchecked = widget.name?.val;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Paddings.basic(
      ReactiveTextField(
        key: const Key('NameField'),
        state: _state,
        label: 'label_name'.l10n,
        hint: 'label_name_hint'.l10n,
        filled: true,
        onSuffixPressed: _state.text.isEmpty
            ? null
            : () {
                PlatformUtils.copy(text: _state.text);
                MessagePopup.success('label_copied'.l10n);
              },
        trailing: _state.text.isEmpty
            ? null
            : Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/copy.svg', height: 15),
                ),
              ),
      ),
    );
  }
}

/// Custom-styled [FieldButton] to display user presence.
class PresenceFieldButton extends StatelessWidget {
  const PresenceFieldButton({super.key, this.text, this.backgroundColor});

  /// Optional label of this [PresenceFieldButton].
  final String? text;

  /// [Color] to fill the circle.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Paddings.basic(
      FieldButton(
        onPressed: () => StatusView.show(context, expanded: false),
        hint: 'label_presence'.l10n,
        text: text,
        trailing: CircleAvatar(backgroundColor: backgroundColor, radius: 7),
        style: fonts.titleMedium!.copyWith(color: style.colors.primary),
      ),
    );
  }
}

/// Custom-styled [ReactiveTextField] to display editable [status].
class StatusFieldButton extends StatefulWidget {
  const StatusFieldButton(this.status, {super.key, required this.onCreate});

  /// Status of an [User].
  final UserTextStatus? status;

  /// Callback, called when a `UserTextStatus` is spotted.
  final Future<void> Function(UserTextStatus? status) onCreate;

  @override
  State<StatusFieldButton> createState() => _StatusFieldButtonState();
}

/// State of an [StatusFieldButton] maintaining the [_state].
class _StatusFieldButtonState extends State<StatusFieldButton> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.status?.val ?? '',
    approvable: true,
    onChanged: (s) {
      s.error.value = null;

      try {
        if (s.text.isNotEmpty) {
          UserTextStatus(s.text);
        }
      } on FormatException catch (_) {
        s.error.value = 'err_incorrect_input'.l10n;
      }
    },
    onSubmitted: (s) async {
      try {
        if (s.text.isNotEmpty) {
          UserTextStatus(s.text);
        }
      } on FormatException catch (_) {
        s.error.value = 'err_incorrect_input'.l10n;
      }

      if (s.error.value == null) {
        s.editable.value = false;
        s.status.value = RxStatus.loading();
        try {
          widget.onCreate.call(
            s.text.isNotEmpty ? UserTextStatus(s.text) : null,
          );
          s.status.value = RxStatus.success();
        } catch (e) {
          s.error.value = 'err_data_transfer'.l10n;
          s.status.value = RxStatus.empty();
          rethrow;
        } finally {
          s.editable.value = true;
        }
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Paddings.basic(
      ReactiveTextField(
        key: const Key('StatusField'),
        state: _state,
        label: 'label_status'.l10n,
        filled: true,
        maxLength: 25,
        onSuffixPressed: _state.text.isEmpty
            ? null
            : () {
                PlatformUtils.copy(text: _state.text);
                MessagePopup.success('label_copied'.l10n);
              },
        trailing: _state.text.isEmpty
            ? null
            : Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/copy.svg', height: 15),
                ),
              ),
        style: fonts.titleMedium,
      ),
    );
  }
}
