// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'dart:async';

import 'package:async/async.dart' show StreamGroup;
import 'package:dio/dio.dart'
    as dio
    show DioException, Options, Response, DioExceptionType, CancelToken;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart';
import 'package:mutex/mutex.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '/config.dart';
import '/domain/model/session.dart';
import '/store/model/version.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';
import '/util/rate_limiter.dart';
import '/util/web/web_utils.dart';
import 'exceptions.dart';
import 'websocket/interface.dart'
    if (dart.library.io) 'websocket/io.dart'
    if (dart.library.js_interop) 'websocket/web.dart'
    as websocket;

/// Base GraphQl provider.
class GraphQlProviderBase extends DisposableInterface {
  /// [GraphQlClient] of this provider.
  final GraphQlClient _client = GraphQlClient();

  /// Returns [GraphQLClient] with or without authorization.
  GraphQlClient get client => _client;

  /// Returns mutex guarding the [client].
  Mutex get clientGuard => _client.guard;

  /// Returns authorization bearer token.
  AccessTokenSecret? get token => _client.token;

  /// Sets callback, called when middleware catches [AuthorizationException].
  set authExceptionHandler(Future<void> Function(AuthorizationException)? fn) =>
      _client.authExceptionHandler = fn;

  /// Sets authorization bearer token and reconnects the [client].
  set token(AccessTokenSecret? value) => _client.token = value;

  /// Indicates whether this [GraphQlClient] is successfully connected to the
  /// endpoint.
  RxBool get connected => _client.connected;

  @override
  void onClose() {
    Log.info('onClose()', '$runtimeType');

    disconnect();
    super.onClose();
  }

  /// Reconnects the [client] right away if the [token] mismatch is detected.
  Future<void> reconnect() => _client.reconnect();

  /// Disconnects the [client] and disposes the connection.
  void disconnect() => _client.disconnect();

  /// Clears the cache attached to the client.
  void clearCache() => _client.clearCache();

  /// Registers the provided [handler] to listen to [Exception]s happening with
  /// the queries.
  ///
  /// Exception is `null`, when successful query is made.
  void addListener(void Function(Exception?) handler) =>
      _client.addListener(handler);

  /// Unregisters the provided [handler] from listening to [Exception]s
  /// happening with the queries.
  ///
  /// Does nothing, if the provided [handler] wasn't added.
  void removeListener(void Function(Exception?) handler) =>
      _client.removeListener(handler);
}

/// Wrapper around [GraphQLClient] used to implement middleware capabilities.
class GraphQlClient {
  GraphQlClient() {
    Log.debug('GraphQlClient()', '$runtimeType($_id)');
  }

  /// Starting period of exponential backoff reconnection.
  static const int minReconnectPeriodMillis = 1000;

  /// Maximum possible period of exponential backoff reconnection.
  static const int maxReconnectPeriodMillis = 30000;

  /// Indicator whether this [GraphQlClient] should allow [WebSocketLink]
  /// connections.
  ///
  /// If `false`, then [subscribe] won't emit any data.
  ///
  /// Intended to be used for tests only, because tests may construct
  /// [GraphQlClient]s on-the-flight just to do some queries or mutations, which
  /// don't need WebSocket connections at all.
  bool withWebSocket = true;

  /// Authorization bearer token.
  AccessTokenSecret? token;

  /// Mutex guarding the [client].
  final Mutex guard = Mutex();

  /// Callback, called when middleware catches [AuthorizationException].
  Future<void> Function(AuthorizationException)? authExceptionHandler;

  /// Indicator whether this [GraphQlClient] is successfully connected to the
  /// endpoint.
  final RxBool connected = RxBool(true);

  /// [Duration] considered as a network timeout.
  static const Duration timeout = Duration(seconds: 60);

  /// Inner [GraphQLClient].
  GraphQLClient? _client;

  /// [WebSocketLink] used by the [_client].
  WebSocketLink? _wsLink;

  /// [GraphQLWebSocketChannel] of [_wsLink] to cancel it during
  /// [_disposeWebSocket].
  GraphQLWebSocketChannel? _wsChannel;

  /// Current authorization bearer token of the [_client].
  ///
  /// Used to update [_client] if [token] is different.
  AccessTokenSecret? _currentToken;

  /// List of the currently ongoing [SubscriptionConnection]s used to emit a
  /// re-subscribe request on the [_client] reconnection.
  final List<SubscriptionConnection> _subscriptions = [];

