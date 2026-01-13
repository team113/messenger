// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/context_menu/menu.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'allow_overflow.dart';
import 'animated_button.dart';
import 'animated_switcher.dart';
import 'animations.dart';
import 'svg/svg.dart';
import 'widget_button.dart';

/// Reactive stylized [TextField] wrapper.
class ReactiveTextField extends StatelessWidget {
  const ReactiveTextField({
    super.key,
    required this.state,
    this.dense,
    this.enabled = true,
    this.fillColor,
    this.filled,
    this.formatters,
    this.hint,
    this.hintColor,
    this.icon,
    this.label,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscure = false,
    this.onChanged,
    this.onSuffixPressed,
    this.onCanceled,
    this.padding,
    this.prefix,
    this.prefixText,
    this.prefixStyle,
    this.style,
    this.suffix,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.trailing,
    this.treatErrorAsStatus = true,
    this.type,
    this.subtitle,
    this.clearable = true,
    this.selectable,
    this.floatingAccent = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.spellCheck = true,
    this.autocomplete,
  });

  /// Constructs a [ReactiveTextField] tuned best for password-type fields.
  static Widget password({
    Key? key,
    required TextFieldState state,
    String? label,
    String? hint,
    required RxBool obscured,
    bool treatErrorAsStatus = true,
    TextStyle? style,
    AutocompleteKind autocomplete = AutocompleteKind.currentPassword,
  }) {
    return Obx(() {
      return ReactiveTextField(
        key: key,
        state: state,
        label: label,
        hint: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        trailing: Center(
          child: SvgIcon(
            obscured.value ? SvgIcons.visibleOff : SvgIcons.visibleOn,
          ),
        ),
        obscure: obscured.value,
        onSuffixPressed: obscured.toggle,
        treatErrorAsStatus: treatErrorAsStatus,
        textCapitalization: TextCapitalization.none,
        style: style,
        spellCheck: false,
        autocomplete: autocomplete,
      );
    });
  }

  /// [ReactiveTextField] with trailing copy button.
  factory ReactiveTextField.copyable({
    Key? key,
    required String text,
    String? label,
  }) => ReactiveTextField(
    key: key,
    state: TextFieldState(text: text, editable: false),
    label: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    trailing: WidgetButton(
      onPressed: () {},
      onPressedWithDetails: (u) {
        PlatformUtils.copy(text: text);
        MessagePopup.success('label_copied'.l10n, at: u.globalPosition);
      },
      child: Center(child: SvgIcon(SvgIcons.copy)),
    ),
  );

  /// Reactive state of this [ReactiveTextField].
  final ReactiveFieldState state;

  /// Indicator whether this field should be enabled or not.
  final bool enabled;

  /// Style of the text of the [TextField].
  final TextStyle? style;

  /// Type of the [TextField].
  final TextInputType? type;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional [IconData] to display instead of the [trailing].
  ///
  /// If specified, the [trailing] will be ignored.
  final IconData? suffix;

  /// Optional prefix [Widget].
  final Widget? prefix;

  /// Optional content padding.
  final EdgeInsets? padding;

  /// Optional trailing [Widget].
  final Widget? trailing;

  /// Optional subtitle [Widget].
  final Widget? subtitle;

  /// Optional label of this [ReactiveTextField].
  final String? label;

  /// [FloatingLabelBehavior] of this [ReactiveTextField].
  final FloatingLabelBehavior floatingLabelBehavior;

  /// Optional hint of this [ReactiveTextField].
  final String? hint;

  /// Optional hint color of this [ReactiveTextField].
  final Color? hintColor;

  /// Callback, called when [TextField] is changed.
  ///
  /// Should only be used to rebuild a widget tree. To react to the changes of
  /// this [ReactiveTextField] use [state] instead.
  final VoidCallback? onChanged;

  /// List of [TextInputFormatter] that formats the input of [TextField].
  final List<TextInputFormatter>? formatters;

  /// Indicator whether this [ReactiveTextField] should be dense or not.
  final bool? dense;

  /// Indicator whether [TextField]'s text should be obscured or not.
  final bool obscure;

  /// Minimum number of lines to occupy when the content spans fewer lines.
  final int? minLines;

  /// Maximum number of lines to show at one time, wrapping if necessary.
  final int? maxLines;

  /// Type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [type] is
  /// [TextInputType.multiline], or [TextInputAction.done] otherwise.
  final TextInputAction? textInputAction;

