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
    final Widget icon;
    final Widget overlay;

    if (visible) {
      if (balance > 0) {
        icon = const SvgIcon(SvgIcons.wallet);

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
        icon = const SvgIcon(SvgIcons.walletClosed);
        overlay = const SizedBox();
      }
    } else {
      if (balance > 0) {
        icon = const SvgIcon(SvgIcons.walletOpened);
      } else {
        icon = const SvgIcon(SvgIcons.walletClosed);
      }

      overlay = const SizedBox();
    }

    return Transform.translate(
      offset: Offset(0, -1 + balance > 0 ? -2 : 0),
      child: Stack(
        children: [
          icon,
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
