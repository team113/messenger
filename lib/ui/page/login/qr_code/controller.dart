import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCodeController extends GetxController {
  QrCodeController({bool? scanning})
      : scanning = RxBool(scanning ?? !PlatformUtils.isMobile);

  final RxBool scanning;

  final RxList<Barcode> barcodes = RxList();

  final GlobalKey scannerKey = GlobalKey();

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();
}
