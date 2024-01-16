import 'package:get/get.dart';

/// Extension adding ability to find non-strict dependencies from a
/// [GetInterface].
extension FindOrNullExtension on GetInterface {
  /// Returns the [S] dependency, if it [isRegistered].
  S? findOrNull<S>({String? tag}) {
    if (isRegistered<S>(tag: tag)) {
      return find<S>(tag: tag);
    }

    return null;
  }
}
