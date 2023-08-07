import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/search/controller.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/view.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:phone_form_field/src/widgets/country_selector/country_finder.dart';
import 'package:phone_form_field/src/widgets/country_selector/country_list.dart';
import 'package:phone_form_field/l10n/generated/phone_field_localization.dart';
import 'package:phone_form_field/l10n/generated/phone_field_localization_en.dart';
import 'package:phone_form_field/src/widgets/country_selector/localized_country_registry.dart';
import 'package:circle_flags/circle_flags.dart';

import 'animated_button.dart';
import 'animated_size_and_fade.dart';
import 'svg/svg.dart';
import 'text_field.dart';
import 'widget_button.dart';

/// Reactive stylized [TextField] wrapper.
class ReactivePhoneField extends StatelessWidget {
  ReactivePhoneField({
    super.key,
    required this.state,
    this.label,
  });

  /// Reactive state of this [ReactivePhoneField].
  final PhoneFieldState state;

  final String? label;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

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
                            ?.copyWith(color: style.colors.dangerColor)
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
              countryCodeStyle: fonts.titleMedium,
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
                        style: fonts.labelMedium?.copyWith(
                          color: style.colors.dangerColor,
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
}

class _CountrySelectorNavigator extends CountrySelectorNavigator {
  const _CountrySelectorNavigator({
    List<IsoCode>? countries,
    List<IsoCode>? favorites,
    bool addSeparator = true,
    bool showCountryCode = true,
    bool sortCountries = false,
    String? noResultMessage,
    TextStyle? subtitleStyle,
    TextStyle? titleStyle,
    InputDecoration? searchBoxDecoration,
    TextStyle? searchBoxTextStyle,
    Color? searchBoxIconColor,
    ScrollPhysics? scrollPhysics,
  }) : super(
          countries: countries,
          favorites: favorites,
          addSeparator: addSeparator,
          showCountryCode: showCountryCode,
          sortCountries: sortCountries,
          noResultMessage: noResultMessage,
          searchAutofocus: false,
          subtitleStyle: subtitleStyle,
          titleStyle: titleStyle,
          searchBoxDecoration: searchBoxDecoration,
          searchBoxTextStyle: searchBoxTextStyle,
          searchBoxIconColor: searchBoxIconColor,
          scrollPhysics: scrollPhysics,
        );

  @override
  Future<Country?> navigate(BuildContext context, FlagCache flagCache) {
    return ModalPopup.show(
      context: context,
      child: CountrySelector(
        countries: countries,
        onCountrySelected: (country) =>
            Navigator.of(context, rootNavigator: true).pop(country),
        favoriteCountries: favorites ?? [],
        addFavoritesSeparator: addSeparator,
        showCountryCode: showCountryCode,
        noResultMessage: noResultMessage,
        searchAutofocus: searchAutofocus,
        subtitleStyle: subtitleStyle,
        titleStyle: titleStyle,
        searchBoxDecoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,
        ),
        searchBoxTextStyle: searchBoxTextStyle,
        searchBoxIconColor: searchBoxIconColor,
        scrollPhysics: scrollPhysics,
        flagSize: flagSize,
        flagCache: flagCache,
      ),
    );
  }
}

class CountrySelector extends StatefulWidget {
  /// List of countries to display in the selector
  /// Value optional in constructor.
  /// when omitted, the full country list is displayed
  final List<IsoCode>? countries;

  /// Callback triggered when user select a country
  final ValueChanged<Country> onCountrySelected;

  /// ListView.builder scroll controller (ie: [ScrollView.controller])
  final ScrollController? scrollController;

  /// The [ScrollPhysics] of the Country List
  final ScrollPhysics? scrollPhysics;

  /// Determine the countries to be displayed on top of the list
  /// Check [addFavoritesSeparator] property to enable/disable adding a
  /// list divider between favorites and others defaults countries
  final List<IsoCode> favoriteCountries;

  /// Whether to add a list divider between favorites & defaults
  /// countries.
  final bool addFavoritesSeparator;

  /// Whether to show the country country code (ie: +1 / +33 /...)
  /// as a listTile subtitle
  final bool showCountryCode;

  /// The message displayed instead of the list when the search has no results
  final String? noResultMessage;

  /// whether the search input is auto focussed
  final bool searchAutofocus;

  /// The [TextStyle] of the country subtitle
  final TextStyle? subtitleStyle;

  /// The [TextStyle] of the country title
  final TextStyle? titleStyle;

  /// The [InputDecoration] of the Search Box
  final InputDecoration? searchBoxDecoration;

  /// The [TextStyle] of the Search Box
  final TextStyle? searchBoxTextStyle;

