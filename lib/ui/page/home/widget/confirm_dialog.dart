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
  })  : assert(variants.isNotEmpty),
        super(key: key);

  /// [ConfirmDialogVariant]s of this [ConfirmDialog].
  final List<ConfirmDialogVariant> variants;

  /// Title of this [ConfirmDialog].
  final String title;

  /// Optional description to display above the [variants].
  final String? description;

  /// Displays a [ConfirmDialog] wrapped in a [ModalPopup].
  static Future<ConfirmDialog?> show(
    BuildContext context, {
    String? description,
    required String title,
    required List<ConfirmDialogVariant> variants,
  }) {
    return ModalPopup.show<ConfirmDialog?>(
      context: context,
      child: ConfirmDialog(
        description: description,
        title: title,
        variants: variants,
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
  didUpdateWidget(ConfirmDialog oldWidget) {
    if (!widget.variants.contains(_variant)) {
      setState(() {
        _variant = widget.variants.first;
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _variant = widget.variants.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    // Builds a button representing the provided [ConfirmDialogVariant].
    Widget button(ConfirmDialogVariant variant) {
      Style style = Theme.of(context).extension<Style>()!;
      return Material(
        type: MaterialType.card,
        borderRadius: style.cardRadius,
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
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(child: Text(widget.title, style: thin?.copyWith(fontSize: 18))),
        const SizedBox(height: 25),
        if (widget.description != null)
          Center(
            child: Text(
              widget.description!,
              style: thin?.copyWith(fontSize: 18),
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
                  _variant.onProceed?.call();
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
                onPressed: Navigator.of(context).pop,
                color: const Color(0xFFEEEEEE),
              ),
            )
          ],
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}
