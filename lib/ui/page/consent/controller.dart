import 'package:get/get.dart';

import '/provider/hive/consent.dart';

/// Controller of a [ConsentView].
class ConsentController extends GetxController {
  ConsentController(this._consentProvider, this.callback);

  /// Status of the [proceed] completing the [callback].
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  /// Function to call after acquiring the user's consent.
  final Future<void> Function(bool) callback;

  /// [ConsentHiveProvider] providing and storing the consent itself.
  final ConsentHiveProvider _consentProvider;

  /// Stores the [consent] and invokes the [callback].
  Future<void> proceed(bool consent) async {
    status.value = RxStatus.loading();

    await _consentProvider.set(consent);
    await callback(consent);

    status.value = RxStatus.success();
  }
}
