// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

  /// Indicates whether this [ChatItem] was sent by [User].
  bool get _isSent => status == SendingStatus.sent;

  /// Indicates whether the status of the sent [ChatItem] is an error.
  bool get _isError => status == SendingStatus.error;

  /// Indicates whether [ChatItem] is in the process of being sent.
  bool get _isSending => status == SendingStatus.sending;

  /// Indicates whether this [ChatItem] has been delivered to [User].
  bool get _isDelivered => _isSent && delivered;

  /// Indicates whether this [ChatItem] has been read by [User].
  bool get _isRead => _isSent && read;

  /// Indicates whether this [ChatItem] was only partially read.
  bool get _isHalfRead => _isSent && halfRead;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final SvgData? icon = _icon();

    return Row(
      key: _key(),
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
        if (icon != null) ...[
          const SizedBox(width: 6),
          SizedBox(width: 17, child: SvgIcon(icon)),
        ],
      ],
    );
  }

  /// Returns a [Key] depending on the [status].
  Key? _key() {
    // Its probably not ours [ChatItem], thus shouldn't append any key.
    if (status == null) {
      return null;
    }

    if (_isError) {
      return Key('Error');
    }

    if (_isSending) {
      return Key('Sending');
    }

    if (_isRead) {
      return Key(_isHalfRead ? 'HalfRead' : 'Read');
    }

    if (_isDelivered) {
      return Key('Delivered');
    }

    if (_isSent) {
      return Key('Sent');
    }

    return Key('NotSent');
  }

  /// Returns an [SvgData] for [SvgIcon] depending on the [status].
  SvgData? _icon() {
    // Its probably not ours [ChatItem], thus shouldn't display any icon.
    if (status == null) {
      return null;
    }

    if (_isRead) {
      if (_isHalfRead) {
        return inverted ? SvgIcons.halfReadWhite : SvgIcons.halfRead;
      }

      return inverted ? SvgIcons.readWhite : SvgIcons.read;
    }

    if (_isDelivered) {
      return inverted ? SvgIcons.deliveredWhite : SvgIcons.delivered;
    }

    if (_isError) {
      return SvgIcons.error;
    }

    if (_isSending) {
      return inverted ? SvgIcons.sendingWhite : SvgIcons.sending;
    }

    if (_isSent) {
      return inverted ? SvgIcons.sentWhite : SvgIcons.sent;
    }

    return null;
  }
}
