import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/text_field.dart';

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.state,
    this.label,
  });

  final TextFieldState state;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ReactiveTextField(
      state: state,
      style: style.fonts.medium.regular.onBackground,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      formatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      onChanged: () {
        String string =
            NumberFormat.decimalPattern().format(int.tryParse(state.text) ?? 0);

        if (string == '0') {
          string = '';
        }

        state.controller.value = TextEditingValue(
          text: string,
          selection: TextSelection.collapsed(offset: string.length),
        );
      },
      hint: '0',
      prefixIcon: SizedBox(
        child: Center(
          widthFactor: 0.0,
          child: Transform.translate(
            offset: const Offset(12, 0),
            child: Text('¤', style: style.fonts.medium.regular.onBackground),
          ),
        ),
      ),
      label: label,
    );
  }
}
