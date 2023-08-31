import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/hovered_ink.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:phone_form_field/phone_form_field.dart' as pff;
import 'package:circle_flags/circle_flags.dart';

import 'animated_delayed_switcher.dart';
import 'modal_popup.dart';
import 'text_field.dart';

class CountrySelector extends StatefulWidget {
  /// List of countries to display in the selector
  /// Value optional in constructor.
  /// when omitted, the full country list is displayed
  final List<pff.IsoCode>? countries;

  /// Callback triggered when user select a country
  final ValueChanged<pff.Country> onCountrySelected;

  final FlagCache flagCache;

  const CountrySelector({
    super.key,
    required this.onCountrySelected,
    required this.flagCache,
    this.countries,
  });

  @override
  CountrySelectorState createState() => CountrySelectorState();
}

class CountrySelectorState extends State<CountrySelector> {
  final ScrollController _scrollController = ScrollController();

  final CountryService _countryService = CountryService();
  late CountryLocalizations _localizations;
  late List<Country> _countryList;
  late List<Country> _filteredList;

  @override
  void initState() {
    _countryList = _countryService.getAll();
    _filteredList = _countryList;
    _localizations = CountryLocalizations(L10n.chosen.value!.locale);
    _sort();
    super.initState();
  }

  _onSearch(String query) {
    List<Country> result = <Country>[];

    if (query.isEmpty) {
      result.addAll(_countryList);
    } else {
      result = _countryList
          .where((c) => c.startsWith(query, _localizations))
          .toList();
    }

    _filteredList = result;
    _sort();

    setState(() {});
  }

  void _sort() {
    _filteredList.sort(
      (a, b) => _localizations
          .countryName(countryCode: a.countryCode)!
          .compareTo(_localizations.countryName(countryCode: b.countryCode)!),
    );
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
          if (_filteredList.isEmpty)
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
                  padding: const EdgeInsets.only(right: 10),
                  controller: _scrollController,
                  itemCount: _filteredList.length,
                  itemBuilder: (_, i) {
                    final country = _filteredList[i];

                    return InkWellWithHover(
                      key: ValueKey(country.e164Key),
                      onTap: () => widget.onCountrySelected(
                        pff.Country(
                          pff.IsoCode.values.firstWhere(
                            (e) =>
                                e.name.toLowerCase() ==
                                country.countryCode.toLowerCase(),
                          ),
                          country.name,
                        ),
                      ),
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
                              country.countryCode,
                              size: 40,
                              cache: widget.flagCache,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _localizations
                                            .countryName(
                                              countryCode: country.countryCode,
                                            )
                                            ?.replaceAll(RegExp(r'\s+'), ' ') ??
                                        country.name,
                                    style: style.fonts.titleLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+${country.phoneCode}',
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
  }
}
