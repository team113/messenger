import 'package:flutter/material.dart';

class Dot extends StatelessWidget {
  const Dot({
    Key? key,
    this.selected,
  }) : super(key: key);

  final bool? selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected == true
            ? CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                radius: 11,
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD7D7D7),
                    width: 1,
                  ),
                ),
                width: 22,
                height: 22,
              ),
      ),
    );
  }
}
