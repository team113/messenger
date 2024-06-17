import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../widget/svg/svg.dart';
import '/domain/model/attachment.dart';
import '/domain/model/native_file.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

class UploadablePhoto extends StatefulWidget {
  const UploadablePhoto({super.key, this.onChanged, this.file});

  final void Function(NativeFile?)? onChanged;
  final NativeFile? file;

  @override
  State<UploadablePhoto> createState() => _UploadableFileState();
}

class _UploadableFileState extends State<UploadablePhoto> {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    if (widget.file == null) {
      // return PrimaryButton(
      //   title: 'Сделать фото',
      //   // headline: Text(widget.label),
      //   onPressed: _takePhoto,
      //   // style: style.fonts.normal.regular.primary,
      // );

      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: style.colors.onSecondary,
            ),
            height: 200,
            width: double.infinity,
            child: const Center(
              child: SvgImage.asset(
                'assets/icons/woman_passport.svg',
                height: 200,
                width: double.infinity,
              ),
            ),
          ),
          if (PlatformUtils.isMobile) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Сделать фото',
                    style: style.fonts.small.regular.primary,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async => await _takePhoto(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          WidgetButton(
            onPressed: () async {
              await GalleryPopup.show(
                context: context,
                gallery: const GalleryPopup(
                  children: [
                    // GalleryItem.image(link, name),
                  ],
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MediaAttachment(
                attachment: LocalAttachment(widget.file!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (PlatformUtils.isMobile) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Переделать фото',
                    style: style.fonts.small.regular.primary,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async => await _takePhoto(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
  }

  Future<void> _takePhoto() async {
    if (PlatformUtils.isDesktop) {
      await _pickFile();
      return;
    }

    final XFile? photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );

    if (photo != null) {
      final file = NativeFile.fromXFile(photo, await photo.length());
      await file.readFile();
      widget.onChanged?.call(file);
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
      widget.onChanged?.call(NativeFile.fromPlatformFile(result.files.first));
    }
  }
}
