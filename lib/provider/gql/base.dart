// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:dio/dio.dart' as dio show DioException, Options, Response;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mutex/mutex.dart';
import 'package:universal_io/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '/config.dart';
import '/domain/model/session.dart';
import '/store/model/version.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';
import 'exceptions.dart';
import 'websocket/interface.dart'
    if (dart.library.io) 'websocket/io.dart'
    if (dart.library.html) 'websocket/web.dart' as websocket;

/// Base GraphQl provider.
class GraphQlProviderBase {
  /// [GraphQlClient] of this provider.
  final GraphQlClient _client = GraphQlClient();

  /// Returns [GraphQLClient] with or without authorization.
  GraphQlClient get client => _client;

  /// Returns mutex guarding the [client].
  Mutex get clientGuard => _client.guard;

  /// Returns authorization bearer token.
  AccessToken? get token => _client.token;

  /// Sets callback, called when middleware catches [AuthorizationException].
  set authExceptionHandler(Future<void> Function(AuthorizationException)? fn) =>
      _client.authExceptionHandler = fn;

  /// Sets authorization bearer token and reconnects the [client].
  set token(AccessToken? value) => _client.token = value;

  /// Reconnects the [client] right away if the [token] mismatch is detected.
  Future<void> reconnect() => _client.reconnect();

  /// Disconnects the [client] and disposes the connection.
  void disconnect() => _client.disconnect();

  /// Clears the cache attached to the client.
  void clearCache() => _client.clearCache();
}

/// Wrapper around [GraphQLClient] used to implement middleware capabilities.
class GraphQlClient {
  /// Starting period of exponential backoff reconnection.
  static const int minReconnectPeriodMillis = 1000;

  /// Maximum possible period of exponential backoff reconnection.
  static const int maxReconnectPeriodMillis = 30000;

  /// Authorization bearer token.
  AccessToken? token;

  /// Mutex guarding the [client].
  final Mutex guard = Mutex();

  /// Callback, called when middleware catches [AuthorizationException].
  Future<void> Function(AuthorizationException)? authExceptionHandler;

  /// [Duration] considered as a network timeout.
  static const Duration timeout = Duration(seconds: 60);

  /// Inner [GraphQLClient].
  GraphQLClient? _client;

  /// [WebSocketLink] used by the [_client].
  WebSocketLink? _wsLink;

