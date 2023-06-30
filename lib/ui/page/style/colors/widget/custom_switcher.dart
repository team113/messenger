import 'package:flutter/material.dart';

class CustomSwitcher extends StatefulWidget {
  final ValueChanged<bool> onChanged;

  const CustomSwitcher({super.key, required this.onChanged});

  @override
  State<CustomSwitcher> createState() => _CustomSwitcherState();
}

class _CustomSwitcherState extends State<CustomSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  late Animation<double> _animation;

  bool _value = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleValue() {
    setState(() {
      _value = !_value;
      widget.onChanged.call(_value);
      _value ? _animationController.forward() : _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleValue,
      child: Container(
        width: 50.0,
        height: 30.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: _value
              ? const Color(0xFF1F3C5D).withOpacity(0.7)
              : Colors.orange[300],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value * 20, 0),
                child: child,
              );
            },
            child: Row(
              children: [
                Container(
                  width: 22.0,
                  height: 22.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
