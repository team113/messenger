import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/themes.dart';

/// [Row] displaying the provided [status] and [at] stylized to be a status of
/// some [ChatItem].
class MessageTimestamp extends StatelessWidget {
  const MessageTimestamp({
    super.key,
    required this.at,
    this.status,
    this.read = false,
    this.delivered = false,
  });

  /// [PreciseDateTime] to display in this [MessageTimestamp].
  final PreciseDateTime at;

  /// [SendingStatus] to display in this [MessageTimestamp], if any.
  final SendingStatus? status;

  /// Indicator whether this [MessageTimestamp] is considered to be read,
  /// meaning it should display an appropriate icon.
  final bool read;

  /// Indicator whether this [MessageTimestamp] is considered to be delivered,
  /// meaning it should display an appropriate icon.
  final bool delivered;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final bool isSent = status == SendingStatus.sent;
    final bool isDelivered = isSent && delivered;
    final bool isRead = isSent && read;
    final bool isError = status == SendingStatus.error;
    final bool isSending = status == SendingStatus.sending;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status != null) ...[
          if (isSent || isDelivered || isRead || isSending || isError)
            Icon(
              (isRead || isDelivered)
                  ? Icons.done_all
                  : isSending
                      ? Icons.access_alarm
                      : isError
                          ? Icons.error_outline
                          : Icons.done,
              color: isRead
                  ? Theme.of(context).colorScheme.secondary
                  : isError
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
              size: 12,
            ),
          const SizedBox(width: 3),
        ],
        SelectionContainer.disabled(
          child: Text(
            DateFormat.Hm().format(at.val.toLocal()),
            style: style.systemMessageStyle.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
