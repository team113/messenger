import 'package:flutter/material.dart';
import 'package:messenger/routes.dart';

class BalanceProviderView extends StatelessWidget {
  const BalanceProviderView(this.provider, {super.key});

  final BalanceProvider provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          provider.toString(),
        ),
      ),
    );
  }
}