  /// Current period of exponential backoff reconnection.
  ///
  /// Starts with the [minReconnectPeriodMillis] and increases by a factor of
  /// two every failed reconnection attempt until reaches
  /// [maxReconnectPeriodMillis].
  int _reconnectPeriodMillis = minReconnectPeriodMillis ~/ 2;

  /// [Timer] for [_wsLink] exponential backoff reconnection.
  Timer? _backoffTimer;

  /// [Timer] for checking [_wsLink] connection status and invoking a
  /// reconnection attempt on failure.
  Timer? _checkConnectionTimer;

  /// [Duration] of [_checkConnectionTimer].
  static const Duration _checkReconnectDuration = Duration(seconds: 20);

  /// [StreamSubscription] to the raw [WebSocketChannel] used to react on
  /// [_wsLink] connection failures.
  StreamSubscription? _channelSubscription;

  /// Indicator whether the [_wsLink] is connected.
  bool _wsConnected = false;

  /// [RateLimiter] limiting the [subscribe] requests to the backend per second.
  final RateLimiter _subscriptionLimiter = RateLimiter(
    per: const Duration(milliseconds: 1000),
  );

  /// [RateLimiter] limiting the [query] requests to the backend per second.
  final RateLimiter _queryLimiter = RateLimiter(
    per: const Duration(milliseconds: 1000),
  );

  /// Indicator whether the latest [_middleware] has finished with an
  /// [Exception].
  bool _errored = false;

  /// Handlers listening for [Exception]s happening with this client.
  final List<void Function(Exception?)> _handlers = [];

  /// Unique ID of this [GraphQlClient] to differentiate it from others.
  final String _id = const Uuid().v4();

  /// Returns [GraphQLClient] with or without [token] header authorization.
  Future<GraphQLClient> get client async {
    if (_client != null && _currentToken == token) {
      return _client!;
    }
    return guard.protect(() async {
      if (_client != null && _currentToken == token) {
        return _client!;
      } else {
        _client = await _newClient();
        _currentToken = token;
        return _client!;
      }
    });
  }

  /// Resolves a single query according to the [QueryOptions] specified and
  /// returns a [Future] which resolves with the [QueryResult] or throws an
  /// [Exception].
  Future<QueryResult> query(
    QueryOptions options, {
    RawClientOptions? raw,
    Exception Function(Map<String, dynamic>)? onException,
  }) async {
    final dio.Response posted = await post(
      const RequestSerializer().serializeRequest(options.asRequest),
      operationName: options.operationName,
      onException: onException,
      raw: raw,
    );

    if (posted.data['data'] == null) {
      throw GraphQlException([GraphQLError(message: posted.data.toString())]);
    }

    final QueryResult query = QueryResult(
      options: options,
      source: QueryResultSource.network,
      data: posted.data['data'],
    );

    GraphQlProviderExceptions.fire(query, onException);
    return query;
  }

  /// Resolves a single mutation according to the [MutationOptions] specified
  /// and returns a [Future] which resolves with the [QueryResult] or throws an
  /// [Exception].
  ///
  /// If [raw] is non-`null`, then the request is immediately performed on a new
  /// [GraphQLClient] and without [AuthorizationException] handling.
  Future<QueryResult> mutate(
    MutationOptions options, {
    RawClientOptions? raw,
    Exception Function(Map<String, dynamic>)? onException,
  }) async {
    final dio.Response posted = await post(
      const RequestSerializer().serializeRequest(options.asRequest),
      operationName: options.operationName,
      onException: onException,
      raw: raw,
    );

    if (posted.data['data'] == null) {
      throw GraphQlException([GraphQLError(message: posted.data.toString())]);
    }

    final QueryResult query = QueryResult(
      options: options,
      source: QueryResultSource.network,
      data: posted.data['data'],
    );

    GraphQlProviderExceptions.fire(query, onException);
    return query;
  }

  /// Subscribes to a GraphQL subscription according to the [options] specified.
  ///
  /// The higher the [priority], the earlier this subscription will be
  /// subscribed to in a rate limiter queue.
  Stream<QueryResult> subscribe(
    SubscriptionOptions options, {
    FutureOr<Version?> Function()? ver,
    bool resubscribe = true,
    int priority = 0,
  }) {
    return SubscriptionHandle(
      _subscribe,
      (e) {
        _subscriptions.remove(e);
        e?.dispose();
      },
      options,
      ver: ver,
      resubscribe: resubscribe,
      priority: priority,
    ).stream;
  }

