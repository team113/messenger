import 'package:flutter/widgets.dart';
import 'package:messenger/domain/service/disposable_service.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/pubspec.g.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpgradeWorker extends DisposableService {
  final Appcast _appcast = Appcast();

  @override
  void onInit() {
    if (!PlatformUtils.isWeb && PlatformUtils.isMacOS) {
      _fetch();
    }

    super.onInit();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
  }

  Future<void> _fetch() async {
    await _appcast.parseAppcastItemsFromUri(
      'https://raw.githubusercontent.com/team113/messenger/new-design-preview/appcast/macos.xml',
    );

    final bestItem = _appcast.bestItem();

    // if (bestItem != null && bestItem.title != Pubspec.version) {
    //   final result = await MessagePopup.alert(
    //     'Upgrade available',
    //     description: [
    //       TextSpan(
    //         text:
    //             '${bestItem.title} is available. \n\n${bestItem.itemDescription}',
    //       ),
    //     ],
    //     proceed: 'btn_download'.l10n,
    //   );

    //   if (result == true) {
    //     await launchUrlString(
    //       'https://gapopa.org/artifacts/messenger-macos.zip',
    //     );
    //   }
    // }
  }
}
