import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../domain/model/native_file.dart';
import '../../../../../themes.dart';
import '../../../../widget/svg/svgs.dart';
import '../../../call/widget/round_button.dart';

class AvatarCropper extends StatefulWidget {
  const AvatarCropper({super.key, required this.file});

  final NativeFile file;

  @override
  State<AvatarCropper> createState() => _AvatarCropperState();
}

class _AvatarCropperState extends State<AvatarCropper> {
  final fileContent = Rx<Uint8List?>(null);
  final hovered = Rx(false);

  @override
  void initState() {
    super.initState();
    run(() async {
      await widget.file.readFile();
      fileContent.value = await widget.file.readFile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final style = Theme.of(context).style;

    return Obx(() {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Column(children: [
          const SizedBox(height: 30),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 100,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 60,
                height: 60,
                child: MouseRegion(
                  onEnter: (_) => hovered.value = true,
                  onExit: (_) => hovered.value = false,
                  child: ClipRRect(
                    child: RoundFloatingButton(
                      color: hovered()
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      onPressed: navigator.pop,
                      icon: SvgIcons.arrowLeft,
                      offset: const Offset(-1, 0),
                    ),
                  ),
                ),
              ),
            ),
            const Text(
              'Crop your image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              softWrap: false,
            ),
            Container(
              width: 100,
              alignment: Alignment.centerRight - const Alignment(0.2, 0),
              child: Text(
                'Save',
                style: TextStyle(color: style.colors.primary, fontSize: 20),
              ),
            ),
          ]),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 500,
                height: 500,
                child: Stack(children: [
                  if (fileContent() != null)
                    Center(
                      child: Image.memory(fileContent()!, fit: BoxFit.contain),
                    ),
                ]),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

T run<T>(T Function() fn) => fn();