  /// Makes an HTTP POST request with an exposed [onSendProgress].
  Future<dio.Response<T>> post<T>(
    dynamic data, {
    dio.Options? options,
    String? operationName,
    Exception Function(Map<String, dynamic>)? onException,
    void Function(int, int)? onSendProgress,
    RawClientOptions? raw,
    dio.CancelToken? cancelToken,
  }) {
    return _middleware(() async {
      return await _transaction(operationName, () async {
        final dio.Options authorized = options ?? dio.Options();
        authorized.headers = (authorized.headers ?? {});

        if (raw == null || raw.token != null) {
          authorized.headers!['Authorization'] =
              'Bearer ${raw?.token ?? token}';
        }

        try {
          return await (await PlatformUtils.dio).post<T>(
            '${Config.url}:${Config.port}${Config.graphql}',
            data: data,
            options: authorized,
            onSendProgress: onSendProgress,
            cancelToken: cancelToken,
          );
        } on dio.DioException catch (e) {
          if (e.response != null) {
            if (onException != null &&
                e.response?.data is Map<String, dynamic> &&
                e.response?.data['data'] != null) {
              throw onException(e.response!.data['data']);
            }
          }

          rethrow;
        }
      });
    });
  }

  /// Reconnects the [client] right away if the [token] mismatch is detected.
  Future<void> reconnect() async {
    Log.debug('reconnect()', '$runtimeType($_id)');

    if (_client == null || _currentToken != token) {
      _client = await _newClient();
      _currentToken = token;
    }
  }

  /// Disconnects the [client] and disposes the connection.
  void disconnect() {
    Log.debug('disconnect()', '$runtimeType($_id)');

    _disposeWebSocket();
    _queryLimiter.clear();
    _subscriptionLimiter.clear();
    _client = null;
  }

  /// Clears the cache attached to the [client].
  void clearCache() => _client?.cache.store.reset();

  /// Registers the provided [handler] to listen to [Exception]s happening with
  /// the queries.
  ///
  /// Exception is `null`, when successful query is made.
  void addListener(void Function(Exception?) handler) {
    _handlers.add(handler);
  }

  /// Unregisters the provided [handler] from listening to [Exception]s
  /// happening with the queries.
  ///
  /// Does nothing, if the provided [handler] wasn't added.
  void removeListener(void Function(Exception?) handler) {
    _handlers.remove(handler);
  }

  /// Subscribes to a GraphQL subscription according to the [options] specified
  /// and returns a [Stream] which either emits received data or an error.
  ///
  /// Re-subscription is required on [ResubscriptionRequiredException] errors.
  Future<SubscriptionConnection> _subscribe(
    SubscriptionOptions options,
    int priority,
  ) async {
    final stream = await _subscriptionLimiter.execute<Stream<QueryResult>>(
      () async => (await client).subscribe(options),
      priority: priority,
    );

    // Store the reference to the current [WebSocketLink].
    final WebSocketLink? wsLink = _wsLink;

    SubscriptionConnection? connection;
    connection = SubscriptionConnection(
      stream.expand((event) {
        Object? e = GraphQlProviderExceptions.parse(event);

        if (e != null) {
          if (e is AuthorizationException) {
            // If we're still using the same [WebSocketLink], then
            // [_newWebSocket] didn't happen just yet, so proceed with error.
            if (wsLink == _wsLink && _subscriptions.contains(connection)) {
              authExceptionHandler?.call(e);
            }

            return [];
          } else {
            throw e;
          }
        }

        return [event];
      }),
    );

    _subscriptions.add(connection);

    return connection;
  }

  /// Middleware that wraps the provided [fn] execution and attempts to handle
  /// [AuthorizationException] if any.
  Future<T> _middleware<T>(Future<T> Function() fn) async {
    // Store the reference to the current [WebSocketLink].
    final GraphQLClient? client = _client;

    try {
      final T result = await fn();

      if (_errored) {
        _reportException(null);
        _errored = false;
      }

      return result;
    } on AuthorizationException catch (e) {
      if (client != _client) {
        rethrow;
      }

      await authExceptionHandler?.call(e);
      return await fn();
    } on Exception catch (e) {
      _errored = true;
      _reportException(e);
      rethrow;
    }
  }

