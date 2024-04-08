import 'package:decimal/decimal.dart';
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
  eur,
  btc,
  usdt;

  String toSymbol() {
    return switch (this) {
      usd => '\$',
      eur => '€',
      btc => 'BTC',
      usdt => 'USDT',
    };
  }

  int toCoins(num amount, [double multiplier = 1]) {
    return switch (this) {
      usd => amount * 100 * multiplier,
      eur => amount * 100 * 1.08 * multiplier,
      btc => amount * 100 / 0.000014 * multiplier,
      usdt => amount * 100 * multiplier,
    }
        .round();
  }

  double fromCoins(num amount, [double multiplier = 1]) {
    return switch (this) {
      usd => amount / 100 * multiplier,
      eur => (amount / 100 / 1.08) * multiplier,
      btc => amount / 100 * 0.000014 * multiplier,
      usdt => amount / 100 * multiplier,
    };
  }
}

/// Reactive stylized [TextField] wrapper.
class CurrencyField extends StatefulWidget {
  CurrencyField({
    super.key,
    required this.currency,
    this.value,
    List<CurrencyKind>? allowed,
    this.onCurrency,
    this.onChanged,
    this.label = 'Currency',
    this.minimum,
    this.maximum,
  }) : allowed = allowed ?? CurrencyKind.values.toList();

  final CurrencyKind? currency;
  final num? value;
  final List<CurrencyKind> allowed;
  final void Function(double)? onChanged;
  final void Function(CurrencyKind)? onCurrency;
  final String label;
  final num? minimum;
  final num? maximum;

  @override
  State<CurrencyField> createState() => _CurrencyFieldState();
}

class _CurrencyFieldState extends State<CurrencyField> {
  late final TextFieldState state = TextFieldState(
    onChanged: (s) {
      s.error.value = null;
      _ensureLimits();
    },
  );

  @override
  void initState() {
    _formatValue();
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    final double current = double.tryParse(state.text) ?? 0;

    if (widget.value != current) {
      setState(() => _formatValue());
      _ensureLimits();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ReactiveTextField(
      state: state,
      label: widget.label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      style: style.fonts.medium.regular.onBackground,
      formatters: [
        // FilteringTextInputFormatter.allow('.'),
        // FilteringTextInputFormatter.digitsOnly,
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]|[.]')),
        LengthLimitingTextInputFormatter(9),
      ],
      onChanged: () {
        final double parsed = double.tryParse(state.text) ?? 0;

        // String string = NumberFormat.decimalPattern().format(parsed);

        // if (string == '0') {
        //   string = '';
        // }

        // state.controller.value = TextEditingValue(
        //   text: string,
        //   selection: TextSelection.collapsed(offset: string.length),
        // );

        widget.onChanged?.call(parsed);
      },
      hint: '0',
      prefixConstraints: widget.currency == null
          ? null
          : BoxConstraints(
              minWidth: 22 + widget.currency!.toSymbol().length * 15,
            ),
      prefixIcon: widget.currency == null
          ? null
          : WidgetButton(
              onPressed: widget.onCurrency == null
                  ? null
                  : () async {
                      final selected = await const _CountrySelectorNavigator()
                          .show(context, widget.currency!);
                      if (selected != null) {
                        widget.onCurrency?.call(selected);
                      }

                      state.focus.requestFocus();
                    },
              child: Center(
                widthFactor: 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 21.0, bottom: 0),
                  child: Text(
                    widget.currency!.toSymbol(),
                    style: style.fonts.big.regular.onBackground.copyWith(
                      color: widget.onCurrency == null
                          ? null
                          : style.colors.primary,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _formatValue() {
    if (widget.value == null) {
      state.text = '';
    } else {
      state.text = Decimal.parse(widget.value.toString()).toString();

      if (state.text == '0.00' || state.text == '0.0' || state.text == '0') {
        state.text = '';
      }
    }
  }

  void _ensureLimits() {
    final double current = double.tryParse(state.text) ?? 0;

    if (current != 0) {
      if (widget.minimum != null && current < widget.minimum!) {
        state.error.value = 'Минимум: ${widget.minimum}';
      } else if (widget.maximum != null && current > widget.maximum!) {
        state.error.value = 'Максимум: ${widget.maximum}';
      }
    }
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
