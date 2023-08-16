import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/animated_logo.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
    if (widget.text == r'${gapopa}') {
      final style = Theme.of(context).style;

      const double multiplier = 0.8;

      return Column(
        children: [
          Text(
            'Messenger',
            style: style.fonts.titleLargeSecondary
                .copyWith(fontSize: 27 * multiplier),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2 * multiplier),
          Text(
            'by Gapopa',
            style: style.fonts.titleLargeSecondary
                .copyWith(fontSize: 21 * multiplier),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 25 * multiplier),
          const AnimatedLogo(
            height: (190 * 0.75 + 25) * multiplier,
            svgAsset: 'assets/images/logo/head0000.svg',
          ),
          const SizedBox(height: 16 * multiplier),
          WidgetButton(
            onPressed: () async {
              await launchUrlString('https://gapopa.net');
            },
            child: Text(
              'gapopa.net',
              style: style.fonts.labelLargePrimary,
            ),
          ),
          // const VacancyDescription('gapopa.net'),
        ],
      );
    }

    if (span == null) {
      return const SizedBox();
    }

    return Text.rich(span!);
  }
}
