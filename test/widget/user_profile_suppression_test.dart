// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:medea_jason/medea_jason.dart';

import 'package:messenger/domain/model/media_settings.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/switch_field.dart';
import 'package:messenger/ui/widget/line_divider.dart';
import 'package:messenger/util/platform_utils.dart';

void main() {
  testWidgets('Noise suppression slider appears and stores values on Desktop', (
    WidgetTester tester,
  ) async {
    PlatformUtils = _PlatformUtilsDesktop();
    final controller = _NoiseController();

    await tester.pumpWidget(
      MaterialApp(
        theme: Themes.light(),
        home: Scaffold(body: _NoiseSuppressionView(controller)),
      ),
    );
    await tester.pumpAndSettle();

    // Slider does not appear if not enabled.
    expect(find.byType(FlutterSlider), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Slider must appear.
    expect(find.byType(FlutterSlider), findsOneWidget);

    // Find and tap slider.
    final slider = tester.widget<FlutterSlider>(find.byType(FlutterSlider));
    slider.onDragCompleted?.call(0, NoiseSuppressionLevel.high, null);
    await tester.pumpAndSettle();

    // Expect side effects
    expect(controller.media.value.noiseSuppressionEnabled, isTrue);
    expect(
      controller.media.value.noiseSuppressionLevel,
      NoiseSuppressionLevel.high,
    );
  });
}

/// Simulate Non-desktop Application.
class _PlatformUtilsDesktop extends PlatformUtilsImpl {
  @override
  bool get isDesktop => true;
  @override
  bool get isWeb => false;

  _PlatformUtilsDesktop();
}

/// Simulate [ProfileController].
class _NoiseController extends GetxController {
  final media = Rx(MediaSettings(noiseSuppressionEnabled: false));

  void setNoiseSuppressionEnabled(bool enabled) {
    media.update((m) {
      m ??= MediaSettings();
      m.noiseSuppressionEnabled = enabled;
    });
  }

  void setNoiseSuppressionLevelValue(NoiseSuppressionLevel level) {
    media.update((m) {
      m ??= MediaSettings();
      m.noiseSuppressionLevel = level;
    });
  }
}

class _NoiseSuppressionView extends StatelessWidget {
  const _NoiseSuppressionView(this.c);

  final _NoiseController c;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        if (PlatformUtils.isDesktop && !PlatformUtils.isWeb) ...[
          const SizedBox(height: 20),
          LineDivider('label_voice_processing'.l10n),
          const SizedBox(height: 16),
          Obx(() {
            // False by default
            final isEnabled = c.media.value.noiseSuppressionEnabled ?? false;

            // Moderate by default (if enabled)
            final level =
                c.media.value.noiseSuppressionLevel ??
                NoiseSuppressionLevel.moderate;

            // Values of NoiseSuppressionLevel
            final values = NoiseSuppressionLevel.values;

            // Percentage in slider
            final percentage =
                (100 * (1 / (values.length - 1)) * values.indexOf(level));

            return Column(
              children: [
                SwitchField(
                  text: 'label_noise_suppression'.l10n,
                  value: isEnabled,
                  onChanged: (enabled) {
                    c.setNoiseSuppressionEnabled(enabled);
                    if (enabled) {
                      // set saved value or default one.
                      c.setNoiseSuppressionLevelValue(level);
                    }
                  },
                ),
                if (isEnabled) ...[
                  SizedBox(
                    height: 70,
                    child: Transform.translate(
                      offset: Offset(0, 12),
                      child: FlutterSlider(
                        handlerHeight: 24,
                        handler: FlutterSliderHandler(child: const SizedBox()),
                        values: [percentage],
                        tooltip: FlutterSliderTooltip(disabled: true),
                        fixedValues: values.mapIndexed((i, e) {
                          return FlutterSliderFixedValue(
                            percent: ((i / (values.length - 1)) * 100).round(),
                            value: e,
                          );
                        }).toList(),
                        trackBar: FlutterSliderTrackBar(
                          inactiveTrackBar: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: style.colors.onBackgroundOpacity13,
                          ),
                          activeTrackBar: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: style.colors.primaryHighlight,
                          ),
                        ),
                        onDragCompleted: (i, lower, upper) {
                          if (lower is NoiseSuppressionLevel) {
                            c.setNoiseSuppressionLevelValue(lower);
                          }
                        },
                        hatchMark: FlutterSliderHatchMark(
                          labelsDistanceFromTrackBar: -48,
                          labels: [
                            FlutterSliderHatchMarkLabel(
                              percent: 0,
                              label: Text(
                                textAlign: TextAlign.center,
                                'label_low'.l10n,
                                style: style.fonts.smaller.regular.secondary,
                              ),
                            ),
                            FlutterSliderHatchMarkLabel(
                              percent: 33,
                              label: Text(
                                textAlign: TextAlign.center,
                                'label_medium'.l10n,
                                style: style.fonts.smaller.regular.secondary,
                              ),
                            ),
                            FlutterSliderHatchMarkLabel(
                              percent: 66,
                              label: Text(
                                textAlign: TextAlign.center,
                                'label_high'.l10n,
                                style: style.fonts.smaller.regular.secondary,
                              ),
                            ),
                            FlutterSliderHatchMarkLabel(
                              percent: 100,
                              label: Text(
                                textAlign: TextAlign.center,
                                'label_very_high'.l10n,
                                style: style.fonts.smaller.regular.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            );
          }),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }
}
