import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:messenger/util/web/web_utils.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

class UploadableFile extends StatefulWidget {
  const UploadableFile({
    super.key,
    required this.label,
    this.onChanged,
    this.file,
  });

  final void Function(PlatformFile?)? onChanged;
  final PlatformFile? file;
  final String label;

  @override
  State<UploadableFile> createState() => _UploadableFileState();
}

class _UploadableFileState extends State<UploadableFile> {
  /// Indicator whether this [DataAttachment] is hovered.
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    if (widget.file == null) {
      return FieldButton(
        text: 'Не выбрано',
        headline: Text(widget.label),
        onPressed: _pickFile,
        style: style.fonts.normal.regular.primary,
      );
    } else {
      final Widget asFile = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: WidgetButton(
          onPressed: () async {
            if (!PlatformUtils.isWeb) {
              final String? to = await FilePicker.platform.saveFile(
                fileName: widget.file?.name,
                lockParentWindow: true,
              );

              if (to != null) {
                await File(to).writeAsBytes(widget.file!.bytes!);
              }
            } else {
              await WebUtils.writeFile(widget.file!.name, widget.file!.bytes!);
            }
          },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                key: const Key('Download'),
                height: 29,
                width: 29,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _hovered ? style.colors.backgroundAuxiliaryLighter : null,
                  border: Border.all(
                    width: 2,
                    color: style.colors.primary,
                  ),
                ),
                child: const KeyedSubtree(
                  key: Key('Sent'),
                  child: Center(
                    child: SvgImage.asset(
                      'assets/icons/arrow_down.svg',
                      width: 9.12,
                      height: 10.39,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.basenameWithoutExtension(widget.file!.name),
                            style: style.fonts.medium.regular.onBackground,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          p.extension(widget.file!.name),
                          style: style.fonts.medium.regular.onBackground,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'label_kb'.l10nfmt({
                            'amount': widget.file?.size == null
                                ? 'dot'.l10n * 3
                                : widget.file!.size ~/ 1024
                          }),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style.fonts.small.regular.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final BorderRadius borderRadius = BorderRadius.circular(15 * 0.7);
      final border = OutlineInputBorder(
        borderSide: BorderSide(width: 0.5, color: style.colors.secondary),
        borderRadius: borderRadius,
      );

      return Column(
        children: [
          InputDecorator(
            decoration: InputDecoration(
              border: border,
              errorBorder: border,
              enabledBorder: border,
              focusedBorder: border,
              disabledBorder: border,
              focusedErrorBorder: border,
              label: Text(widget.label),
            ),
            child: asFile,
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Заменить',
                  style: style.fonts.small.regular.primary,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async => await _pickFile(),
                ),
                TextSpan(
                  text: ' или ',
                  style: style.fonts.small.regular.secondary,
                ),
                TextSpan(
                  text: 'удалить',
                  style: style.fonts.small.regular.primary,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => widget.onChanged?.call(null),
                ),
              ],
            ),
          ),
        ],
      );

      // return FieldButton(
      //   text: 'Заменить',
      //   headline: Text(label),
      //   onPressed: () {},
      //   style: style.fonts.normal.regular.primary,
      // );
    }
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      lockParentWindow: true,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      widget.onChanged?.call(result.files.firstOrNull);
    }
  }
}
