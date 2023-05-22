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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'allow_overflow.dart';
import 'animations.dart';
import 'svg/svg.dart';

/// Reactive stylized [TextField] wrapper.
class ReactiveTextField extends StatelessWidget {
  const ReactiveTextField({
    super.key,
    required this.state,
    this.dense,
    this.enabled = true,
    this.fillColor,
    this.filled,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
    this.focusNode,
    this.formatters,
    this.hint,
    this.icon,
    this.label,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscure = false,
    this.onChanged,
    this.onSuffixPressed,
    this.padding,
    this.prefix,
    this.prefixIcon,
    this.prefixIconColor,
    this.prefixStyle,
    this.prefixText,
    this.readOnly = false,
    this.style,
    this.suffix,
    this.suffixColor,
    this.suffixSize,
    this.suffixText,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.trailing,
    this.trailingWidth = 24,
    this.treatErrorAsStatus = true,
    this.type,
  });

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

  final Color? suffixColor;
  final double? suffixSize;
  final String? suffixText;

  /// Optional content padding.
  final EdgeInsets? padding;

  /// Optional trailing [Widget].
  final Widget? trailing;
  final double? trailingWidth;

  /// Optional label of this [ReactiveTextField].
  final String? label;

  /// Optional hint of this [ReactiveTextField].
  final String? hint;

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

  /// Callback, called when user presses the [suffix].
  ///
  /// Only meaningful if [suffix] is non-`null`.
  final VoidCallback? onSuffixPressed;

  /// Optional text prefix to display before the input.
  final String? prefixText;
  final TextStyle? prefixStyle;

  /// Indicator whether the [ReactiveFieldState.error] being non-`null` should
  /// be treated as a [RxStatus.error].
  final bool treatErrorAsStatus;

  /// Indicator whether this [ReactiveTextField] should be filled with [Color].
  final bool? filled;

  final Widget? prefixIcon;

  final Color? prefixIconColor;

  final FocusNode? focusNode;

  /// [TextAlign] of this [ReactiveTextField].
  final TextAlign textAlign;

  /// Fill color of the [TextField].
  final Color? fillColor;

  /// Maximum number of characters allowed in this [TextField].
  final int? maxLength;

  final bool readOnly;

  final FloatingLabelBehavior floatingLabelBehavior;

