import 'package:flutter/material.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/block.dart';

class NotesBlock extends StatelessWidget {
  const NotesBlock({super.key, this.info = false});
  const NotesBlock.info({super.key}) : info = true;

  final bool info;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Block(
      crossAxisAlignment: CrossAxisAlignment.start,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      title: info ? 'label_info'.l10n : 'label_chat_monolog'.l10n,
      titleStyle: style.fonts.large.regular.onBackground,
      children: [
        Text(
          'label_chat_monolog_description'.l10n,
          style: style.fonts.small.regular.secondary,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
