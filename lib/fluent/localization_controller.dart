import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:messenger/fluent/fluent_localization.dart';

class LocalizationController extends GetxController {
  LocalizationController(this.localizator);

  final FluentLocalization? localizator;
}
