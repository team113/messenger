// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/api/backend/schema.graphql.dart';
import '/domain/model/operation.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/svg/svgs.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Widget displaying the provided [Operation] visually.
class OperationWidget extends StatelessWidget {
  const OperationWidget(this.operation, {super.key, this.expanded = true});

  /// [Operation] itself.
  final Operation operation;

  /// Indicator whether the details of [operation] should be displayed.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      decoration: BoxDecoration(
        borderRadius: style.cardRadius,
        border: style.cardBorder,
        color: style.colors.onPrimary,
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: _content(context, operation, expanded: expanded),
    );
  }

  /// Contents of the provided [operation] in [expanded] or not state.
  Widget _content(
    BuildContext context,
    Operation operation, {
    bool expanded = false,
  }) {
    final style = Theme.of(context).style;

    final bool positive = operation.amount.sum.val >= 0;

    TableRow row(String label, Widget child) {
      return TableRow(
        children: [
          Text(
            label,
            style: style.fonts.normal.regular.secondary,
            textAlign: TextAlign.right,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle(
                style: style.fonts.normal.regular.secondary.copyWith(
                  color: style.colors.secondaryBackgroundLight,
                ),
                child: child,
              ),
            ),
          ),
        ],
      );
    }

    final List<Widget> more;

    switch (operation.runtimeType) {
      case const (OperationDeposit):
        operation as OperationDeposit;

        more = [
          const SizedBox(height: 8),
          LineDivider('label_information'.l10n),
          const SizedBox(height: 8),
          Table(
            children: [
              row('label_status'.l10n, switch (operation.status) {
                OperationStatus.completed => Text(
                  'label_operation_completed'.l10n,
                ),
                OperationStatus.inProgress => Text(
                  'label_operation_in_progress'.l10n,
                ),
                OperationStatus.failed => Text(
                  'label_operation_failed'.l10n,
                  style: style.fonts.normal.regular.secondary,
                ),
                OperationStatus.artemisUnknown => Text('label_unknown'.l10n),
              }),
              row(
                'label_transaction_id'.l10n,
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${operation.id}'),
                      WidgetSpan(
                        child: WidgetButton(
                          onPressed: () async {
                            PlatformUtils.copy(text: '${operation.id}');
                            MessagePopup.success('label_copied'.l10n);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: SvgIcon(SvgIcons.copySmallThick),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              row('label_details'.l10n, switch (operation.kind) {
                OperationDepositKind.paypal => Text('label_top_up_paypal'.l10n),
                OperationDepositKind.artemisUnknown => Text(
                  'label_unknown'.l10n,
                ),
              }),
            ],
          ),

          if (operation.invoice != null) ...[
            // const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: WidgetButton(
                onPressed: () async {
                  if (PlatformUtils.isWeb) {
                    await launchUrlString(
                      operation.invoice!.val,
                      webOnlyWindowName: '_blank',
                    );
                  } else {
                    await PlatformUtils.saveTo(operation.invoice!.val);
                  }
                },
                child: Text(
                  'btn_invoice'.l10n,
                  style: style.fonts.small.regular.primary,
                ),
              ),
            ),
          ] else
            const SizedBox(height: 8),
        ];
        break;

      case const (OperationDepositBonus):
        operation as OperationDepositBonus;

        more = [
          const SizedBox(height: 8),
          LineDivider('label_information'.l10n),
          const SizedBox(height: 16),
          Table(
            children: [
              row('label_status'.l10n, switch (operation.status) {
                OperationStatus.completed => Text(
                  'label_operation_completed'.l10n,
                ),
                OperationStatus.inProgress => Text(
                  'label_operation_in_progress'.l10n,
                ),
                OperationStatus.failed => Text(
                  'label_operation_failed'.l10n,
                  style: style.fonts.normal.regular.secondary,
                ),
                OperationStatus.artemisUnknown => Text('label_unknown'.l10n),
              }),
              row(
                'label_transaction_id'.l10n,
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${operation.id}'),
                      WidgetSpan(
                        child: WidgetButton(
                          onPressed: () async {
                            PlatformUtils.copy(text: '${operation.id}');
                            MessagePopup.success('label_copied'.l10n);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: SvgIcon(SvgIcons.copySmallThick),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              row(
                'label_details'.l10n,
                Text(
                  'label_top_up_bonus_with_id'.l10nfmt({
                    'id': operation.depositId.val,
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ];
        break;

      default:
        more = [];
        break;
    }

    final String currency = switch (operation.amount.currency.val) {
      'G' => '¤',
      (_) => operation.amount.currency.val,
    };

    final String primaryText =
        '${positive ? '+' : '-'}$currency${operation.amount.sum.val.toStringAsFixed(2)}';
    final TextStyle primaryStyle = style.fonts.big.regular.onBackground
        .copyWith(
          fontWeight: FontWeight.bold,
          color: switch (operation.status) {
            OperationStatus.completed => style.colors.currencyPrimary,
            OperationStatus.inProgress => style.colors.currencySecondary,
            OperationStatus.failed => style.colors.currencySecondary,
            OperationStatus.artemisUnknown => style.colors.secondary,
          },
        );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: primaryText, style: primaryStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return Column(
      children: [
        SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: Text(primaryText, style: primaryStyle),
                  ),

                  if (operation.status == OperationStatus.failed)
                    Positioned(
                      left: 0,
                      top: 1,
                      bottom: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 2,
                          width: textPainter.size.width + 10,
                          color: style.colors.secondaryBackgroundLightest,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${operation.createdAt.val.yMd} ${operation.createdAt.val.hms}',
              style: style.fonts.smaller.regular.secondary,
            ),
            const SizedBox(width: 8),
            SvgIcon(switch (operation.status) {
              OperationStatus.completed => SvgIcons.operationDone,
              OperationStatus.inProgress => SvgIcons.operationSending,
              OperationStatus.failed => SvgIcons.operationCanceled,
              OperationStatus.artemisUnknown => SvgIcons.operationCanceled,
            }),
          ],
        ),
        AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: expanded
              ? Column(children: more)
              : const SizedBox(
                  key: Key('None'),
                  width: double.infinity,
                  height: 8,
                ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
