import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart' show CancelToken;
import 'package:get/get.dart';

import '/domain/model/cache_info.dart';
import '/domain/repository/cache.dart';
import '/domain/service/disposable_service.dart';

class FileService extends DisposableService {
  FileService(this._cacheRepository);

  /// [AbstractCacheRepository] maintaining the cache.
  final AbstractCacheRepository _cacheRepository;

  /// Returns the [CacheInfo].
  Rx<CacheInfo?> get cache => _cacheRepository.cacheInfo;

  /// Gets a file data from cache by the provided [checksum] or downloads by the
  /// provided [url].
  ///
  /// At least one of [url] or [checksum] arguments must be provided.
  FutureOr<Uint8List?> get({
    String? url,
    String? checksum,
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    Future<void> Function()? onForbidden,
  }) =>
      _cacheRepository.get(
        url: url,
        checksum: checksum,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        onForbidden: onForbidden,
      );

  /// Saves the provided [data] to the cache.
  Future<void> save(Uint8List data, [String? checksum]) =>
      _cacheRepository.save(data, checksum);

  /// Returns indicator whether data with the provided [checksum] exists in the
  /// cache.
  bool exists(String checksum) => _cacheRepository.exists(checksum);

  /// Clears the cache.
  Future<void> clear() => _cacheRepository.clear();
}
