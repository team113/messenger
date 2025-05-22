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

import 'package:flutter/material.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';

/// [Row] displaying the provided [status] and [at] stylized to be a status of
/// some [ChatItem].
class MessageTimestamp extends StatelessWidget {
  const MessageTimestamp({
    super.key,
    required this.at,
    this.status,
    this.date = false,
    this.read = false,
    this.halfRead = false,
    this.delivered = false,
    this.inverted = false,
    this.fontSize,
  });

  /// [PreciseDateTime] to display in this [MessageTimestamp].
  final PreciseDateTime at;

  /// [SendingStatus] to display in this [MessageTimestamp], if any.
  final SendingStatus? status;

  /// Indicator whether this [MessageTimestamp] should displayed a date.
  final bool date;

  /// Indicator whether this [MessageTimestamp] is considered to be read,
  /// meaning it should display an appropriate icon.
  final bool read;

  /// Indicator whether this [MessageTimestamp] is considered to be read only
  /// partially, meaning it should display an appropriate icon.
  final bool halfRead;

  /// Indicator whether this [MessageTimestamp] is considered to be delivered,
  /// meaning it should display an appropriate icon.
  final bool delivered;

  /// Indicator whether this [MessageTimestamp] should have its colors
  /// inverted.
  final bool inverted;

  /// Optional font size of this [MessageTimestamp].
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final bool isSent = status == SendingStatus.sent;
    final bool isDelivered = isSent && delivered;
    final bool isRead = isSent && read;
    final bool isHalfRead = isSent && halfRead;
    final bool isError = status == SendingStatus.error;
    final bool isSending = status == SendingStatus.sending;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectionContainer.disabled(
          child: Text(
            date ? at.val.toLocal().yMdHm : at.val.toLocal().hm,
            style:
                (inverted
                        ? style.fonts.smaller.regular.onPrimary
                        : style.fonts.smaller.regular.secondary)
                    .copyWith(
                      fontSize:
                          fontSize ??
                          style.fonts.smaller.regular.onBackground.fontSize,
                    ),
          ),
        ),
        if (status != null &&
            (isSent || isDelivered || isRead || isSending || isError)) ...[
          const SizedBox(width: 3),
          SizedBox(
            key: Key(
              isError
                  ? 'Error'
                  : isSending
                  ? 'Sending'
                  : isRead
                  ? isHalfRead
                        ? 'HalfRead'
                        : 'Read'
                  : 'Sent',
            ),
            width: 17,
            child: SvgIcon(
              isRead
                  ? isHalfRead
                        ? inverted
                              ? SvgIcons.halfReadWhite
                              : SvgIcons.halfRead
                        : inverted
                        ? SvgIcons.readWhite
                        : SvgIcons.read
                  : isDelivered
                  ? inverted
                        ? SvgIcons.deliveredWhite
                        : SvgIcons.delivered
                  : isError
                  ? SvgIcons.error
                  : isSending
                  ? inverted
                        ? SvgIcons.sendingWhite
                        : SvgIcons.sending
                  : inverted
                  ? SvgIcons.sentWhite
                  : SvgIcons.sent,
            ),
          ),
        ],
      ],
    );
  }
}
