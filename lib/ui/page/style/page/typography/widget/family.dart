import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '/config.dart';
import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Column] describing visually a font family of the provided [weight].
class FontFamily extends StatelessWidget {
  const FontFamily({
    super.key,
    required this.weight,
    required this.name,
    required this.asset,
  });

  /// [FontWeight] of the family to describe.
  final FontWeight weight;

  /// Name of this [FontFamily].
  final String name;

  /// Asset name of this [FontFamily].
  final String asset;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'G, The quick brown fox jumps over the lazy dog${', the quick brown fox jumps over the lazy dog' * 10}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.fonts.largest.regular.onBackground
              .copyWith(fontWeight: weight),
        ),
        const SizedBox(height: 4),
        WidgetButton(
          onPressed: () async {
            String? to;

            try {
              to = await FilePicker.platform.saveFile(
                fileName: asset,
                type: FileType.image,
                lockParentWindow: true,
              );
            } on UnimplementedError catch (_) {
              // No-op.
            }

            await PlatformUtils.download(
              '${Config.origin}/assets/assets/fonts/$asset',
              asset,
              null,
              path: to,
            );

            MessagePopup.success('$asset downloaded');
          },
          child: Text(name, style: style.fonts.smaller.regular.primary),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
