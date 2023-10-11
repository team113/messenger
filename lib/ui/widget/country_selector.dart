import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/hovered_ink.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:phone_form_field/src/widgets/country_selector/country_finder.dart';
import 'package:phone_form_field/l10n/generated/phone_field_localization_en.dart';
import 'package:circle_flags/circle_flags.dart';

import 'animated_delayed_switcher.dart';
import 'modal_popup.dart';
import 'text_field.dart';

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
  final ScrollController _scrollController = ScrollController();

  late CountryFinder _countryFinder;

  @override
  didChangeDependencies() {
    super.didChangeDependencies();

    PhoneFieldLocalization? l10n;

    if (L10n.chosen.value != null) {
      try {
        l10n = lookupPhoneFieldLocalization(L10n.chosen.value!.locale);
      } catch (_) {
        // No-op.
      }
    }

    l10n ??= PhoneFieldLocalizationEn();

    final isoCodes = widget.countries ?? IsoCode.values;
    final countryRegistry = LocalizedCountryRegistry.cached(l10n);
    _countryFinder = CountryFinder(countryRegistry.whereIsoIn(isoCodes));
  }

  _onSearch(String searchedText) {
    _countryFinder.filter(searchedText);
    setState(() {});
  }

  onSubmitted() {
    if (_countryFinder.filteredCountries.isNotEmpty) {
      widget.onCountrySelected(_countryFinder.filteredCountries.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      constraints: const BoxConstraints(maxHeight: 650),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          ModalPopupHeader(text: 'label_country'.l10n),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(child: SearchField(onChanged: _onSearch)),
          ),
          const SizedBox(height: 18),
          if (_countryFinder.filteredCountries.isEmpty)
            Expanded(
              child: AnimatedDelayedSwitcher(
                delay: const Duration(milliseconds: 300),
                child: Center(
                  child: Text(
                    'label_nothing_found'.l10n,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _countryFinder.filteredCountries.length,
                  itemBuilder: (_, i) {
                    final country = _countryFinder.filteredCountries[i];

                    return InkWellWithHover(
                      key: ValueKey(country.isoCode.name),
                      onTap: () => widget.onCountrySelected(country),
                      selectedColor: style.activeColor,
                      unselectedColor: style.colors.onPrimary,
                      selectedHoverColor: style.activeColor,
                      unselectedHoverColor: style.colors.onPrimary.darken(0.03),
                      borderRadius: style.cardRadius,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            CircleFlag(
                              country.isoCode.name,
                              key: ValueKey(
                                  'circle-flag-${country.isoCode.name}'),
                              size: 40,
                              cache: widget.flagCache,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(country.name,
                                      style: style.fonts.titleLarge),
                                  const SizedBox(height: 2),
                                  Text(
                                    country.displayCountryCode,
                                    style: style.fonts.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class SearchField extends StatefulWidget {
  const SearchField({super.key, this.onChanged});

  final void Function(String)? onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextFieldState search = TextFieldState();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ReactiveTextField(
      key: const Key('SearchTextField'),
      state: search,
      label: 'label_search'.l10n,
      style: style.fonts.titleMedium,
      onChanged: () => widget.onChanged?.call(search.text),
    );

    // return CustomAppBar(
    //   // border: Border.all(color: style.colors.primary, width: 2),
    //   title: Theme(
    //     data: MessageFieldView.theme(context),
    //     child: Padding(
    //       padding: const EdgeInsets.symmetric(horizontal: 10),
    //       child: Transform.translate(
    //         offset: const Offset(0, 1),
    //         child: ReactiveTextField(
    //           key: const Key('SearchField'),
    //           state: search,
    //           hint: 'label_search'.l10n,
    //           maxLines: 1,
    //           filled: false,
    //           dense: true,
    //           padding: const EdgeInsets.symmetric(vertical: 8),
    //           style: style.fonts.bodyLarge,
    //           onChanged: () => widget.onChanged?.call(search.text),
    //         ),
    //       ),
    //     ),
    //   ),
    //   actions: [
    //     Obx(() {
    //       Widget? child;

    //       if (search.isEmpty.value == false) {
    //         child = SvgImage.asset(
    //           key: const Key('CloseSearch'),
    //           height: 11,
    //         );
    //       } else {
    //         child = null;
    //       }

    //       return Row(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           if (child != null)
    //             WidgetButton(
    //               key: null,
    //               onPressed: () {
    //                 if (search.isEmpty.value == false) {
    //                   search.clear();
    //                   search.focus.requestFocus();
    //                   widget.onChanged?.call('');
    //                 }
    //               },
    //               child: Container(
    //                 padding: const EdgeInsets.only(left: 12, right: 16),
    //                 height: double.infinity,
    //                 child: SizedBox(
    //                   width: 29.17,
    //                   child: AnimatedButton(
    //                     child: AnimatedSwitcher(
    //                       duration: 250.milliseconds,
    //                       child: child,
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //             ),
    //         ],
    //       );
    //     }),
    //   ],
  }
}
