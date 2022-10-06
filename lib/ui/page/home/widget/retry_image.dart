import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_client_helper/http_client_helper.dart';

class RetryImage extends StatefulWidget {
  const RetryImage(this.url, {Key? key}) : super(key: key);

  final String url;

  @override
  State<RetryImage> createState() => _RetryImageState();
}

class _RetryImageState extends State<RetryImage> {
  Duration backOff = const Duration(milliseconds: 500);

  /// Starting period of exponential backoff reconnection.
  static const int minReconnectPeriodMillis = 500;

  bool loaded = false;
  late Uint8List image;
  final StreamController<ImageChunkEvent> chunkEvents =
      StreamController<ImageChunkEvent>();
  int _reconnectPeriodMillis = minReconnectPeriodMillis ~/ 2;

  @override
  void initState() {
    _loadNetwork();
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      (loaded) ? Image.memory(image) : CircularProgressIndicator();

  /// Get the image from network.
  Future<void> _loadNetwork() async {
    await tryRun();
  }

  Future<void> tryRun() async {
    http.Response? data;
    while (loaded == false) {
      print('lelkek');
      try {
        data = await http.get(Uri.parse(widget.url));
      } on OperationCanceledError catch (error) {
        rethrow;
      } catch (e) {
        print(e);
      }

      if (data != null && data.statusCode == 200) {
        setState(() {
          loaded = true;
          image = data!.bodyBytes;
        });
        print('loaded');
        return;
      }

      final Future<void> future = CancellationTokenSource.register(
          null,
          Future<void>.delayed(
              Duration(milliseconds: _reconnectPeriodMillis), () {}));
      await future;
      print(_reconnectPeriodMillis);
      if (_reconnectPeriodMillis < 32000) {
        _reconnectPeriodMillis *= 2;
      }
    }
    return;
  }
}
