import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/text_field.dart';

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.state,
    this.label,
    this.onChanged,
    this.currency = '\$',
    this.maximum,
  });

  final TextFieldState state;
  final String? label;
  final void Function(int)? onChanged;
  final String? currency;
  final double? maximum;

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
        state.error.value = null;

        final int parsed = int.tryParse(state.text) ?? 0;
        String string = parsed.withSpaces;

        if (string == '0') {
          string = '';
        }

        state.controller.value = TextEditingValue(
          text: string,
          selection: TextSelection.collapsed(offset: string.length),
        );

        onChanged?.call(parsed);

        if (maximum != null && parsed > maximum!) {
          state.error.value = 'Превышен баланс';
        }
      },
      hint: '0',
      // prefixIcon: currency == null
      //     ? null
      //     : SizedBox(
      //         child: Center(
      //           widthFactor: 0.0,
      //           child: Transform.translate(
      //             offset: const Offset(12, 0),
      //             child: Text(
      //               currency!,
      //               style: style.fonts.medium.regular.onBackground,
      //             ),
      //           ),
      //         ),
      //       ),
      label: label,
    );
  }
}

extension on num {
  String get withSpaces {
    String value = toString();

    int len = value.length;
    int dlen = 3;

    while (len > dlen) {
      value =
          '${value.substring(0, len - dlen)} ${value.substring(len - dlen, value.length)}';
      dlen += 4;
      len += 1;
    }

    return value;
  }
}
