import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

class VacancyDescription extends StatefulWidget {
  const VacancyDescription(this.text, {super.key});

  final String text;

  @override
  State<VacancyDescription> createState() => _VacancyDescriptionState();
}

class _VacancyDescriptionState extends State<VacancyDescription> {
  final List<TapGestureRecognizer> _recognizers = [];
  TextSpan? span;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    for (var e in _recognizers) {
      e.dispose();
    }
    _recognizers.clear();

    setState(() => span = widget.text.parseLinks(_recognizers, context));
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    for (var e in _recognizers) {
      e.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (span == null) {
      return const SizedBox();
    }

    return Text.rich(span!);
  }
}
