// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/ui/page/call/widget/conditional_backdrop.dart';

/// Circular progress indicator, which spins to indicate that the application is
/// busy.
class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({
    super.key,
    this.color,
    this.backgroundColor,
    this.valueColor,
    this.strokeWidth = 2.0,
    this.value,
    this.padding = const EdgeInsets.all(6),
    this.size = 32,
    this.blur = true,
  });

  /// If non-null, the value of this progress indicator.
  ///
  /// A value of 0.0 means no progress and 1.0 means that progress is complete.
  /// The value will be clamped to be in the range 0.0-1.0.
  ///
  /// If null, this progress indicator is indeterminate, which means the
  /// indicator displays a predetermined animation that does not indicate how
  /// much actual progress is being made.
  final double? value;

  /// Progress indicator's background color.
  final Color? backgroundColor;

  /// Progress indicator's color.
  final Color? color;

  /// Progress indicator's color as an animated value.
  final Animation<Color?>? valueColor;

  /// Width of the line used to draw the circle.
  final double strokeWidth;

  /// Padding to apply to the [CustomCircularProgressIndicator] if the
  /// background is blurred.
  final EdgeInsets padding;

  /// Size of this [CustomProgressIndicator].
  final double size;

  /// Indicator whether the background is blurred.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    return ConditionalBackdropFilter(
      condition: blur,
      borderRadius: BorderRadius.circular(60),
      child: Container(
        constraints: BoxConstraints(maxWidth: size, maxHeight: size),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        padding: blur ? padding : EdgeInsets.zero,
        child: CustomCircularProgressIndicator(
          value: value,
          color: color ?? const Color.fromARGB(255, 175, 175, 175),
          backgroundColor:
              backgroundColor ?? const Color.fromARGB(255, 213, 213, 213),
          valueColor: valueColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// Minimum circular progress indicator size.
const double _kMinCircularProgressIndicatorSize = 36.0;

/// Value used to get the [SawTooth] animation of a indeterminate progress
/// indicator.
const int _kIndeterminateCircularDuration = 1333 * 100;

/// [CustomPainter] drawing a circular progress indicator.
class _CircularProgressIndicatorPainter extends CustomPainter {
  _CircularProgressIndicatorPainter({
    this.backgroundColor,
    required this.valueColor,
    required this.value,
    required this.headValue,
    required this.tailValue,
    required this.offsetValue,
    required this.rotationValue,
    required this.strokeWidth,
  })  : arcStart = value != null
            ? _startAngle
            : _startAngle +
                tailValue * 3 / 2 * math.pi +
                rotationValue * math.pi * 2.0 +
                offsetValue * 0.5 * math.pi,
        arcSweep = value != null
            ? clampDouble(value, 0.0, 1.0) * _sweep
            : math.max(
                headValue * 3 / 2 * math.pi - tailValue * 3 / 2 * math.pi,
                _epsilon);

  /// Background circle's color.
  final Color? backgroundColor;

  /// Progress arc's color as an animated value.
  final Color valueColor;

  /// Progress value.
  final double? value;

  /// Value of the first end of the progress arc.
  final double headValue;

  /// Value of the second end of the progress arc.
  final double tailValue;

  /// Offset value of the progress arc.
  final double offsetValue;

  /// Rotation value of the progress arc.
  final double rotationValue;

  /// Width of the line used to draw the progress arc and background circle.
  final double strokeWidth;

  /// Start angle for [Canvas.drawArc] to draw the progress arc.
  final double arcStart;

  /// Sweep angle for [Canvas.drawArc] to draw the progress arc.
  final double arcSweep;

  /// Value denoting a full circle.
  static const double _twoPi = math.pi * 2.0;

  /// Value used to draw the background circle.
  ///
  /// Canvas.drawArc(r, 0, 2*PI) doesn't draw anything, so just get close.
  static const double _epsilon = .001;

  /// Sweep angle for [Canvas.drawArc] to draw the background circle.
  static const double _sweep = _twoPi - _epsilon;

  /// Initial value of the first end of progress arc. Is the top point of the
  /// circle.
  static const double _startAngle = -math.pi / 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    if (backgroundColor != null) {
      final Paint backgroundPaint = Paint()
        ..color = backgroundColor!
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawArc(Offset.zero & size, 0, _sweep, false, backgroundPaint);
    }

    if (value == null) {
      // Indeterminate
      paint.strokeCap = StrokeCap.square;
    }

    canvas.drawArc(Offset.zero & size, arcStart, arcSweep, false, paint);
  }

  @override
  bool shouldRepaint(_CircularProgressIndicatorPainter oldPainter) {
    return oldPainter.backgroundColor != backgroundColor ||
        oldPainter.valueColor != valueColor ||
        oldPainter.value != value ||
        oldPainter.headValue != headValue ||
        oldPainter.tailValue != tailValue ||
        oldPainter.offsetValue != offsetValue ||
        oldPainter.rotationValue != rotationValue ||
        oldPainter.strokeWidth != strokeWidth;
  }
}

/// A Material Design circular progress indicator, which spins to indicate that
/// the application is busy.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=O-rhXZLtpv0}
///
/// A widget that shows progress along a circle. There are two kinds of circular
/// progress indicators:
///
///  * _Determinate_. Determinate progress indicators have a specific value at
///    each point in time, and the value should increase monotonically from 0.0
///    to 1.0, at which time the indicator is complete. To create a determinate
///    progress indicator, use a non-null [value] between 0.0 and 1.0.
///  * _Indeterminate_. Indeterminate progress indicators do not have a specific
///    value at each point in time and instead indicate that progress is being
///    made without indicating how much progress remains. To create an
///    indeterminate progress indicator, use a null [value].
///
/// The indicator arc is displayed with [valueColor], an animated value. To
/// specify a constant color use: `AlwaysStoppedAnimation<Color>(color)`.
///
/// {@tool dartpad}
/// This example shows a [CircularProgressIndicator] with a changing value.
///
/// ** See code in examples/api/lib/material/progress_indicator/circular_progress_indicator.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample shows the creation of a [CircularProgressIndicator] with a changing value.
/// When toggling the switch, [CircularProgressIndicator] uses a determinate value.
/// As described in: https://m3.material.io/components/progress-indicators/overview
///
/// ** See code in examples/api/lib/material/progress_indicator/circular_progress_indicator.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [LinearProgressIndicator], which displays progress along a line.
///  * [RefreshIndicator], which automatically displays a [CircularProgressIndicator]
///    when the underlying vertical scrollable is overscrolled.
///  * <https://material.io/design/components/progress-indicators.html#circular-progress-indicators>
class CustomCircularProgressIndicator extends ProgressIndicator {
  /// Creates a circular progress indicator.
  ///
  /// {@macro flutter.material.ProgressIndicator.ProgressIndicator}
  const CustomCircularProgressIndicator({
    super.key,
    super.value,
    super.backgroundColor,
    super.color,
    super.valueColor,
    this.strokeWidth = 4.0,
    super.semanticsLabel,
    super.semanticsValue,
  });

  /// {@template flutter.material.CircularProgressIndicator.trackColor}
  /// Color of the circular track being filled by the circular indicator.
  ///
  /// If [CircularProgressIndicator.backgroundColor] is null then the
  /// ambient [ProgressIndicatorThemeData.circularTrackColor] will be used.
  /// If that is null, then the track will not be painted.
  /// {@endtemplate}
  @override
  Color? get backgroundColor => super.backgroundColor;

  /// The width of the line used to draw the circle.
  final double strokeWidth;

  @override
  State<CustomCircularProgressIndicator> createState() =>
      _CircularProgressIndicatorState();
}

/// State of a [CustomCircularProgressIndicator] maintaining drawing of the
/// progress indicator.
class _CircularProgressIndicatorState
    extends State<CustomCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  /// Number of cycles when the progress arc from the minimum size reaches the
  /// maximum and decreases to the minimum for the period
  /// [_controller.duration].
  static const int _pathCount = _kIndeterminateCircularDuration ~/ 1333;

  /// Number of rotations the progress arc for the period
  /// [_controller.duration].
  static const int _rotationCount = _kIndeterminateCircularDuration ~/ 2222;

  /// [Animatable] producing value of the first end of the progress arc.
  static final Animatable<double> _strokeHeadTween = CurveTween(
    curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(curve: const SawTooth(_pathCount)));

  /// [Animatable] producing value of the second end of the progress arc.
  static final Animatable<double> _strokeTailTween = CurveTween(
    curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(curve: const SawTooth(_pathCount)));

  /// [Animatable] producing of the progress arc offset value.
  static final Animatable<double> _offsetTween =
      CurveTween(curve: const SawTooth(_pathCount));

  /// [Animatable] producing of the progress arc rotation value.
  static final Animatable<double> _rotationTween =
      CurveTween(curve: const SawTooth(_rotationCount));

  /// [AnimationController] controlling the progress indicator animation.
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 200),
      vsync: this,
    );
    if (widget.value == null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CustomCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns the color of the progress indicator.
  Color _getValueColor(BuildContext context, {Color? defaultColor}) {
    return widget.valueColor?.value ??
        widget.color ??
        ProgressIndicatorTheme.of(context).color ??
        defaultColor ??
        Theme.of(context).colorScheme.primary;
  }

  /// Draws a determinate progress indicator.
  Widget _buildMaterialIndicator(BuildContext context, double headValue,
      double tailValue, double offsetValue, double rotationValue) {
    final ProgressIndicatorThemeData defaults = Theme.of(context).useMaterial3
        ? _CircularProgressIndicatorDefaultsM3(context)
        : _CircularProgressIndicatorDefaultsM2(context);
    final Color? trackColor = widget.backgroundColor ??
        ProgressIndicatorTheme.of(context).circularTrackColor;

    return Container(
      constraints: const BoxConstraints(
        minWidth: _kMinCircularProgressIndicatorSize,
        minHeight: _kMinCircularProgressIndicatorSize,
      ),
      child: CustomPaint(
        painter: _CircularProgressIndicatorPainter(
          backgroundColor: trackColor,
          valueColor: _getValueColor(context, defaultColor: defaults.color),
          value: widget.value, // may be null
          headValue:
              headValue, // remaining arguments are ignored if widget.value is not null
          tailValue: tailValue,
          offsetValue: offsetValue,
          rotationValue: rotationValue,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }

  /// Draws a indeterminate progress indicator.
  Widget _buildAnimation() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return _buildMaterialIndicator(
          context,
          _strokeHeadTween.evaluate(_controller),
          _strokeTailTween.evaluate(_controller),
          _offsetTween.evaluate(_controller),
          _rotationTween.evaluate(_controller),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != null) {
      return _buildMaterialIndicator(context, 0.0, 0.0, 0, 0.0);
    }
    return _buildAnimation();
  }
}

/// Hand coded defaults based on Material Design 2.
class _CircularProgressIndicatorDefaultsM2 extends ProgressIndicatorThemeData {
  _CircularProgressIndicatorDefaultsM2(this.context);

  /// [BuildContext] used to get the [_colors].
  final BuildContext context;

  /// Default [ColorScheme].
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color get color => _colors.primary;
}

/// Hand coded defaults based on Material Design 3.
class _CircularProgressIndicatorDefaultsM3 extends ProgressIndicatorThemeData {
  _CircularProgressIndicatorDefaultsM3(this.context);

  /// [BuildContext] used to get the [_colors].
  final BuildContext context;

  /// Default [ColorScheme].
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color get color => _colors.primary;
}
