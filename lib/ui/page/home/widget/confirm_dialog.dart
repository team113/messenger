// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';

/// Variant of a [ConfirmDialog].
class ConfirmDialogVariant {
  const ConfirmDialogVariant({required this.child, this.onProceed});

  /// Callback, called when this [ConfirmDialogVariant] is submitted.
  final void Function()? onProceed;

  /// [Widget] representing this [ConfirmDialogVariant].
  final Widget child;
}

/// Dialog confirming a specific action from the provided [variants].
///
/// Intended to be displayed with the [show] method.
class ConfirmDialog extends StatefulWidget {
  ConfirmDialog({
    Key? key,
    this.description,
    required this.title,
    required this.variants,
    this.initial = 0,
    this.label,
    this.additional = const [],
  })  : assert(variants.isNotEmpty),
        super(key: key);

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
  static Future<ConfirmDialog?> show(
    BuildContext context, {
    String? description,
    required String title,
    required List<ConfirmDialogVariant> variants,
    String? label,
    List<Widget> additional = const [],
    int initial = 0,
  }) {
    return ModalPopup.show<ConfirmDialog?>(
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
  late ConfirmDialogVariant _variant;

  @override
  void didUpdateWidget(ConfirmDialog oldWidget) {
    if (!widget.variants.contains(_variant)) {
      setState(() => _variant = widget.variants.first);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _variant = widget.variants[widget.initial];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    // Builds a button representing the provided [ConfirmDialogVariant].
    Widget button(ConfirmDialogVariant variant) {
      final Style style = Theme.of(context).extension<Style>()!;

      return Padding(
        padding: ModalPopup.padding(context),
        child: Material(
          type: MaterialType.card,
          borderRadius: style.cardRadius,
          color: _variant == variant
              ? style.cardSelectedColor.withOpacity(0.8)
              : style.cardColor.darken(0.05),
          child: InkWell(
            onTap: () => setState(() => _variant = variant),
            borderRadius: style.cardRadius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(color: Colors.black, fontSize: 18),
                      child: variant.child,
                    ),
                  ),
                  IgnorePointer(
                    child: Radio<ConfirmDialogVariant>(
                      value: variant,
                      groupValue: _variant,
                      onChanged: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalPopupHeader(
          header: Center(
            child: Text(widget.title, style: thin?.copyWith(fontSize: 18)),
          ),
        ),
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
                style: thin?.copyWith(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        if (widget.variants.length > 1 && widget.description != null)
          const SizedBox(height: 15),
        if (widget.variants.length > 1)
          Flexible(
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (c, i) => button(widget.variants[i]),
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemCount: widget.variants.length,
            ),
          ),
        if (widget.variants.length > 1 || widget.description != null)
          const SizedBox(height: 25),
        Padding(
          padding: ModalPopup.padding(context),
          child: OutlinedRoundedButton(
            key: const Key('Proceed'),
            maxWidth: double.infinity,
            title: Text(
              widget.label ?? 'btn_proceed'.l10n,
              style: thin?.copyWith(color: Colors.white),
            ),
            onPressed: () {
              _variant.onProceed?.call();
              Navigator.of(context).pop();
            },
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