  /// Attempts to reconnect the [_wsLink] using the exponential backoff
  /// algorithm.
  void _reconnect() {
    if (_wsConnected) {
      _reconnectPeriodMillis = 0;
      _wsConnected = false;

      if (!_errored) {
        _reportException(ConnectionException(Exception('_reconnect()')));
        _errored = true;
      }
    }

    _reconnectPeriodMillis *= 2;
    if (_reconnectPeriodMillis > maxReconnectPeriodMillis) {
      _reconnectPeriodMillis = maxReconnectPeriodMillis;
    }

    Log.info('Reconnecting in $_reconnectPeriodMillis ms...', 'WebSocket');

    _checkConnectionTimer?.cancel();
    _backoffTimer?.cancel();

    // Try to reconnect again in [_reconnectPeriodMillis].
    _backoffTimer = Timer(
      Duration(milliseconds: _reconnectPeriodMillis),
      () async {
        if (_reconnectPeriodMillis == 0) {
          _reconnectPeriodMillis = minReconnectPeriodMillis ~/ 2;
        }

        _client = await _newClient();

        // Populate the [_checkConnectionTimer] to check if any connection was
        // established and attempt to reconnect again if not.
        _checkConnectionTimer = Timer(_checkReconnectDuration, () {
          if (!_wsConnected) {
            _reconnect();
          }
        });
      },
    );
  }

  /// Populates the [_wsLink] with a new [WebSocketLink].
  Future<void> _newWebSocket() async {
    if (!withWebSocket) {
      return;
    }

    _disposeWebSocket();
    Log.debug('_newWebSocket()', '$runtimeType($_id)');

    _wsLink = WebSocketLink(
      Config.ws,
      config: SocketClientConfig(
        initialPayload: {'ticket': token?.val},
        headers: {
          if (!PlatformUtils.isWeb) 'User-Agent': await PlatformUtils.userAgent,
        },
        autoReconnect: false,
        delayBetweenReconnectionAttempts: null,
        inactivityTimeout: const Duration(seconds: 15),
        connectFn: (Uri uri, Iterable<String>? protocols) async {
          Log.debug('connectFn($uri, $protocols)', '$runtimeType($_id)');

          _wsChannel?.sink.close();
          _wsChannel = websocket
              .connect(
                uri,
                protocols: protocols,
                customClient: PlatformUtils.isWeb
                    ? null
                    : (HttpClient()..userAgent = await PlatformUtils.userAgent),
              )
              .forGraphQL();

          _wsChannel?.stream = _wsChannel!.stream.handleError((_, _) => false);
          _channelSubscription = _wsChannel?.stream.listen((e) {
            if (!_wsConnected) {
              Log.info('Connected', 'WebSocket');
              _checkConnectionTimer?.cancel();
              _backoffTimer?.cancel();
              _wsConnected = true;

              if (_errored) {
                _reportException(null);
                _errored = false;
              }
            }

            if (!connected.value) {
              _reportException(null);
            }
          }, onDone: _reconnect);

          return _wsChannel!;
        },
      ),
    );

    // Send a [ResubscriptionRequiredException] to all the ongoing subscriptions
    // having listeners.
    for (SubscriptionConnection s in List.from(_subscriptions)) {
      if (s.hasListener) {
        Future.delayed(Duration.zero, () {
          s.addError(const ResubscriptionRequiredException());
        });
      }
    }
    _subscriptions.clear();
  }

  /// Disposes the [_wsLink] and related resources.
  void _disposeWebSocket() {
    if (_wsLink != null) {
      Log.debug('_disposeWebSocket()', '$runtimeType($_id)');
    }

    _checkConnectionTimer?.cancel();
    _backoffTimer?.cancel();
    _channelSubscription?.cancel();
    _wsChannel?.sink.close();
    _wsLink?.dispose();
    _wsLink = null;
  }

