import 'package:get/get.dart';

import '../../../routes.dart';

class StyleController extends GetxController {
  StyleController();

  ///
  final RxBool isDarkMode = false.obs;

  ///
  final selectedTab = StyleTab.colors.obs;

  ///
  void toggleTab(StyleTab tab) {
    selectedTab.value = tab;
  }

  ///
  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
  }
}
