import 'package:flutter/material.dart';
import 'package:messenger/fluent/fluent_localization.dart';

extension Translate on String {
  String t(BuildContext? context, {Map<String, dynamic> args = const {}}) {
    return context == null
        ? this
        : FluentLocalization.of(context)!.getTranslatedValue(this, args: args);
  }
}
