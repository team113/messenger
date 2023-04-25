import 'package:flutter/material.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

class WalletWidget extends StatelessWidget {
  const WalletWidget({
    super.key,
    this.balance = 0,
    this.visible = true,
  });

  final double balance;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final String icon;
    final Widget overlay;

    final double width;
    final double height;

    if (visible) {
      if (balance > 0) {
        icon = 'wallet3';
        width = 36;
        height = 31;
      } else {
        icon = 'wallet4';
        width = 35;
        height = 26;
      }

      overlay = Transform.translate(
        offset: Offset(0, balance > 0 ? 2 : 0),
        child: Text(
          _balance(balance),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
          textScaleFactor: 1,
        ),
      );
    } else {
      if (balance > 0) {
        icon = 'wallet2';
        width = 36;
        height = 31;
      } else {
        icon = 'wallet1';
        width = 36;
        height = 26;
      }

      overlay = const SizedBox();
    }

    return Transform.translate(
      offset: Offset(0, balance > 0 ? -2 : 0),
      child: Stack(
        children: [
          SvgLoader.asset('assets/icons/$icon.svg',
              width: width, height: height),
          Positioned.fill(child: Center(child: overlay)),
        ],
      ),
    );
  }

  String _balance(double balance) {
    if (balance < 1000) {
      return balance.toInt().toString();
    } else if (balance < 1000000) {
      return '${balance ~/ 1000}k';
    } else {
      return '${balance ~/ 1000000}m';
    }
  }
}