  /// [TextCapitalization] of this [ReactiveTextField].
  ///
  /// Defaults to [TextCapitalization.sentences].
  final TextCapitalization textCapitalization;

  /// Callback, called when user presses the [suffix].
  ///
  /// Only meaningful if [suffix] is non-`null`.
  final void Function()? onSuffixPressed;

  /// Callback, called when user presses the cancel button.
  ///
  /// If `null`, then no cancel button will be displayed.
  final void Function()? onCanceled;

  /// Optional text prefix to display before the input.
  final String? prefixText;

  /// [TextStyle] of the [prefixText].
  final TextStyle? prefixStyle;

  /// Indicator whether the [ReactiveFieldState.error] being non-`null` should
  /// be treated as a [RxStatus.error].
  final bool treatErrorAsStatus;

  /// Indicator whether this [ReactiveTextField] should be filled with [Color].
  final bool? filled;

  /// [TextAlign] of this [ReactiveTextField].
  final TextAlign textAlign;

  /// Fill color of the [TextField].
  final Color? fillColor;

  /// Maximum number of characters allowed in this [TextField].
  final int? maxLength;

  /// Indicator whether this [ReactiveTextField] should display a save button,
  /// when being empty, if [state] is approvable.
  final bool clearable;

  /// Indicator whether text within this [ReactiveTextField] should be
  /// selectable.
  final bool? selectable;

  /// Indicator whether the style of floating [label] should have accent.
  final bool floatingAccent;

  /// Indicator whether spell checking and auto correction should be enabled for
  /// this field.
  final bool spellCheck;

  /// [AutocompleteKind] to pass to this field.
  final AutocompleteKind? autocomplete;

