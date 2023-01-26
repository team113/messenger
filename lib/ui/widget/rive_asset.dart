import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveAsset extends StatefulWidget {
  const RiveAsset(this.asset, {super.key});

  final String asset;

  @override
  State<RiveAsset> createState() => _RiveAssetState();
}

class _RiveAssetState extends State<RiveAsset> {
  StateMachineController? _controller;
  SMIBool? _hover;
  SMITrigger? _click;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover?.change(true)),
      onExit: (_) => setState(() => _hover?.change(false)),
      child: Listener(
        onPointerDown: (_) => setState(() => _click?.fire()),
        child: RiveAnimation.asset(
          widget.asset,
          fit: BoxFit.contain,
          onInit: (a) {
            _controller = StateMachineController.fromArtboard(
              a,
              a.stateMachines.first.name,
            );
            a.addController(_controller!);

            _hover = _controller?.findInput<bool>('Hover') as SMIBool?;
            _click = _controller?.findInput<bool>('Click') as SMITrigger?;

            setState(() {});
          },
        ),
      ),
    );
  }
}