  /// Current authorization bearer token of the [_client].
  ///
  /// Used to update [_client] if [token] is different.
  AccessToken? _currentToken;

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
    QueryOptions options, [
    Exception Function(Map<String, dynamic>)? handleException,
  ]) =>
      _middleware(() async {
        QueryResult result =
            await (await client).query(options).timeout(timeout);
        GraphQlProviderExceptions.fire(result, handleException);
        return result;
      });

  /// Resolves a single mutation according to the [MutationOptions] specified
  /// and returns a [Future] which resolves with the [QueryResult] or throws an
  /// [Exception].
  ///
  /// If [raw] is `true` then the request is immediately performed on a new
  /// [GraphQLClient] and without [AuthorizationException] handling.
  Future<QueryResult> mutate(
    MutationOptions options, {
    bool raw = false,
    Exception Function(Map<String, dynamic>)? onException,
  }) async {
    if (raw) {
      QueryResult result =
          await (await _newClient(true)).mutate(options).timeout(timeout);
      GraphQlProviderExceptions.fire(result, onException);
      return result;
    } else {
      return _middleware(() async {
        QueryResult result =
            await (await client).mutate(options).timeout(timeout);
        GraphQlProviderExceptions.fire(result, onException);
        return result;
      });
    }
  }

  /// Subscribes to a GraphQL subscription according to the [options] specified.
  Stream<QueryResult> subscribe(
    SubscriptionOptions options, {
    Version? Function()? ver,
  }) {
    return SubscriptionHandle(_subscribe, options, ver: ver).stream;
  }

  /// Makes an HTTP POST request with an exposed [onSendProgress].
  Future<dio.Response<T>> post<T>(
    dynamic data, {
    dio.Options? options,
    Exception Function(Map<String, dynamic>)? onException,
    void Function(int, int)? onSendProgress,
  }) =>
      _middleware(() async {
        final dio.Options authorized = options ?? dio.Options();
        authorized.headers = (authorized.headers ?? {});
        authorized.headers!['Authorization'] = 'Bearer $token';

        try {
          return await (await PlatformUtils.dio).post<T>(
            '${Config.url}:${Config.port}${Config.graphql}',
            data: data,
            options: authorized,
            onSendProgress: onSendProgress,
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

  /// Reconnects the [client] right away if the [token] mismatch is detected.
  Future<void> reconnect() async {
    if (_client == null || _currentToken != token) {
      _client = await _newClient();
      _currentToken = token;
    }
  }

  /// Disconnects the [client] and disposes the connection.
  void disconnect() {
    _disposeWebSocket();
    _client = null;
  }

  /// Clears the cache attached to the [client].
  void clearCache() => _client?.cache.store.reset();

  /// Subscribes to a GraphQL subscription according to the [options] specified
  /// and returns a [Stream] which either emits received data or an error.
  ///
  /// Re-subscription is required on [ResubscriptionRequiredException] errors.
  Future<Stream<QueryResult>> _subscribe(SubscriptionOptions options) async {
    var stream = (await client).subscribe(options);

    final connection = SubscriptionConnection(
      stream.expand((event) {
        Object? e = GraphQlProviderExceptions.parse(event);

        if (e != null) {
          if (e is AuthorizationException) {
            authExceptionHandler?.call(e);
            return [];
          } else {
            throw e;
          }
        }

        return [event];
      }),
    );

    _subscriptions.add(connection);
    return connection.stream;
  }

  /// Middleware that wraps the provided [fn] execution and attempts to handle
  /// [AuthorizationException] if any.
  Future<T> _middleware<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AuthorizationException catch (e) {
      await authExceptionHandler?.call(e);
      return await fn();
    }
  }

  /// Attempts to reconnect the [_wsLink] using the exponential backoff
  /// algorithm.
  void _reconnect() {
    if (_wsConnected) {
      _reconnectPeriodMillis = 0;
      _wsConnected = false;
    }

    _reconnectPeriodMillis *= 2;
    if (_reconnectPeriodMillis > maxReconnectPeriodMillis) {
      _reconnectPeriodMillis = maxReconnectPeriodMillis;
    }

    Log.print('Reconnecting in $_reconnectPeriodMillis ms...', 'WebSocket');

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
          var socket = websocket
              .connect(
                uri,
                protocols: protocols,
                customClient: PlatformUtils.isWeb
                    ? null
                    : (HttpClient()..userAgent = await PlatformUtils.userAgent),
              )
              .forGraphQL();

          socket.stream = socket.stream.handleError((_, __) => false);

          _channelSubscription = socket.stream.listen(
            (_) {
              if (!_wsConnected) {
                Log.print('Connected', 'WebSocket');
                _checkConnectionTimer?.cancel();
                _backoffTimer?.cancel();
                _wsConnected = true;
              }
            },
            onDone: _reconnect,
          );

          return socket;
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
    _checkConnectionTimer?.cancel();
    _backoffTimer?.cancel();
    _channelSubscription?.cancel();
    _wsLink?.dispose();
    _wsLink = null;
  }

  /// Creates a new [GraphQLClient].
  Future<GraphQLClient> _newClient([bool raw = false]) async {
    final httpLink = HttpLink(
      '${Config.url}:${Config.port}${Config.graphql}',
      defaultHeaders: {
        if (!PlatformUtils.isWeb) 'User-Agent': await PlatformUtils.userAgent,
      },
    );
    final AuthLink authLink = AuthLink(getToken: () => 'Bearer $token');
    final Link httpAuthLink =
        token != null ? authLink.concat(httpLink) : httpLink;
    Link link = httpAuthLink;

    // Update the WebSocket connection if not [raw].
    if (!raw) {
      _disposeWebSocket();

      // WebSocket connection is meaningful only if the token is provided.
      if (token != null) {
        await _newWebSocket();
        link = Link.split(
          (request) => request.isSubscription,
          _wsLink!,
          httpAuthLink,
        );
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
    );
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

  /// Indicates whether there is a subscriber on the [stream] or not.
  bool get hasListener => _addonController.hasListener;

  /// Returns a merged stream of the subscription this [SubscriptionConnection]
  /// represents and an addon stream.
  Stream<QueryResult> get stream =>
      StreamGroup.merge([_addonController.stream, _stream]);

  /// Sends or enqueues an error event to the [stream].
  void addError(Object error, [StackTrace? stackTrace]) =>
      _addonController.addError(error, stackTrace);
}

/// Steady [StreamController] listening to the provided GraphQL subscription
/// events and resubscribing on the errors.
class SubscriptionHandle {
  SubscriptionHandle(this._listen, this._options, {this.ver});

  /// Callback, called when a [Version] to pass the [SubscriptionOptions] is
  /// required.
  final Version? Function()? ver;

  /// Callback, called to get the [Stream] of [QueryResult]s itself.
  final FutureOr<Stream<QueryResult>> Function(SubscriptionOptions) _listen;

  /// [SubscriptionOptions] to pass to the [_listen].
  final SubscriptionOptions _options;

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
  }

  /// Subscribes to the events.
  Future<void> _subscribe() async {
    _subscription?.cancel();

    try {
      _subscription = (await _listen(_options)).listen(
        (e) {
          if (_backoff != null) {
            Log.print(
              'Successfully resubscribed 👍',
              _options.operationName,
            );

            _backoffDuration = Duration.zero;
            _backoff?.cancel();
            _backoff = null;
          }

          _controller.add(e);
        },
        onDone: _resubscribe,
        onError: (e) {
          _controller.addError(e);
          if (e is ResubscriptionRequiredException) {
            _resubscribe();
          } else if (e is StaleVersionException) {
            _resubscribe(noVersion: true);
          } else {
            _resubscribe();
          }
        },
      );
    } catch (e) {
      _controller.addError(e);
      _resubscribe();
    }
  }

  /// Resubscribes to the events.
  void _resubscribe({bool noVersion = false}) {
    Log.print('Reconnecting in $_backoffDuration...', _options.operationName);

    if (ver != null) {
      _options.variables['ver'] = noVersion ? null : ver!()?.val;
    }

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