  /// The [Color] of the Search Icon in the Search Box
  final Color? searchBoxIconColor;
  final double flagSize;
  final FlagCache flagCache;

  const CountrySelector({
    Key? key,
    required this.onCountrySelected,
    required this.flagCache,
    this.scrollController,
    this.scrollPhysics,
    this.addFavoritesSeparator = true,
    this.showCountryCode = false,
    this.noResultMessage,
    this.favoriteCountries = const [],
    this.countries,
    this.searchAutofocus = false,
    this.subtitleStyle,
    this.titleStyle,
    this.searchBoxDecoration,
    this.searchBoxTextStyle,
    this.searchBoxIconColor,
    this.flagSize = 40,
  }) : super(key: key);

  @override
  CountrySelectorState createState() => CountrySelectorState();
}

class CountrySelectorState extends State<CountrySelector> {
  late CountryFinder _countryFinder;
  late CountryFinder _favoriteCountryFinder;

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    final localization =
        PhoneFieldLocalization.of(context) ?? PhoneFieldLocalizationEn();
    final isoCodes = widget.countries ?? IsoCode.values;
    final countryRegistry = LocalizedCountryRegistry.cached(localization);
    final notFavoriteCountries =
        countryRegistry.whereIsoIn(isoCodes, omit: widget.favoriteCountries);
    final favoriteCountries =
        countryRegistry.whereIsoIn(widget.favoriteCountries);
    _countryFinder = CountryFinder(notFavoriteCountries);
    _favoriteCountryFinder = CountryFinder(favoriteCountries, sort: false);
  }

  _onSearch(String searchedText) {
    _countryFinder.filter(searchedText);
    _favoriteCountryFinder.filter(searchedText);
    setState(() {});
  }

  onSubmitted() {
    if (_favoriteCountryFinder.filteredCountries.isNotEmpty) {
      widget.onCountrySelected(_favoriteCountryFinder.filteredCountries.first);
    } else if (_countryFinder.filteredCountries.isNotEmpty) {
      widget.onCountrySelected(_countryFinder.filteredCountries.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),

        SizedBox(
          height: 65,
          width: double.infinity,
          child: SearchField(
            onChanged: _onSearch,
          ),
        ),

        // child: SearchBox(
        //   autofocus: widget.searchAutofocus,
        //   onChanged: _onSearch,
        //   onSubmitted: onSubmitted,
        //   decoration: widget.searchBoxDecoration,
        //   style: widget.searchBoxTextStyle,
        //   searchIconColor: widget.searchBoxIconColor,
        // ),

        const SizedBox(height: 16),
        Flexible(
          child: CountryList(
            favorites: _favoriteCountryFinder.filteredCountries,
            countries: _countryFinder.filteredCountries,
            showDialCode: widget.showCountryCode,
            onTap: widget.onCountrySelected,
            flagSize: widget.flagSize,
            scrollController: widget.scrollController,
            scrollPhysics: widget.scrollPhysics,
            noResultMessage: widget.noResultMessage,
            titleStyle: widget.titleStyle,
            subtitleStyle: widget.subtitleStyle,
            flagCache: widget.flagCache,
          ),
        ),
      ],
    );
  }
}

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.onChanged,
  });

  final void Function(String)? onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextFieldState search = TextFieldState();

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return CustomAppBar(
      // border: Border.all(color: style.colors.primary, width: 2),
      title: Theme(
        data: MessageFieldView.theme(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.translate(
            offset: const Offset(0, 1),
            child: ReactiveTextField(
              key: const Key('SearchField'),
              state: search,
              hint: 'label_search'.l10n,
              maxLines: 1,
              filled: false,
              dense: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              style: fonts.bodyLarge,
              onChanged: () => widget.onChanged?.call(search.text),
            ),
          ),
        ),
      ),
      actions: [
        Obx(() {
          Widget? child;

          if (search.isEmpty.value == false) {
            child = SvgImage.asset(
              'assets/icons/search_exit.svg',
              key: const Key('CloseSearch'),
              height: 11,
            );
          } else {
            child = null;
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (child != null)
                WidgetButton(
                  key: null,
                  onPressed: () {
                    if (search.isEmpty.value == false) {
                      search.clear();
                      search.focus.requestFocus();
                      widget.onChanged?.call('');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 12, right: 16),
                    height: double.infinity,
                    child: SizedBox(
                      width: 29.17,
                      child: AnimatedButton(
                        child: AnimatedSwitcher(
                          duration: 250.milliseconds,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
      leading: [
        Container(
          padding: const EdgeInsets.only(left: 20, right: 6),
          height: double.infinity,
          child: SvgImage.asset('assets/icons/search.svg', width: 17.77),
        ),
      ],
    );
  }
}
