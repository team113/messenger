// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/util/platform_utils.dart';
import 'animations.dart';

/// Reactive stylized [TextField] wrapper.
class ReactiveTextField extends StatelessWidget {
  const ReactiveTextField({
    Key? key,
    required this.state,
    this.dense,
    this.enabled = true,
    this.formatters,
    this.hint,
    this.icon,
    this.label,
    this.obscure = false,
    this.onChanged,
    this.style,
    this.suffix,
    this.prefix,
    this.trailing,
    this.type,
    this.minLines,
    this.maxLines = 1,
    this.textInputAction,
    this.onSuffixPressed,
    this.prefixText,
    this.filled,
    this.treatErrorAsStatus = true,
  }) : super(key: key);

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

  /// Optional trailing [Widget].
  final Widget? trailing;

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

  /// Indicator whether the [ReactiveFieldState.error] being non-`null` should
  /// be treated as a [RxStatus.error].
  final bool treatErrorAsStatus;

  /// Indicator whether this [ReactiveTextField] should be filled with [Color].
  final bool? filled;

  @override
  Widget build(BuildContext context) {
    EdgeInsets? contentPadding;

    if (prefix == null && dense != true) {
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

    return Obx(
      () => Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: const ScrollbarThemeData(crossAxisMargin: -10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: state.controller,
              style: style,
              focusNode: state.focus,
              onChanged: (s) {
                state.isEmpty.value = s.isEmpty;
                onChanged?.call();
              },
              onSubmitted: (s) => state.submit(),
              inputFormatters: formatters,
              readOnly: !enabled || !state.editable.value,
              enabled: enabled && state.editable.value,
              decoration: InputDecoration(
                isDense: dense ?? PlatformUtils.isMobile,
                prefixText: prefixText,
                prefix: prefix,
                contentPadding: contentPadding,
                fillColor: filled == false ? Colors.transparent : null,
                suffixIconConstraints: suffix == null &&
                        trailing == null &&
                        state.status.value.isEmpty
                    ? const BoxConstraints(maxWidth: 0)
                    : null,
                suffixIcon: ElasticAnimatedSwitcher(
                  child: (suffix != null ||
                          trailing != null ||
                          !state.status.value.isEmpty)
                      ? Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: ElasticAnimatedSwitcher(
                              child: state.status.value.isLoading
                                  ? const Icon(
                                      Icons.query_builder_outlined,
                                      size: 18,
                                      key: ValueKey('Load'),
                                    )
                                  : state.status.value.isSuccess
                                      ? const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Colors.green,
                                          key: ValueKey('Success'),
                                        )
                                      : (state.error.value != null &&
                                                  treatErrorAsStatus) ||
                                              state.status.value.isError
                                          ? const Icon(
                                              Icons.error,
                                              size: 18,
                                              color: Colors.red,
                                              key: ValueKey('Error'),
                                            )
                                          : IgnorePointer(
                                              ignoring: onSuffixPressed == null,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    BoxConstraints.tight(
                                                  const Size(24, 24),
                                                ),
                                                key: const ValueKey('Icon'),
                                                onPressed: onSuffixPressed,
                                                icon: suffix != null
                                                    ? Icon(suffix)
                                                    : trailing == null
                                                        ? Container()
                                                        : trailing!,
                                              ),
                                            ),
                            ),
                          ),
                        )
                      : const SizedBox(width: 1),
                ),
                icon: icon == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(icon),
                      ),
                labelText: label,
                hintText: hint,
                hintMaxLines: 1,

                // Hide the error's text as the [AnimatedSize] below this
                // [TextField] displays it better.
                errorStyle: const TextStyle(fontSize: 0),
              ),
              obscureText: obscure,
              keyboardType: type,
              minLines: minLines,
              maxLines: maxLines,
              textInputAction: textInputAction,
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
                          padding: const EdgeInsets.only(left: 24, top: 4),
                          child: Text(
                            state.error.value!,
                            style: (style ?? const TextStyle()).copyWith(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
  final FocusNode focus = FocusNode();

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
    bool editable = true,
  }) {
    controller = TextEditingController(text: text);
    isEmpty = RxBool(text?.isEmpty ?? true);

    this.editable = RxBool(editable);
    this.status = Rx(status ?? RxStatus.empty());

    if (onChanged != null) {
      focus.addListener(
        () {
          if (controller.text != _previousText &&
              (_previousText != null || controller.text.isNotEmpty)) {
            isEmpty.value = controller.text.isEmpty;
            if (!focus.hasFocus) {
              onChanged?.call(this);
              _previousText = controller.text;
            }
          }
        },
      );
    }
  }

  /// Callback, called when the [text] has finished changing.
  ///
  /// This callback is fired only when the [text] is changed on:
  /// - submit action of [TextEditingController] was emitted;
  /// - [focus] node changed its focus;
  /// - setter or [submit] was manually called.
  final Function(TextFieldState)? onChanged;

  /// Callback, called when the [text] is submitted.
  ///
  /// This callback is fired only when the [text] value was not yet submitted:
  /// - submit action of [TextEditingController] was emitted;
  /// - [submit] was manually called.
  final Function(TextFieldState)? onSubmitted;

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

  /// Previous [TextEditingController]'s text used to determine if the [text]
  /// was modified on any [focus] change.
  String? _previousText;

  /// Previous [TextEditingController]'s text used to determine if the [text]
  /// was modified since the last [submit] action.
  String? _previousSubmit;

  /// Returns the text of the [TextEditingController].
  String get text => controller.text;

  /// Sets the text of [TextEditingController] to [value] and calls [onChanged].
  set text(String value) {
    controller.text = value;
    isEmpty.value = value.isEmpty;
    onChanged?.call(this);
  }

  /// Sets the text of [TextEditingController] to [value] without calling
  /// [onChanged].
  set unchecked(String? value) {
    controller.text = value ?? '';
    _previousText = value ?? '';
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
      }
    }
  }

  /// Clears the last submitted value.
  void unsubmit() => _previousSubmit = null;

  /// Clears the [TextEditingController]'s text without calling [onChanged].
  void clear() {
    isEmpty.value = true;
    controller.text = '';
    error.value = null;
    _previousText = null;
    _previousSubmit = null;
  }
}
