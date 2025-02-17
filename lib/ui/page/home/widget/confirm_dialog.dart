// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:math';

import 'package:flutter/material.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import 'rectangle_button.dart';

/// Variant of a [ConfirmDialog].
class ConfirmDialogVariant<T> {
  const ConfirmDialogVariant({this.key, required this.label, this.onProceed});

  /// [Key] of this [ConfirmDialogVariant].
  final Key? key;

  /// Callback, called when this [ConfirmDialogVariant] is submitted.
  final T? Function()? onProceed;

  /// Label representing this [ConfirmDialogVariant].
  final String label;
}

/// Dialog confirming a specific action from the provided [variants].
///
/// Intended to be displayed with the [show] method.
class ConfirmDialog extends StatefulWidget {
  ConfirmDialog({
    super.key,
    this.description,
    required this.title,
    required this.variants,
    this.initial = 0,
    this.label,
    this.additional = const [],
  }) : assert(variants.isNotEmpty);

  /// [ConfirmDialogVariant]s of this [ConfirmDialog].
  final List<ConfirmDialogVariant> variants;

  /// Title of this [ConfirmDialog].
  final String title;

  /// Optional description to display above the [variants].
  final String? description;

  /// Label of the submit button.
  final String? label;

  /// [Widget]s to put above the [description].
  final List<Widget> additional;

  /// Index of the [variants] to be initially selected.
  final int initial;

  /// Displays a [ConfirmDialog] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    String? description,
    required String title,
    required List<ConfirmDialogVariant> variants,
    String? label,
    List<Widget> additional = const [],
    int initial = 0,
  }) {
    return ModalPopup.show<T?>(
      context: context,
      child: ConfirmDialog(
        description: description,
        title: title,
        variants: variants,
        additional: additional,
        label: label,
        initial: initial,
      ),
    );
  }

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

/// State of a [ConfirmDialog] keeping the selected [ConfirmDialogVariant].
class _ConfirmDialogState extends State<ConfirmDialog> {
  /// Currently selected [ConfirmDialogVariant].
  late ConfirmDialogVariant _selected;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ConfirmDialog oldWidget) {
    if (!widget.variants.contains(_selected)) {
      setState(() => _selected = widget.variants.first);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _selected = widget
        .variants[max(min(widget.initial, widget.variants.length - 1), 0)];
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalPopupHeader(text: widget.title),
        const SizedBox(height: 12),
        ...widget.additional.map((e) {
          return Padding(padding: ModalPopup.padding(context), child: e);
        }),
        if (widget.additional.isNotEmpty &&
            (widget.variants.length > 1 || widget.description != null))
          const SizedBox(height: 15),
        if (widget.description != null)
          Padding(
            padding: ModalPopup.padding(context),
            child: Center(
              child: Text(
                widget.description!,
                style: style.fonts.normal.regular.secondary,
              ),
            ),
          ),
        if (widget.variants.length > 1 && widget.description != null)
          const SizedBox(height: 15),
        if (widget.variants.length > 1)
          Flexible(
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.separated(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (c, i) {
                  final ConfirmDialogVariant variant = widget.variants[i];

                  return Padding(
                    padding: ModalPopup.padding(context),
                    child: RectangleButton(
                      key: variant.key,
                      selected: _selected == variant,
                      onPressed: _selected == variant
                          ? null
                          : () => setState(() => _selected = variant),
                      label: variant.label,
                      radio: true,
                    ),
                  );
                },
                separatorBuilder: (c, i) => const SizedBox(height: 10),
                itemCount: widget.variants.length,
              ),
            ),
          ),
        if (widget.variants.length > 1 || widget.description != null)
          const SizedBox(height: 25),
        Padding(
          padding: ModalPopup.padding(context),
          child: PrimaryButton(
            key: const Key('Proceed'),
            title: widget.label ?? 'btn_proceed'.l10n,
            onPressed: () {
              Navigator.of(context).pop(_selected.onProceed?.call());
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