  @override
  Widget build(BuildContext context) {
    EdgeInsets? contentPadding = padding;

    if (prefix == null && dense != true && contentPadding == null) {
      bool isFilled = filled ?? Theme.of(context).inputDecorationTheme.filled;
      bool isDense = dense ?? PlatformUtils.isMobile;
      if (Theme.of(context).inputDecorationTheme.border?.isOutline != true) {
        if (isFilled) {
          contentPadding = isDense
              ? const EdgeInsets.fromLTRB(20, 8, 20, 8) * 0.9
              : const EdgeInsets.fromLTRB(12, 12, 12, 12) * 0.9;
        } else {
          contentPadding = isDense
              ? const EdgeInsets.fromLTRB(8, 8, 8, 8) * 0.9
              : const EdgeInsets.fromLTRB(0, 12, 0, 12) * 0.9;
        }
      } else {
        contentPadding = isDense
            ? const EdgeInsets.fromLTRB(12, 20, 12, 12) * 0.9
            : const EdgeInsets.fromLTRB(12, 24, 12, 16) * 0.9;
      }

      contentPadding = contentPadding + const EdgeInsets.only(left: 10) * 0.5;
    }

    // Builds the suffix depending on the provided states.
    Widget buildSuffix() {
      final style = Theme.of(context).style;

      return Obx(() {
        final RxStatus status = state.status.value;
        final bool hasError =
            status.isError || (state.error.value != null && treatErrorAsStatus);
        final bool hasSuffix =
            state.approvable ||
            suffix != null ||
            trailing != null ||
            !status.isEmpty ||
            hasError ||
            onCanceled != null;

        final Widget cancelButton = AllowOverflow(
          key: const ValueKey('Cancel'),
          child: Text(
            'btn_cancel'.l10n,
            style: style.fonts.small.regular.primary,
          ),
        );

        return ElasticAnimatedSwitcher(
          child: hasSuffix
              ? SizedBox(
                  height: 48,
                  child: AnimatedButton(
                    onPressed:
                        state.approvable &&
                            (state.changed.value ||
                                state.resubmitOnError.isTrue)
                        ? state.isEmpty.value && !clearable
                              ? null
                              : state.submit
                        : onCanceled ?? onSuffixPressed,
                    decorator: (child) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8, right: 16),
                        child: child,
                      );
                    },
                    child: ElasticAnimatedSwitcher(
                      child: status.isLoading
                          ? const SvgIcon(key: Key('Loading'), SvgIcons.timer)
                          : status.isSuccess
                          ? SizedBox(
                              key: const ValueKey('Success'),
                              width: 24,
                              child: Icon(
                                Icons.check,
                                size: 18,
                                color: style.colors.acceptAuxiliary,
                              ),
                            )
                          : hasError
                          ? onCanceled != null
                                ? cancelButton
                                : SizedBox(
                                    key: const ValueKey('Error'),
                                    width: 24,
                                    child: Icon(
                                      Icons.error,
                                      size: 18,
                                      color: style.colors.danger,
                                    ),
                                  )
                          : (state.approvable &&
                                (state.changed.value ||
                                    state.resubmitOnError.isTrue))
                          ? state.isEmpty.value && !clearable
                                ? null
                                : AllowOverflow(
                                    key: const ValueKey('Approve'),
                                    child: Text(
                                      'btn_save'.l10n,
                                      style: style.fonts.small.regular.primary,
                                    ),
                                  )
                          : onCanceled != null
                          ? cancelButton
                          : SizedBox(
                              key: const ValueKey('Icon'),
                              width: 24,
                              child: suffix != null ? Icon(suffix) : trailing,
                            ),
                    ),
                  ),
                )
              : null,
        );
      });
    }

    return Obx(() {
      final style = Theme.of(context).style;

      final decoration = Theme.of(context).inputDecorationTheme;

      final floatingLabel = state.error.value?.isNotEmpty == true
          ? decoration.floatingLabelStyle?.copyWith(color: style.colors.danger)
          : state.isFocused.value
          ? decoration.floatingLabelStyle?.copyWith(color: style.colors.primary)
          : floatingAccent
          ? decoration.floatingLabelStyle?.copyWith(
              fontSize: style.fonts.big.regular.onBackground.fontSize,
              color: style.colors.onBackground,
            )
          : decoration.floatingLabelStyle;

      return Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(
            context,
          ).inputDecorationTheme.copyWith(floatingLabelStyle: floatingLabel),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              enableInteractiveSelection: selectable,
              selectionControls: PlatformUtils.isAndroid
                  ? MaterialTextSelectionControls()
                  : PlatformUtils.isIOS
                  ? CupertinoTextSelectionControls()
                  : null,
              controller: state.controller,
              style: this.style,
              focusNode: state.focus,
              onChanged: (s) {
                state.isEmpty.value = s.isEmpty;
                onChanged?.call();
              },
              textAlign: textAlign,
              onSubmitted: (s) => state.submit(),
              inputFormatters: formatters,
              textAlignVertical: const TextAlignVertical(y: 0.15),
              readOnly: !enabled || !state.editable.value,
              enabled: enabled,
              decoration: InputDecoration(
                alignLabelWithHint: true,
                labelStyle:
                    floatingLabelBehavior == FloatingLabelBehavior.always
                    ? floatingLabel
                    : null,
                floatingLabelBehavior: floatingLabelBehavior,
                isDense: dense ?? PlatformUtils.isMobile,
                focusedBorder: state.editable.value
                    ? null
                    : Theme.of(context).inputDecorationTheme.border,
                prefixText: prefixText,
                prefixStyle: prefixStyle,
                prefix: prefix,
                fillColor:
                    fillColor ??
                    (state.editable.value
                        ? style.colors.onPrimary
                        : style.colors.onPrimaryLight),
                filled: filled ?? true,
                contentPadding: contentPadding,
                suffixIcon: dense == true ? null : buildSuffix(),
                suffixIconConstraints: const BoxConstraints(minWidth: 16),
                icon: icon == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(icon),
                      ),
                labelText: label,
                hintText: hint,
                hintMaxLines: maxLines,
                hintStyle: this.style?.copyWith(
                  color:
                      hintColor ??
                      Theme.of(context).inputDecorationTheme.hintStyle?.color,
                ),

                // Hide the error's text as the [AnimatedSize] below this
                // [TextField] displays it better.
                errorStyle: style.fonts.medium.regular.onBackground.copyWith(
                  fontSize: 0,
                ),
                errorText: state.error.value,
              ),
              obscureText: obscure,
              keyboardType: type,
              minLines: minLines,
              maxLines: maxLines,
              textInputAction: textInputAction,
              textCapitalization: textCapitalization,
              maxLength: maxLength,
              spellCheckConfiguration: spellCheck
                  ? null
                  : SpellCheckConfiguration.disabled(),
              autocorrect: spellCheck ? null : false,
              enableSuggestions: spellCheck,
              autofillHints: [?autocomplete?.value],
              contextMenuBuilder: (_, field) {
                final double dx = field.contextMenuAnchors.primaryAnchor.dx;
                final double dy = field.contextMenuAnchors.primaryAnchor.dy;

                double qx = 0, qy = 0;
                if (dx > (context.mediaQuery.size.width) - 70) qx = -1;
                if (dy > (context.mediaQuery.size.height) - 70) qy = -1;
                final Offset offset = Offset(qx, qy);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: field.contextMenuAnchors.primaryAnchor.dx,
                      top: field.contextMenuAnchors.primaryAnchor.dy,
                      child: FractionalTranslation(
                        translation: offset,
                        child: ContextMenu(
                          actions: [
                            ContextMenuButton(
                              label: 'btn_copy'.l10n,
                              trailing: const SvgIcon(SvgIcons.copy19),
                              inverted: const SvgIcon(SvgIcons.copy19White),
                              onPressed: () {
                                if (field.copyEnabled) {
                                  field.copySelection(
                                    SelectionChangedCause.toolbar,
                                  );
                                } else {
                                  PlatformUtils.copy(
                                    text: state.controller.text,
                                  );
                                  field.hideToolbar();
                                }

                                MessagePopup.success('label_copied'.l10n);
                              },
                            ),
                            if (field.pasteEnabled)
                              ContextMenuButton(
                                label: 'btn_paste'.l10n,
                                trailing: const SvgIcon(SvgIcons.copy19),
                                inverted: const SvgIcon(SvgIcons.copy19White),
                                onPressed: () => field.pasteText(
                                  SelectionChangedCause.toolbar,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Displays the [subtitle] or an error, if any.
            AnimatedSize(
              duration: 200.milliseconds,
              child: SafeAnimatedSwitcher(
                duration: 200.milliseconds,
                child: state.error.value == null
                    ? subtitle != null
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                              child: DefaultTextStyle(
                                style: style.fonts.small.regular.onBackground,
                                child: subtitle!,
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 1)
                    : Padding(
                        key: Key('HasError'),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            state.error.value ?? '',
                            style: style.fonts.small.regular.danger,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Possible autocomplete hints to pass to a [TextField].
enum AutocompleteKind {
  currentPassword,
  newPassword,
  username;

  /// Returns the actual value to use from this [AutocompleteKind].
  String get value {
    return switch (this) {
      currentPassword => 'current-password',
      newPassword => 'new-password',
      username => 'username',
    };
  }
}

/// Abstract wrapper with all the necessary methods and fields to make any input
/// reactive for any changes and validations.
abstract class ReactiveFieldState {
  /// [TextEditingController] of this [ReactiveFieldState].
  TextEditingController get controller;

  /// Reactive [RxStatus] of this [ReactiveFieldState].
  Rx<RxStatus> get status;

  /// Indicator whether this [ReactiveFieldState] should be editable or not.
  RxBool get editable;

  /// Indicator whether [controller]'s text is empty or not.
  RxBool get isEmpty;

  /// [FocusNode] of this [ReactiveFieldState] used to determine focus changes.
  FocusNode get focus;

  /// Indicator whether [controller]'s text was changed.
  RxBool get changed;

  /// Indicator whether [controller]'s text should be approved.
  bool approvable = false;

  /// Reactive [FocusNode.hasFocus] of this [ReactiveFieldState].
  final RxBool isFocused = RxBool(false);

  /// Reactive error message.
  final RxnString error = RxnString();

  /// Indicator whether this [ReactiveFieldState] can still be [submit]ted, when
  /// it has an [error], or is not [changed].
  final RxBool resubmitOnError = RxBool(false);

  /// Indicator whether this [ReactiveFieldState] can be [submit]ted.
  final RxBool submittable = RxBool(true);

  /// Submits this [ReactiveFieldState].
  void submit() {
    // Does nothing by default.
  }
}

/// Wrapper with all the necessary methods and fields to make a [TextField]
/// reactive to any changes and validations.
class TextFieldState extends ReactiveFieldState {
  TextFieldState({
    String? text,
    this.onChanged,
    this.onFocus,
    this.onSubmitted,
    RxStatus? status,
    FocusNode? focus,
    bool approvable = false,
    bool editable = true,
    bool submitted = true,
    String? error,
  }) : focus = focus ?? FocusNode() {
    controller = TextEditingController(text: text);
    isEmpty = RxBool(text?.isEmpty ?? true);

    this.editable = RxBool(editable);
    this.status = Rx(status ?? RxStatus.empty());
    this.approvable = approvable;
    this.error.value = error;

    if (submitted) {
      _previousSubmit = text;
    }

    _previousText = text;

    changed.value = _previousSubmit != text;

    String prev = controller.text;

    controller.addListener(() {
      PlatformUtils.keepActive();

      changed.value = controller.text != (_previousSubmit ?? '');

      if (controller.text != prev) {
        onChanged?.call(this);

        prev = controller.text;
        this.error.value = null;
        resubmitOnError.value = false;
      }
    });

    this.focus.addListener(() async {
      isFocused.value = this.focus.hasFocus;

      if (this.focus.hasFocus) {
        focuses.add(this);
      } else {
        focuses.remove(this);
      }

      if (onFocus != null) {
        if (controller.text != _previousText &&
            (_previousText != null || controller.text.isNotEmpty)) {
          isEmpty.value = controller.text.isEmpty;
          if (!this.focus.hasFocus) {
            await onFocus?.call(this);
            _previousText = controller.text;
          }
        }
      }
    });
  }

  /// Callback, called every time when the [text] changes.
  final Function(TextFieldState)? onChanged;

  /// Callback, called when the [text] has finished changing.
  ///
  /// This callback is fired only when the [text] is changed on:
  /// - submit action of [TextEditingController] was emitted;
  /// - [focus] node changed its focus;
  /// - setter or [submit] was manually called.
  final FutureOr<void> Function(TextFieldState)? onFocus;

  /// Callback, called when the [text] is submitted.
  ///
  /// This callback is fired only when the [text] value was not yet submitted:
  /// - submit action of [TextEditingController] was emitted;
  /// - [submit] was manually called.
  final FutureOr<void> Function(TextFieldState)? onSubmitted;

  @override
  final RxBool changed = RxBool(false);

  @override
  late final TextEditingController controller;

  @override
  late final Rx<RxStatus> status;

  @override
  late final RxBool editable;

  @override
  late final RxBool isEmpty;

  @override
  late final FocusNode focus;

  /// [TextFieldState]s that currently have focus.
  static List<TextFieldState> focuses = [];

  /// Previous [TextEditingController]'s text used to determine if the [text]
  /// was modified on any [focus] change.
  String? _previousText;

  /// Previous [TextEditingController]'s text used to determine if the [text]
  /// was modified since the last [submit] action.
  String? _previousSubmit;

  /// Returns the text of the [TextEditingController].
  String get text => controller.text;

  /// Sets the text of [TextEditingController] to [value] and calls [onFocus]
  /// and [onChanged].
  set text(String value) {
    controller.text = value;
    _previousText = value;
    isEmpty.value = value.isEmpty;
    changed.value = true;
    onChanged?.call(this);
    onFocus?.call(this);
  }

  /// Sets the text of [TextEditingController] to [value] without calling
  /// [onFocus] and [onChanged].
  set unchecked(String? value) {
    controller.text = value ?? '';
    _previousText = value ?? '';
    _previousSubmit = value ?? '';
    changed.value = false;
    isEmpty.value = controller.text.isEmpty;
  }

  /// Indicates whether [onFocus] was called after the [focus] change and no
  /// more text editing was done since then.
  bool get isValidated => controller.text == _previousText;

  @override
  void submit() {
    Log.debug(
      'submit() -> ${editable.isTrue} && ${submittable.isTrue} -> `${controller.text}`',
      '$runtimeType',
    );

    if (editable.isTrue && submittable.isTrue) {
      if (controller.text != _previousSubmit) {
        if (_previousText != controller.text) {
          _previousText = controller.text;
          onChanged?.call(this);
          onFocus?.call(this);
        }

        if (error.value == null || resubmitOnError.isTrue) {
          error.value = null;
          resubmitOnError.value = false;
          _previousSubmit = controller.text;
          onSubmitted?.call(this);
          changed.value = false;
        }
      }
    }
  }

  /// Clears the last submitted value.
  void unsubmit() {
    _previousSubmit = null;
    changed.value = false;
  }

  /// Clears the [TextEditingController]'s text without calling [onFocus] and
  /// [onChanged].
  void clear({bool unfocus = true}) {
    isEmpty.value = true;
    controller.text = '';
    error.value = null;
    _previousText = null;
    _previousSubmit = null;
    changed.value = false;
    if (unfocus) {
      focus.unfocus();
    }
  }
}
