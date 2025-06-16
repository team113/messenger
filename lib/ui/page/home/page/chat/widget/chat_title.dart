import 'package:flutter/material.dart';
import '/themes.dart';

class ChatTitle extends StatelessWidget {
  const ChatTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Text(title, style: style.fonts.larger.regular.onBackground),
      ),
    );
  }
}
