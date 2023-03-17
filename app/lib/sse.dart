import 'dart:async';
import 'dart:developer';
import 'package:universal_html/html.dart' as html;

class Sse {
  final html.EventSource eventSource;
  final StreamController<String> streamController;

  Sse._internal(this.eventSource, this.streamController);

  factory Sse.connect({
    required Uri baseUri,
    required String eventType,
    required String channel,
    int retryInterval = 1000,
    bool isReconnecting=false,
    bool withCredentials = false,
  }) {
    final streamController = StreamController<String>();
    final newUri = baseUri.replace(
      queryParameters: <String, String>{
        'channel': channel,
      },
    );
    final eventSource = html.EventSource(newUri.toString(), withCredentials: withCredentials);
    int retryInterval = 0;

    eventSource.onOpen.listen((event) {
      log('Connected to SSE server.');
      retryInterval = 1000; // Reset retry interval
    });

    eventSource.addEventListener(eventType, (html.Event message) {
      streamController.add((message as html.MessageEvent).data as String);
      log(message.lastEventId);
    });

   eventSource.onError.listen((event) {
    log('Error occurred. Attempting to reconnect in $retryInterval milliseconds');
    if (isReconnecting) {
      return;
    }
    isReconnecting = true;
    eventSource.close();
    // streamController.close();

    // Apply backoff reconnect strategy
    retryInterval = retryInterval * 2; // Gradually increase reconnect interval
    int maxRetryInterval = 30000; // Maximum reconnect interval, e.g., 30 seconds
    if (retryInterval > maxRetryInterval) {
      retryInterval = maxRetryInterval;
    }
    Timer(Duration(milliseconds: retryInterval), () => Sse.connect(
      baseUri: baseUri,
      eventType: eventType,
      channel: channel,
      isReconnecting: false,
      retryInterval: retryInterval
      ));
    });
    
    return Sse._internal(eventSource, streamController);
  }

  Stream get stream => streamController.stream;

  bool isClosed() => streamController.isClosed;

  void close() {
    eventSource.close();
    streamController.close();
  }
}