  @override
  Widget build(BuildContext context) {
    EdgeInsets? contentPadding = padding;

    if (prefix == null && dense != true && contentPadding == null) {
      bool isFilled = filled ?? Theme.of(context).inputDecorationTheme.filled;
      bool isDense = dense ?? PlatformUtils.isMobile;
      if (Theme.of(context).inputDecorationTheme.border?.isOutline != true) {
        if (isFilled) {
          contentPadding = isDense
              ? const EdgeInsets.fromLTRB(20, 8, 20, 8)
              : const EdgeInsets.fromLTRB(12, 12, 12, 12);
        } else {
          contentPadding = isDense
              ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
              : const EdgeInsets.fromLTRB(0, 12, 0, 12);
        }
      } else {
        contentPadding = isDense
            ? const EdgeInsets.fromLTRB(12, 20, 12, 12)
            : const EdgeInsets.fromLTRB(12, 24, 12, 16);
      }

      contentPadding = contentPadding + const EdgeInsets.only(left: 10);
    }

    // Builds the suffix depending on the provided states.
    Widget buildSuffix() {
      final Style style = Theme.of(context).extension<Style>()!;

      return Obx(() {
        return WidgetButton(
          onPressed: state.approvable && state.changed.value
              ? state.submit
              : onSuffixPressed,
          child: ElasticAnimatedSwitcher(
            child: (state.approvable ||
                    suffix != null ||
                    trailing != null ||
                    !state.status.value.isEmpty)
                ? Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: SizedBox(
                      height: 24,
                      child: ElasticAnimatedSwitcher(
                        child: state.status.value.isLoading
                            ? SvgImage.asset(
                                'assets/icons/timer.svg',
                                width: 17,
                                height: 17,
                              )
                            : state.status.value.isSuccess
                                ? SizedBox(
                                    key: const ValueKey('Success'),
                                    width: 24,
                                    child: Icon(
                                      Icons.check,
                                      size: 18,
                                      color: style.colors.acceptAuxiliaryColor,
                                    ),
                                  )
                                : (state.error.value != null &&
                                            treatErrorAsStatus) ||
                                        state.status.value.isError
                                    ? SizedBox(
                                        key: const ValueKey('Error'),
                                        width: 24,
                                        child: Icon(
                                          Icons.error,
                                          size: 18,
                                          color: style.colors.dangerColor,
                                        ),
                                      )
                                    : (state.approvable && state.changed.value)
                                        ? AllowOverflow(
                                            key: const ValueKey('Approve'),
                                            child: Text(
                                              'btn_save'.l10n,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: style.colors.primary,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          )
                                        : SizedBox(
                                            key: const ValueKey('Icon'),
                                            width: trailingWidth,
                                            child: suffix != null
                                                ? Icon(suffix)
                                                : trailing == null
                                                    ? Container()
                                                    : trailing!,
                                          ),
                      ),
                    ),
                  )
                : const SizedBox(width: 1, height: 0),
          ),
        );
      });
    }

    return Obx(() {
      final Style style = Theme.of(context).extension<Style>()!;

      return Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                floatingLabelStyle: state.error.value?.isNotEmpty == true
                    ? Theme.of(context)
                        .inputDecorationTheme
                        .floatingLabelStyle
                        ?.copyWith(color: style.colors.dangerColor)
                    : state.isFocused.value
                        ? Theme.of(context)
                            .inputDecorationTheme
                            .floatingLabelStyle
                            ?.copyWith(color: style.colors.primary)
                        : null,
              ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              selectionControls: PlatformUtils.isAndroid
                  ? MaterialTextSelectionControls()
                  : PlatformUtils.isIOS
                      ? CupertinoTextSelectionControls()
                      : null,
              controller: state.controller,
              style: this.style,
              focusNode: focusNode ?? state.focus,
              onChanged: (s) {
                state.isEmpty.value = s.isEmpty;
                onChanged?.call();
              },
              textAlign: textAlign,
              onSubmitted: (s) => state.submit(),
              inputFormatters: formatters,
              readOnly: readOnly || (!enabled || !state.editable.value),
              enabled: enabled && state.editable.value,
              decoration: InputDecoration(
                floatingLabelBehavior: floatingLabelBehavior,
                isDense: dense ?? PlatformUtils.isMobile,
                prefixText: prefixText,
                suffixText: suffixText,
                prefixStyle: prefixStyle,
                prefix: prefix,
                prefixIcon: prefixIcon,
                prefixIconColor: prefixIconColor,
                fillColor: fillColor ?? style.colors.onPrimary,
                filled: filled ?? true,
                // fillColor: filled == false ? Colors.transparent : null,
                contentPadding: contentPadding,
                suffixIconConstraints: null,

                // suffixIconConstraints: suffix == null && trailing == null
                //     ? const BoxConstraints(maxWidth: 44)
                //     : null,
                suffixIcon: dense == true ? null : buildSuffix(),
                icon: icon == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(icon),
                      ),
                labelText: label,
                // hintStyle: style?.copyWith(color: Color(0xFFC6C6C6)),
                hintStyle: this.style?.copyWith(
                      // color: Theme.of(context).colorScheme.secondary,
                      color: const Color(0xFFC6C6C6),
                    ),
                hintText: hint,
                hintMaxLines: 1,

                // Hide the error's text as the [AnimatedSize] below this
                // [TextField] displays it better.
                errorStyle: const TextStyle(fontSize: 0),
                errorText: state.error.value,
              ),
              obscureText: obscure,
              keyboardType: type,
              minLines: minLines,
              maxLines: maxLines,
              textInputAction: textInputAction,
              maxLength: maxLength,
            ),

            // Displays an error, if any.
            AnimatedSize(
              duration: 200.milliseconds,
              child: AnimatedSwitcher(
                duration: 200.milliseconds,
                child: state.error.value == null
                    ? const SizedBox(width: double.infinity, height: 1)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Text(
                            state.error.value!,
                            style: (this.style ?? const TextStyle()).copyWith(
                              color: style.colors.dangerColor,
                              fontSize: 13,
                            ),
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
    this.onSubmitted,
    RxStatus? status,
    FocusNode? focus,
    bool approvable = false,
    bool editable = true,
    bool submitted = true,
  }) : focus = focus ?? FocusNode() {
    controller = TextEditingController(text: text);
    isEmpty = RxBool(text?.isEmpty ?? true);

    this.editable = RxBool(editable);
    this.status = Rx(status ?? RxStatus.empty());
    this.approvable = approvable;

    if (submitted) {
      _previousSubmit = text;
    }

    changed.value = _previousSubmit != text;

    if (onChanged != null) {
      controller.addListener(() {
        changed.value = controller.text != (_previousSubmit ?? '');

        _debounceTimer?.cancel();
        _debounceTimer = Timer(debounce, () {
          if (_previousText != controller.text) {
            _previousText = controller.text;
            onChanged?.call(this);
          }
        });
      });
    }

    this.focus.addListener(() {
      isFocused.value = this.focus.hasFocus;

      if (onChanged != null) {
        if (controller.text != _previousText &&
            (_previousText != null || controller.text.isNotEmpty)) {
          isEmpty.value = controller.text.isEmpty;
          if (!this.focus.hasFocus) {
            onChanged?.call(this);
            _previousText = controller.text;
          }
        }
      }
    });
  }

  /// [Duration] to debounce the [onChanged] calls with.
  static const Duration debounce = Duration(milliseconds: 500);

  /// Callback, called when the [text] has finished changing.
  ///
  /// This callback is fired only when the [text] is changed on:
  /// - submit action of [TextEditingController] was emitted;
  /// - [focus] node changed its focus;
  /// - setter or [submit] was manually called.
  Function(TextFieldState)? onChanged;

  /// Callback, called when the [text] is submitted.
  ///
  /// This callback is fired only when the [text] value was not yet submitted:
  /// - submit action of [TextEditingController] was emitted;
  /// - [submit] was manually called.
  final Function(TextFieldState)? onSubmitted;

  @override
  final RxBool changed = RxBool(false);

  /// [TextEditingController] of this [TextFieldState].
  @override
  late final TextEditingController controller;

  /// Reactive [RxStatus] of this [TextFieldState].
  @override
  late final Rx<RxStatus> status;

  /// Indicator whether this [TextFieldState] should be editable or not.
  @override
  late final RxBool editable;

  @override
  late final RxBool isEmpty;

  @override
  late final FocusNode focus;

  /// Previous [TextEditingController]'s text used to determine if the [text]
  /// was modified on any [focus] change.
  String? _previousText;

  /// Previous [TextEditingController]'s text used to determine if the [text]
  /// was modified since the last [submit] action.
  String? _previousSubmit;

  /// [Timer] debouncing the [onChanged] callback.
  Timer? _debounceTimer;

  /// Returns the text of the [TextEditingController].
  String get text => controller.text;

  /// Sets the text of [TextEditingController] to [value] and calls [onChanged].
  set text(String value) {
    controller.text = value;
    _previousText = value;
    isEmpty.value = value.isEmpty;
    changed.value = true;
    onChanged?.call(this);
  }

  /// Sets the text of [TextEditingController] to [value] without calling
  /// [onChanged].
  set unchecked(String? value) {
    controller.text = value ?? '';
    _previousText = value ?? '';
    _previousSubmit = value ?? '';
    changed.value = false;
    isEmpty.value = controller.text.isEmpty;
  }

  /// Indicates whether [onChanged] was called after the [focus] change and no
  /// more text editing was done since then.
  bool get isValidated => controller.text == _previousText;

  /// Submits this [TextFieldState].
  @override
  void submit() {
    if (editable.value) {
      if (controller.text != _previousSubmit) {
        if (_previousText != controller.text) {
          _previousText = controller.text;
          onChanged?.call(this);
        }
        _previousSubmit = controller.text;
        onSubmitted?.call(this);
        changed.value = false;
      }
    }
  }

  /// Clears the last submitted value.
  void unsubmit() {
    _previousSubmit = null;
    changed.value = false;
  }

  /// Clears the [TextEditingController]'s text without calling [onChanged].
  void clear() {
    isEmpty.value = true;
    controller.text = '';
    error.value = null;
    _previousText = null;
    _previousSubmit = null;
    changed.value = false;
    _debounceTimer?.cancel();
  }
}
