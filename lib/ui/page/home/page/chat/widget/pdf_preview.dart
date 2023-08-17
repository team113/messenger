import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/util/log.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pdfx/src/renderer/interfaces/platform.dart';

class PdfPreview extends StatefulWidget {
  const PdfPreview(this.bytes, {super.key});

  final Uint8List? bytes;

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  final GlobalKey _pdfKey = GlobalKey();

  PdfPage? _page;
  PdfPageImage? _image;
  RxStatus _status = RxStatus.loading();

  @override
  void initState() {
    if (!PlatformUtils.isLinux) {
      _init();
    } else {
      // TODO: Display icon when empty.
      _status = RxStatus.empty();
    }

    super.initState();
  }

  @override
  void didUpdateWidget(PdfPreview oldWidget) {
    if (widget.bytes != oldWidget.bytes) {
      if (!PlatformUtils.isLinux) {
        _init();
      } else {
        // TODO: Display icon when empty.
        _status = RxStatus.empty();
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  Future<void> _init() async {
    if (widget.bytes == null) {
      _status = RxStatus.loading();
      return;
    }

    try {
      if (mounted) {
        setState(() => _status = RxStatus.loading());
      }

      var document = await PdfxPlatform.instance.openData(widget.bytes!);

      _page = await document.getPage(1);

      _image = await _page!.render(
        height: 100,
        width: 100,
      );

      if (mounted) {
        setState(() => _status = RxStatus.success());
      }
    } catch (e) {
      Log.error(e);
      if (mounted) {
        setState(() => _status = RxStatus.error(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;

    if (_status.isSuccess) {
      content = SizedBox(
        height: 100,
        width: 100,
        child: Image(
          key: const Key('Image'),
          fit: BoxFit.cover,
          image: PdfPageImageProvider(Future.value(_image), 0, ''),
        ),
      );
    } else if (_status.isError) {
      content = SizedBox(
        key: const Key('Error'),
        width: 100,
        height: 100,
        child: Center(
          child: Text(
            '${_status.errorMessage}',
            style: const TextStyle(color: Colors.black),
          ),
        ),
      );
    } else {
      content = const SizedBox(
        key: Key('Loading'),
        width: 100,
        height: 100,
        child: Center(child: CustomProgressIndicator()),
      );
    }

    return content;
  }
}
