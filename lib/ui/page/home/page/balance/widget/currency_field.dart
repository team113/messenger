import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';

enum CurrencyKind {
  usd,
  eur;

  String toSymbol() {
    return switch (this) { usd => '\$', eur => '€' };
  }

  int toCoins(int amount) {
    return switch (this) {
      usd => amount * 100,
      eur => (amount * 100 * 1.08).round(),
    };
  }
}

/// Reactive stylized [TextField] wrapper.
class CurrencyField extends StatefulWidget {
  CurrencyField({
    super.key,
    required this.currency,
    List<CurrencyKind>? allowed,
    this.onCurrency,
    this.onChanged,
  }) : allowed = allowed ?? CurrencyKind.values.toList();

  final CurrencyKind currency;
  final List<CurrencyKind> allowed;
  final void Function(int)? onChanged;
  final void Function(CurrencyKind)? onCurrency;

  @override
  State<CurrencyField> createState() => _CurrencyFieldState();
}

class _CurrencyFieldState extends State<CurrencyField> {
  final TextFieldState state = TextFieldState();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ReactiveTextField(
      state: state,
      label: 'Currency',
      floatingLabelBehavior: FloatingLabelBehavior.always,
      style: style.fonts.medium.regular.onBackground,
      formatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      onChanged: () {
        final int parsed = int.tryParse(state.text) ?? 0;
        String string = NumberFormat.decimalPattern().format(parsed);

        if (string == '0') {
          string = '';
        }

        state.controller.value = TextEditingValue(
          text: string,
          selection: TextSelection.collapsed(offset: string.length),
        );

        widget.onChanged?.call(parsed);
      },
      hint: '0',
      prefixIcon: WidgetButton(
        onPressed: () async {
          final selected = await const _CountrySelectorNavigator()
              .show(context, widget.currency);
          if (selected != null) {
            widget.onCurrency?.call(selected);
          }

          state.focus.requestFocus();
        },
        child: Center(
          widthFactor: 0,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 0),
            child: Text(
              widget.currency.toSymbol(),
              style: style.fonts.big.regular.onBackground.copyWith(
                color: widget.onCurrency == null ? null : style.colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountrySelectorNavigator {
  const _CountrySelectorNavigator();

  Future<CurrencyKind?> show(BuildContext context, CurrencyKind selected) {
    return ModalPopup.show(
      context: context,
      child: Builder(
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModalPopupHeader(text: 'Валюта'),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: CurrencyKind.values.map((e) {
                    return Padding(
                      padding: ModalPopup.padding(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: MenuButton(
                          title: e.name,
                          dense: true,
                          inverted: e == selected,
                          onPressed: () => Navigator.of(context).pop(e),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
