import 'package:flutter/material.dart';
import 'package:gif/gif.dart';

class AvatarImage extends StatefulWidget {
  const AvatarImage({Key? key}) : super(key: key);

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage>
    with TickerProviderStateMixin {
  late GifController _controller;
  /// TODO add parser for animated or not
  /// TODO add public methods for control animation

  @override
  void initState() {
    super.initState();
    _controller = GifController(vsync: this);
  }

  void onEntered(bool isHovered){
    isHovered?_controller.repeat() : _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        _controller.forward(from: 0);
      },
      child: MouseRegion(
        onEnter: (_)=> onEntered(true),
        onExit: (_)=> onEntered(false),
        child: Gif(
          image: const NetworkImage(
              'https://gapopa.net/files/47/17/35/83/bb/de/a3/f1/51/2d/d6/2d/6a/8f/31/ac/orig.gif'),
          controller: _controller,
          autostart: Autostart.once,
        ),
      ),
    );
  }
}
