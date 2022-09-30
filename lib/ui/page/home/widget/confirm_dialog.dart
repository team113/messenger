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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:messenger/ui/widget/modal_popup.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/outlined_rounded_button.dart';

/// Variant of a [ConfirmDialog].
class ConfirmDialogVariant {
  ConfirmDialogVariant({required this.label, required this.onProceed});

  /// Callback, of this [ConfirmDialogVariant].
  void Function() onProceed;

  /// Label of this [ConfirmDialogVariant].
  Widget label;
}

/// Confirmation dialog.
class ConfirmDialog extends StatefulWidget {
  const ConfirmDialog({
    required this.variants,
    required this.title,
    this.noVariantLabel,
    Key? key,
  }) : super(key: key);

  /// List of possible [ConfirmDialogVariant]s of this [ConfirmDialog].
  final List<ConfirmDialogVariant> variants;

  /// Title of this [ConfirmDialog].
  final String title;

  /// Label showed when only one [ConfirmDialogVariant] is available.
  final String? noVariantLabel;

  /// Displays a [ConfirmDialog] wrapped in a [ModalPopup].
  static Future<ConfirmDialog?> show(
    BuildContext context, {
    required List<ConfirmDialogVariant> variants,
    required String title,
    String? noVariantLabel,
  }) {
    return ModalPopup.show<ConfirmDialog?>(
      context: context,
      desktopConstraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
      modalConstraints: const BoxConstraints(maxWidth: 500),
      child: ConfirmDialog(
        variants: variants,
        title: title,
        noVariantLabel: noVariantLabel,
      ),
    );
  }

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  late ConfirmDialogVariant _selectedVariant;

  @override
  void initState() {
    assert(widget.variants.isNotEmpty);

    _selectedVariant = widget.variants.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Text(
            widget.title,
            style: thin?.copyWith(fontSize: 18),
          ),
        ),
        const SizedBox(height: 25),
        if (widget.variants.length > 1)
          ...widget.variants
              .map((e) => _button(context, variant: e, setState: setState))
              .expandIndexed(
                  (i, e) => i > 0 ? [const SizedBox(height: 10), e] : [e])
        else
          widget.noVariantLabel != null
              ? Center(
                  child: Text(
                    widget.noVariantLabel!,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                )
              : Container(),
        if (widget.variants.length > 1 || widget.noVariantLabel != null)
          const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: OutlinedRoundedButton(
                key: const Key('Proceed'),
                maxWidth: null,
                title: Text(
                  'btn_proceed'.l10n,
                  style: thin?.copyWith(color: Colors.white),
                ),
                onPressed: () {
                  _selectedVariant.onProceed();
                  Navigator.of(context).pop();
                },
                color: const Color(0xFF63B4FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedRoundedButton(
                maxWidth: null,
                title: Text('btn_cancel'.l10n, style: thin),
                onPressed: () => Navigator.of(context).pop(true),
                color: const Color(0xFFEEEEEE),
              ),
            )
          ],
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  /// Returns radio button represented the provided [ConfirmDialogVariant].
  Widget _button(
    BuildContext context, {
    required ConfirmDialogVariant variant,
    required StateSetter setState,
  }) {
    ThemeData theme = Theme.of(context);
    Style style = theme.extension<Style>()!;

    return Material(
      type: MaterialType.card,
      borderRadius: style.cardRadius,
      child: InkWell(
        onTap: () => setState(() => _selectedVariant = variant),
        borderRadius: style.cardRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: variant.label,
              ),
              IgnorePointer(
                child: Radio<ConfirmDialogVariant>(
                  value: variant,
                  groupValue: _selectedVariant,
                  onChanged: (ConfirmDialogVariant? value) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
