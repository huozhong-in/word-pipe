import 'dart:developer';
import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';
import 'package:app/controller.dart';

class SSEClient {
  Uri baseUri;
  final String eventType;
  final String channel;
  html.EventSource? _eventSource;
  int _retryInterval;
  bool _isReconnecting;

  // 创建一个StreamController，用于广播特定事件类型的消息
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  SSEClient(this.baseUri, this.eventType, this.channel, {int retryInterval = 1000})
      : _retryInterval = retryInterval,
        _isReconnecting = false {
    // 添加channel参数到URL
    Uri url = baseUri.replace(
      queryParameters: <String, String>{
        'channel': channel,
      },
    );
    _connect(url);
  }

  final Controller c = Get.find();
  
  void _connect(Uri url) {
    
    _eventSource = html.EventSource(url.toString());

    _eventSource!.onOpen.listen((event) {
      log('Connected to SSE server.');
      _retryInterval = 1000; // Reset retry interval
      // 如果存在 lastEventId，则在连接之前发送一个HTTP POST请求，通知服务器客户端已连接
      if (_eventSource!.readyState != html.EventSource.CONNECTING) {
        // String lastEventId = (event as html.MessageEvent).lastEventId;
        // log(lastEventId);
        // c.reConnect('username', lastEventId);
      }
    });

    _eventSource!.addEventListener(eventType, (event) {
      html.MessageEvent messageEvent = event as html.MessageEvent;
      // log('Received message: ${messageEvent.data}');
      log('lastEventId: ${messageEvent.lastEventId}');
      _messageController.add(messageEvent.data); // 向StreamController添加消息
    });

    _eventSource!.onError.listen((event) {
      if (_isReconnecting) {
        return; // 如果已经在尝试重新连接，就不要触发多次
      }
      _isReconnecting = true; // 设置正在尝试重新连接的标志
      log('Error occurred. Attempting to reconnect in $_retryInterval millseconds...');
      _eventSource!.close();

      // Apply backoff reconnect strategy
      _retryInterval = _retryInterval * 2; // Gradually increase reconnect interval
      int maxRetryInterval = 30000; // Maximum reconnect interval, e.g., 30 seconds
      if (_retryInterval > maxRetryInterval) {
        _retryInterval = maxRetryInterval;
      }
      Timer(Duration(milliseconds: _retryInterval), () {
        _isReconnecting = false; // 重置正在尝试重新连接的标志
        _connect(url);
      });
    });
  }

  Stream<String> get messages => _messageController.stream; // 提供消息流的访问

  void close() {
    _eventSource?.close();
    _messageController.close(); // 关闭StreamController
  }
}

void main() {
  Uri url = Uri.parse('http://127.0.0.1/stream');
  String eventType = 'broadcasting';
  String channel = 'users.social';

  SSEClient sseClient = SSEClient(url, eventType, channel);

  // 订阅消息流
  sseClient.messages.listen((message) {
    log('Message from main(): $message');
  });

  // 当需要停止监听时，可以调用 `sseClient.close()` 方法。
  // sseClient.close();
}