  /// Creates a new [GraphQLClient].
  Future<GraphQLClient> _newClient([RawClientOptions? raw]) async {
    Log.debug('_newClient($raw)', '$runtimeType($_id)');

    final httpLink = HttpLink(
      '${Config.url}:${Config.port}${Config.graphql}',
      httpClient: WebUtils.httpClient,
      defaultHeaders: {
        if (!PlatformUtils.isWeb) 'User-Agent': await PlatformUtils.userAgent,
      },
    );

    final AccessTokenSecret? bearer = raw?.token ?? token;
    final AuthLink authLink = AuthLink(getToken: () => 'Bearer $bearer');
    final Link httpAuthLink = bearer != null
        ? authLink.concat(httpLink)
        : httpLink;
    Link link = httpAuthLink;

    // Update the WebSocket connection if not [raw].
    if (raw == null) {
      _disposeWebSocket();

      // WebSocket connection is meaningful only if the token is provided.
      if (token != null) {
        await _newWebSocket();

        if (_wsLink != null) {
          link = Link.split(
            (request) => request.isSubscription,
            _wsLink!,
            httpAuthLink,
          );
        }
      }
    }

    return GraphQLClient(
      // Default cache's store is [InMemoryStore], so no persistence.
      cache: GraphQLCache(store: InMemoryStore()),

      // Default policy states that by default all queries and mutations
      // should use network only results and store no cache.
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
          cacheReread: CacheRereadPolicy.ignoreAll,
        ),
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
          cacheReread: CacheRereadPolicy.ignoreAll,
        ),
        subscribe: Policies(
          fetch: FetchPolicy.networkOnly,
          cacheReread: CacheRereadPolicy.ignoreAll,
        ),
      ),
      link: link,
      queryRequestTimeout: const Duration(seconds: 60),
    );
  }

  /// Completes the [fn] wrapped around [Sentry.startTransaction], meaning the
  /// [fn] will be recorded as a transaction.
  Future<T> _transaction<T>(String? operation, Future<T> Function() fn) async {
    if (operation == null || Config.sentryDsn.isEmpty || kDebugMode) {
      return await fn();
    }

    final ISentrySpan transaction = Sentry.startTransaction(
      'graphql.$operation()',
      'graphql',
      autoFinishAfter: const Duration(minutes: 1),
    )..startChild('query');

    try {
      return await fn();
    } catch (e) {
      transaction.throwable = e;
      transaction.status = const SpanStatus.internalError();
      rethrow;
    } finally {
      transaction.finish();
    }
  }

  /// Handles the [exception] to determine the [connected] status of this
  /// client.
  void _reportException(Exception? exception) {
    if (exception == null) {
      connected.value = true;
    } else if (connected.value) {
      if (exception is ClientException ||
          exception is ConnectionException ||
          exception is TimeoutException ||
          exception is FormatException) {
        connected.value = false;
      } else if (exception is dio.DioException) {
        switch (exception.type) {
          case dio.DioExceptionType.connectionTimeout:
          case dio.DioExceptionType.sendTimeout:
          case dio.DioExceptionType.receiveTimeout:
          case dio.DioExceptionType.connectionError:
            connected.value = false;
            break;

          default:
            // No-op.
            break;
        }
      } else if (exception is GraphQlException) {
        // No-op.
      }
    }

    for (var handler in _handlers) {
      handler(exception);
    }
  }
}

/// Wrapper around a [Stream], representing an ongoing GraphQL subscription with
/// an ability to add errors to it.
///
/// May be (and intended to) be used to implement re-subscription requests.
class SubscriptionConnection {
  SubscriptionConnection(this._stream);

  /// [StreamController] used to add events and errors to the output [stream].
  final StreamController<QueryResult> _addonController = StreamController();

  /// Source [Stream] of a [QueryResult]s.
  final Stream<QueryResult> _stream;

  /// Indicates whether this [SubscriptionConnection] has already invoked
  /// [dispose].
  bool _disposed = false;

  /// Indicates whether there is a subscriber on the [stream] or not.
  bool get hasListener => _addonController.hasListener;

  /// Indicates whether this [SubscriptionConnection] has already invoked
  /// [dispose].
  bool get disposed => _disposed;

  /// Returns a merged stream of the subscription this [SubscriptionConnection]
  /// represents and an addon stream.
  Stream<QueryResult> get stream =>
      StreamGroup.merge([_addonController.stream, _stream]);

  /// Disposes the [StreamController]s associated with this connection.
  void dispose() {
    if (_disposed) {
      return;
    }

    _addonController.close();
    _disposed = true;
  }

  /// Sends or enqueues an error event to the [stream].
  void addError(Object error, [StackTrace? stackTrace]) =>
      _addonController.addError(error, stackTrace);
}

/// Steady [StreamController] listening to the provided GraphQL subscription
/// events and resubscribing on the errors.
class SubscriptionHandle {
  SubscriptionHandle(
    this._listen,
    this._cancel,
    this._options, {
    this.ver,
    this.resubscribe = true,
    this.priority = 0,
  });

