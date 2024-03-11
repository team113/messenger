// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:js/js.dart';

@JS('renderPayPalButton')
external renderPayPalButton();

class PayPalButton extends StatefulWidget {
  const PayPalButton({super.key});

  @override
  State<PayPalButton> createState() => _PayPalButtonState();
}

class _PayPalButtonState extends State<PayPalButton> {
  /// Native [html.ImageElement] itself.
  html.DivElement? _element;

  /// Unique identifier for a platform view.
  late int _elementId;

  /// Type of platform view to pass to [HtmlElementView].
  late String _viewType;

  @override
  void initState() {
    _initImageElement();
    super.initState();
  }

  @override
  void dispose() {
    _element?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: SizedBox(
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : 300,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : 150,
          child: HtmlElementView(viewType: _viewType),
        ),
      );
    });
  }

  /// Registers the actual HTML element representing an image.
  void _initImageElement() {
    _elementId = platformViewsRegistry.getNextPlatformViewId();
    _viewType = '${_elementId}__payPalButtonViewType__';

    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        _element = html.DivElement()
          ..id = 'paypal-button-container'
          ..style.width = '300px';
        // ..style.height = '150px';

        SchedulerBinding.instance.addPostFrameCallback((_) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            renderPayPalButton();
          });
        });

        return _element!;
      },
    );
  }
}
