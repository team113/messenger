import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:phone_form_field/phone_form_field.dart' hide CountrySelector;

import 'animated_size_and_fade.dart';
import 'country_selector2.dart';
import 'text_field.dart';

/// Reactive stylized [TextField] wrapper.
class ReactivePhoneField extends StatelessWidget {
  const ReactivePhoneField({
    super.key,
    required this.state,
    this.label,
  });

  /// Reactive state of this [ReactivePhoneField].
  final PhoneFieldState state;

  final String? label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    EdgeInsets? contentPadding;

    bool isFilled = Theme.of(context).inputDecorationTheme.filled;
    bool isDense = PlatformUtils.isMobile;
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

    return Obx(() {
      return Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: Theme.of(context)
                  .inputDecorationTheme
                  .copyWith(
                    floatingLabelStyle: state.error.value?.isNotEmpty == true
                        ? Theme.of(context)
                            .inputDecorationTheme
                            .floatingLabelStyle
                            ?.copyWith(color: style.colors.danger)
                        : state.isFocused.value
                            ? Theme.of(context)
                                .inputDecorationTheme
                                .floatingLabelStyle
                                ?.copyWith(color: style.colors.primary)
                            : null,
                  ),
            ),
            child: PhoneFormField(
              controller: state.controller2,
              shouldFormat: true,
              autofocus: false,
              autofillHints: const [AutofillHints.telephoneNumber],
              countrySelectorNavigator: const _CountrySelectorNavigator(),
              defaultCountry: IsoCode.US,
              decoration: InputDecoration(
                label: label == null ? null : Text(label!),
                alignLabelWithHint: false,
                border: const OutlineInputBorder(),
                errorStyle: const TextStyle(fontSize: 0),
                errorText: state.error.value,
              ),
              focusNode: state.focus,
              enabled: true,
              showFlagInInput: true,
              validator: PhoneValidator.compose([PhoneValidator.valid()]),
              autovalidateMode: AutovalidateMode.disabled,
              countryCodeStyle: style.fonts.normal.regular.onBackground,
              onSaved: (p) => print('saved $p'),
              onSubmitted: (s) => state.submit(),
              onChanged: (s) {
                state.isEmpty.value = s?.nsn.isEmpty != false;
              },
              isCountryChipPersistent: true,
            ),
          ),

          // Displays an error, if any.
          AnimatedSizeAndFade(
            fadeDuration: 200.milliseconds,
            sizeDuration: 200.milliseconds,
            child: state.error.value == null
                ? const SizedBox(width: double.infinity, height: 0)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Text(
                        state.error.value ?? '',
                        style: style.fonts.small.regular.onBackground.copyWith(
                          color: style.colors.danger,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

/// Wrapper with all the necessary methods and fields to make a [TextField]
/// reactive to any changes and validations.
class PhoneFieldState extends ReactiveFieldState {
  PhoneFieldState({
    PhoneNumber? initial,
    this.onChanged,
    this.onSubmitted,
    RxStatus? status,
    FocusNode? focus,
    bool approvable = false,
    bool editable = true,
    bool submitted = true,
    bool revalidateOnUnfocus = false,
  }) : focus = focus ?? FocusNode() {
    controller = TextEditingController();
    controller2 = PhoneController(null);
    isEmpty = RxBool(initial == null);

    this.editable = RxBool(editable);
    this.status = Rx(status ?? RxStatus.empty());

    if (submitted) {
      _previousSubmit = initial;
    }

    changed.value = _previousSubmit != initial;

    controller2.addListener(() => PlatformUtils.keepActive());

    PhoneNumber? prevPhone = controller2.value;
    controller2.addListener(() {
      if (controller2.value != prevPhone) {
        prevPhone = controller2.value;
        if (revalidateOnUnfocus) {
          error.value = null;
        }
      }
    });

    if (onChanged != null) {
      controller2.addListener(() {
        changed.value = controller2.value != (_previousSubmit ?? '');
      });
    }

    this.focus.addListener(() {
      isFocused.value = this.focus.hasFocus;

      if (onChanged != null) {
        if (controller2.value != _previousText &&
            (_previousText?.nsn.isEmpty == false ||
                controller2.value?.nsn.isEmpty == false)) {
          isEmpty.value = controller2.value?.nsn.isEmpty != false;
          if (!this.focus.hasFocus) {
            onChanged?.call(this);
            _previousText = controller2.value;
          }
        }
      }
    });
  }

  /// [Duration] to debounce the [onChanged] calls with.
  static const Duration debounce = Duration(seconds: 2);

  /// Callback, called when the [text] has finished changing.
  ///
  /// This callback is fired only when the [text] is changed on:
  /// - submit action of [TextEditingController] was emitted;
  /// - [focus] node changed its focus;
  /// - setter or [submit] was manually called.
  Function(PhoneFieldState)? onChanged;

  /// Callback, called when the [text] is submitted.
  ///
  /// This callback is fired only when the [text] value was not yet submitted:
  /// - submit action of [TextEditingController] was emitted;
  /// - [submit] was manually called.
  final Function(PhoneFieldState)? onSubmitted;

  @override
  final RxBool changed = RxBool(false);

  /// [TextEditingController] of this [TextFieldState].
  @override
  late final TextEditingController controller;

  late final PhoneController controller2;

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
  PhoneNumber? _previousText;

  /// Previous [TextEditingController]'s text used to determine if the [text]
  /// was modified since the last [submit] action.
  PhoneNumber? _previousSubmit;

  /// Returns the text of the [TextEditingController].
  PhoneNumber? get phone => controller2.value;

  /// Sets the text of [TextEditingController] to [value] and calls [onChanged].
  set phone(PhoneNumber? value) {
    controller2.value = value;
    _previousText = value;
    isEmpty.value = value?.nsn.isEmpty != false;
    changed.value = true;
    onChanged?.call(this);
  }

  /// Sets the text of [TextEditingController] to [value] without calling
  /// [onChanged].
  set unchecked(PhoneNumber? value) {
    controller2.value = value;
    _previousText = value;
    _previousSubmit = value;
    changed.value = false;
    isEmpty.value = controller2.value?.nsn.isEmpty != false;
  }

  /// Indicates whether [onChanged] was called after the [focus] change and no
  /// more text editing was done since then.
  bool get isValidated => controller2.value == _previousText;

  /// Submits this [TextFieldState].
  @override
  void submit() {
    if (editable.value) {
      if (controller2.value != _previousSubmit) {
        if (_previousText != controller2.value) {
          _previousText = controller2.value;
          onChanged?.call(this);
        }
        _previousSubmit = controller2.value;
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
    controller2.value = null;
    error.value = null;
    _previousText = null;
    _previousSubmit = null;
    changed.value = false;
  }

  @override
  final RxBool hasAllowance = RxBool(false);
}

class _CountrySelectorNavigator extends CountrySelectorNavigator {
  const _CountrySelectorNavigator()
      : super(
          searchAutofocus: false,
        );

  @override
  Future<Country?> navigate(BuildContext context, dynamic flagCache) {
    return ModalPopup.show(
      context: context,
      child: CountrySelector(
        countries: countries,
        onCountrySelected: (country) =>
            Navigator.of(context, rootNavigator: true).pop(country),
        flagCache: flagCache,
      ),
    );
  }
}