  /// Callback, called when a [Version] to pass the [SubscriptionOptions] is
  /// required.
  final FutureOr<Version?> Function()? ver;

  /// Indicator whether resubscription should happen automatically on
  /// [ResubscriptionRequiredException] or not.
  final bool resubscribe;

  /// Priority of [_listen] subscription in [RateLimiter]'s queue.
  ///
  /// The bigger, the more earlier this subscription will be resubscribed.
  int priority;

  /// Callback, called to get the [Stream] of [QueryResult]s itself.
  final FutureOr<SubscriptionConnection> Function(SubscriptionOptions, int)
  _listen;

  /// Callback, called to cancel the provided [SubscriptionConnection].
  final void Function(SubscriptionConnection?) _cancel;

  /// [SubscriptionOptions] to pass to the [_listen].
  SubscriptionOptions _options;

  /// Last [SubscriptionConnection] retrieved from [_listen].
  SubscriptionConnection? _connection;

  /// [Mutex] guarding [_listen] invokes.
  final Mutex _mutex = Mutex();

  /// [StreamController] of the [stream] exposed containing the events.
  late final StreamController<QueryResult> _controller =
      StreamController.broadcast(onListen: _subscribe, onCancel: cancel);

  /// [StreamSubscription] to the [_subscribe] stream.
  StreamSubscription? _subscription;

  /// [Timer] invoking [_resubscribe] with backoff algorithm.
  Timer? _backoff;

  /// Current delay of exponential backoff subscribing.
  Duration _backoffDuration = Duration.zero;

  /// [Stream] of the events of this [SubscriptionHandle].
  Stream<QueryResult> get stream => _controller.stream;

  /// Cancels the subscription.
  void cancel() {
    _backoff?.cancel();
    _backoffDuration = Duration.zero;
    _subscription?.cancel();
    _cancel(_connection);
  }

  /// Subscribes to the events.
  Future<void> _subscribe() async {
    Log.debug('subscribe()', '$runtimeType');

    await _mutex.protect(() async {
      _subscription?.cancel();

      try {
        _cancel(_connection);
        _connection = null;

        if (!_controller.hasListener) {
          return;
        }

        _connection = await _listen(_options, priority);

        if (!_controller.hasListener) {
          return cancel();
        }

        _subscription = _connection?.stream.listen(
          (e) {
            if (_backoff != null) {
              Log.info('Successfully resubscribed 👍', _options.operationName);

              _backoffDuration = Duration.zero;
              _backoff?.cancel();
              _backoff = null;
            }

            _controller.add(e);
          },
          onDone: resubscribe ? _resubscribe : null,
          onError: (e) {
            _controller.addError(e);

            if (e is ResubscriptionRequiredException && resubscribe) {
              _resubscribe();
            } else if (e is StaleVersionException && resubscribe) {
              _resubscribe(noVersion: true);
            } else {
              _resubscribe();
            }
          },
          cancelOnError: true,
        );
      } catch (e) {
        _controller.addError(e);
        _resubscribe();
      }
    });
  }

  /// Resubscribes to the events.
  void _resubscribe({bool noVersion = false}) async {
    Log.info('Reconnecting in $_backoffDuration...', _options.operationName);

    _cancel(_connection);
    _connection = null;

    _options = SubscriptionOptions(
      document: _options.document,
      operationName: _options.operationName,
      variables: {
        ..._options.variables,
        'ver': noVersion ? null : (await ver?.call())?.val,
      },
      fetchPolicy: _options.policies.fetch,
      errorPolicy: _options.policies.error,
      cacheRereadPolicy: _options.policies.cacheReread,
      optimisticResult: _options.optimisticResult,
      context: _options.context,
      parserFn: _options.parserFn,
    );

    if (_backoff?.isActive != true) {
      _backoff?.cancel();
      _backoff = Timer(_backoffDuration, _subscribe);
      if (_backoffDuration == Duration.zero) {
        _backoffDuration = const Duration(milliseconds: 500);
      } else if (_backoffDuration < const Duration(seconds: 16)) {
        _backoffDuration *= 2;
      }
    }
  }
}

/// Options for raw [GraphQlClient] instance.
class RawClientOptions {
  const RawClientOptions([this.token]);

  /// [AccessTokenSecret] to pass to raw [GraphQlClient].
  final AccessTokenSecret? token;
}
