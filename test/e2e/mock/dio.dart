import 'package:dio/dio.dart';

class MockDio extends Dio {
  factory MockDio() => MockDio();

  @override
  void clear() {
    // TODO: implement clear
  }

  @override
  void close({bool force = false}) {
    // TODO: implement close
  }

  @override
  Future<Response<T>> delete<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> deleteUri<T>(Uri uri,
      {data, Options? options, CancelToken? cancelToken}) {
    // TODO: implement deleteUri
    throw UnimplementedError();
  }

  @override
  Future<Response> download(String urlPath, savePath,
      {ProgressCallback? onReceiveProgress,
      Map<String, dynamic>? queryParameters,
      CancelToken? cancelToken,
      bool deleteOnError = true,
      String lengthHeader = Headers.contentLengthHeader,
      data,
      Options? options}) {
    // TODO: implement download
    throw UnimplementedError();
  }

  @override
  Future<Response> downloadUri(Uri uri, savePath,
      {ProgressCallback? onReceiveProgress,
      CancelToken? cancelToken,
      bool deleteOnError = true,
      String lengthHeader = Headers.contentLengthHeader,
      data,
      Options? options}) {
    // TODO: implement downloadUri
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) {
    // TODO: implement fetch
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> getUri<T>(Uri uri,
      {Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement getUri
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> head<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) {
    // TODO: implement head
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> headUri<T>(Uri uri,
      {data, Options? options, CancelToken? cancelToken}) {
    // TODO: implement headUri
    throw UnimplementedError();
  }

  @override
  // TODO: implement interceptors
  Interceptors get interceptors => throw UnimplementedError();

  @override
  void lock() {
    // TODO: implement lock
  }

  @override
  Future<Response<T>> patch<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement patch
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> patchUri<T>(Uri uri,
      {data,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement patchUri
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> post<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement post
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> postUri<T>(Uri uri,
      {data,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement postUri
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> put<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement put
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> putUri<T>(Uri uri,
      {data,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement putUri
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> request<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      CancelToken? cancelToken,
      Options? options,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement request
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> requestUri<T>(Uri uri,
      {data,
      CancelToken? cancelToken,
      Options? options,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) {
    // TODO: implement requestUri
    throw UnimplementedError();
  }

  @override
  void unlock() {
    // TODO: implement unlock
  }
}
