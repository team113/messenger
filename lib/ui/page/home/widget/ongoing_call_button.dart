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

import '/domain/model/chat.dart';
import '/themes.dart';
import '/ui/page/home/tab/chats/widget/periodic_builder.dart';

/// [Widget] which returns a rounded rectangular button representing an
/// [OngoingCall] associated action.
class OngoingCallButton extends StatelessWidget {
  const OngoingCallButton({
    super.key,
    required this.active,
    required this.duration,
    required this.builder,
    this.onDrop,
    this.onJoin,
  });

  /// Indicator whether this device of the currently authenticated [MyUser]
  /// takes part in the [Chat.ongoingCall], if any.
  final bool active;

  /// Difference between the current time and the start time of an
  /// [OngoingCall].
  final Duration duration;

  /// Callback, called when a drop [Chat.ongoingCall] in this [rxChat]
  /// action is triggered.
  final void Function()? onDrop;

  /// Callback, called when a join [Chat.ongoingCall] in this [rxChat]
  /// action is triggered.
  final void Function()? onJoin;

  final Widget Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return DecoratedBox(
      key: active ? const Key('JoinCallButton') : const Key('DropCallButton'),
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: style.colors.onPrimary, width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        elevation: 0,
        type: MaterialType.button,
        borderRadius: BorderRadius.circular(20),
        color: active ? style.colors.dangerColor : style.colors.primary,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: active ? onDrop : onJoin,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: Row(
              children: [
                Icon(
                  active ? Icons.call_end : Icons.call,
                  size: 16,
                  color: style.colors.onPrimary,
                ),
                const SizedBox(width: 6),
                PeriodicBuilder(
                  period: const Duration(seconds: 1),
                  builder: builder,
                  // builder: (_) {
                  //   final String text = duration.hhMmSs();

                  //   return Text(
                  //     text,
                  //     style: Theme.of(context)
                  //         .textTheme
                  //         .titleSmall
                  //         ?.copyWith(color: style.colors.onPrimary),
                  //   ).fixedDigits();
                  // },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
