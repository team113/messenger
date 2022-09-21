import '/domain/model/file.dart';

import '../schema.dart';

/// Extension adding models construction from a [FileMixin].
extension FileConversion on FileMixin {
  /// Constructs a new [StorageFile] from this [FileMixin].
  StorageFile toModel() => StorageFile(
        relativeRef: relativeRef,
        checksum: checksum,
        size: size,
      );
}
