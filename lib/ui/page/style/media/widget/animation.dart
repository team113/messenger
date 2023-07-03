import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rive/rive.dart';

import '../../../../../config.dart';
import '../../../auth/widget/animated_logo.dart';
import '../../controller.dart';
import '/themes.dart';

class AnimationStyleWidget extends StatelessWidget {
  const AnimationStyleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, _) = Theme.of(context).styles;

    return GetBuilder(
        init: StyleController(),
        builder: (StyleController c) {
          return Row(
            children: [
              Tooltip(
                message: 'Full-length animated Logo',
                child: Container(
                  height: 300,
                  width: 200,
                  decoration: BoxDecoration(
                    color: style.colors.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Obx(
                    () => Padding(
                      padding: const EdgeInsets.all(15),
                      child: AnimatedLogo(
                        key: const ValueKey('Logo'),
                        svgAsset:
                            'assets/images/logo/head000${c.logoFrame.value}.svg',
                        onInit: Config.disableInfiniteAnimations
                            ? null
                            : (a) => _setBlink(c, a),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }

  /// Sets the [StyleController.blink] from the provided [Artboard] and invokes
  /// a [StyleController.animate] to animate it.
  Future<void> _setBlink(StyleController c, Artboard a) async {
    final StateMachineController machine =
        StateMachineController(a.stateMachines.first);
    a.addController(machine);

    c.blink = machine.findInput<bool>('blink') as SMITrigger?;

    await Future.delayed(const Duration(milliseconds: 500), c.animate);
  }
}
