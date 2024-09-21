import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../domain/model/native_file.dart';

class AvatarCropper extends StatefulWidget {
  const AvatarCropper({super.key, required this.file});

  final NativeFile file;

  @override
  State<AvatarCropper> createState() => _AvatarCropperState();
}

class _AvatarCropperState extends State<AvatarCropper> {
  final fileContent = Rx<Uint8List?>(null);

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
    return Obx(() {
      return Container(
        color: Colors.black,
        child: Stack(children: [
          Stack(children: [
            if (fileContent() != null) Image.memory(fileContent()!),
          ]),
          Align(
            alignment: Alignment.topLeft,
            child: Listener(
              onPointerDown: (_) {
                final navigator = Navigator.of(context, rootNavigator: true);
                navigator.pop();
              },
              child: const Text(
                'close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

T run<T>(T Function() fn) => fn();
