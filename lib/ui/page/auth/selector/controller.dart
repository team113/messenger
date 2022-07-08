import 'package:get/get.dart';
import 'package:messenger/l10n/_l10n.dart';

class SelectorController extends GetxController {
  SelectorController();

  /// Index number of selected language.
  late final RxInt selectedLanguage;

  /// Prevents instant language change after the user has set
  ///  [selectedLanguage].
  late final Worker _languageDebounce;

  @override
  void onInit() {
    selectedLanguage = RxInt(L10n.languages.keys.toList().indexOf(L10n.chosen));
    _languageDebounce = debounce(
      selectedLanguage,
      (int i) {
        L10n.chosen = L10n.languages.keys.elementAt(i);
        Get.updateLocale(L10n.locales[L10n.chosen]!);
      },
      time: 500.milliseconds,
    );

    super.onInit();
  }

  @override
  void onClose() {
    _languageDebounce.dispose();
    super.onClose();
  }
}
