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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/widget/text_field.dart';

/// Button for selecting from a list of items.
///
/// Dropdown button lets an user select from a number of items. It shows the
/// currently selected item as well as an arrow that opens a menu for selecting
/// another items.
class ReactiveDropdown<T> extends StatelessWidget {
  const ReactiveDropdown({
    Key? key,
    required this.state,
    this.icon,
    this.label,
  }) : super(key: key);

  /// Reactive state of this [ReactiveDropdown].
  final DropdownFieldState<T> state;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional label of this [ReactiveDropdown].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return StatefulBuilder(
      builder: (context, setState) => Stack(
        children: [
          ReactiveTextField(
            state: state,
            enabled: false,
            label: label,
            hint: label,
            icon: icon,
            suffix: Icons.keyboard_arrow_down,
          ),
          Container(
            height: 50,
            margin: EdgeInsets.only(
              left: icon == null ? 0 : 60,
            ),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
            child: Obx(
              () => DropdownButton<T>(
                value: state.value,
                selectedItemBuilder: (BuildContext context) => state.items
                    .map<Widget>((T item) => const SizedBox())
                    .toList(),
                items: state.items
                    .map<DropdownMenuItem<T>>(
                      (T e) => DropdownMenuItem(
                        value: e,
                        child: Text(state.stringify(e)),
                      ),
                    )
                    .toList(),
                onChanged: state.editable.value
                    ? (d) => setState(() => state.value = d)
                    : null,
                borderRadius: BorderRadius.circular(18),
                isExpanded: true,
                style: style.labelLarge.copyWith(
                  fontWeight: FontWeight.normal,
                ),
                icon: const SizedBox(),
                underline: const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper with all the necessary methods and fields to make a [DropdownButton]
/// reactive to any changes and validations.
class DropdownFieldState<T> extends ReactiveFieldState {
  DropdownFieldState({
    required this.stringify,
    required this.items,
    T? value,
    this.onChanged,
    RxStatus? status,
    bool editable = true,
  })  : _value = value,
        editable = RxBool(editable),
        status = Rx(status ?? RxStatus.empty()) {
    controller = TextEditingController(text: stringify(value));
  }

  /// Conversion function that converts [items] to `String`.
  final String Function(T?) stringify;

  /// List of items selectable by user.
  final List<T> items;

  /// Callback, called when the [value] has changed.
  final Function(DropdownFieldState)? onChanged;

  @override
  late final TextEditingController controller;

  @override
  late final Rx<RxStatus> status;

  @override
  late final RxBool editable;

  @override
  final RxBool isEmpty = RxBool(true);

  @override
  final RxBool changed = RxBool(false);

  @override
  final FocusNode focus = FocusNode();

  /// Currently selected value of this [DropdownFieldState].
  T? _value;

  /// Returns selected value of this [DropdownFieldState].
  T? get value => _value;

  /// Sets text of the [TextEditingController] to [value] and calls [onChanged].
  set value(T? value) {
    unchecked = value;
    onChanged?.call(this);
  }

  /// Sets text of the [TextEditingController] to [value] without calling
  /// [onChanged].
  set unchecked(T? value) {
    controller.text = stringify(value);
    _value = value;
  }
}
