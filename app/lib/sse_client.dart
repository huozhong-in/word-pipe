import 'dart:developer';
import 'dart:async';
import 'package:universal_html/html.dart' as html;


class SSEClient {
  Uri baseUri;
  String eventType;
  String channel;
  html.EventSource? _eventSource;
  int _retryInterval;
  bool _isReconnecting;
  String lastLastEventId = '';

  // 创建一个StreamController，用于广播特定事件类型的消息
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  static final SSEClient _instance = SSEClient._internal();

  factory SSEClient.getInstance(Uri baseUri, String eventType, String channel, {int retryInterval = 1000}) {
    return _instance.._init(baseUri, eventType, channel, retryInterval: retryInterval);
  }

  SSEClient._internal() : baseUri = Uri(), eventType = '', channel = '', _retryInterval = 0, _isReconnecting = false;

  void _init(Uri baseUri, String eventType, String channel, {int retryInterval = 1000}) {
    if (_eventSource == null) {
      this.baseUri = baseUri;
      this.eventType = eventType;
      this.channel = channel;
      _retryInterval = retryInterval;
      _isReconnecting = false;

      // 添加channel参数到URL
      Uri url = baseUri.replace(
        queryParameters: <String, String>{
          'channel': channel,
        },
      );
      _connect(url);
    }
  }

  void _connect(Uri url) {
    _eventSource = html.EventSource(url.toString());

    _eventSource!.onOpen.listen((event) {
      log('Connected to SSE server.');
      _retryInterval = 1000; // Reset retry interval
      // if (_eventSource!.readyState != html.EventSource.CONNECTING) {
      // }
      // if (_eventSource!.readyState == html.EventSource.OPEN) {
      // }
    });

    _eventSource!.addEventListener(eventType, (event) {
      // print(eventType); // `prod`
      html.MessageEvent messageEvent = event as html.MessageEvent;
      // log('Received message: ${messageEvent.data}');
      log('lastEventId: ${messageEvent.lastEventId}');
      // 过滤掉重复的消息
      if (messageEvent.lastEventId == lastLastEventId) {
        print('重复的消息');
      }else{
        lastLastEventId = messageEvent.lastEventId;
        _messageController.add(messageEvent.data); // 向StreamController添加消息
      }
    });

    // _eventSource!.onMessage.listen((event) {
    //   html.MessageEvent messageEvent = event;
    //   log('Received message: ${messageEvent.data}');
    //   log('lastEventId: ${messageEvent.lastEventId}');
    //   _messageController.add(messageEvent.data); // 向StreamController添加消息
    // });

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

  // 获取单例实例
  SSEClient sseClient = SSEClient.getInstance(url, eventType, channel);

  // 订阅消息流
  sseClient.messages.listen((message) {
    log('Message from main(): $message');
  });

  // 当需要停止监听时，可以调用 `sseClient.close()` 方法。
  sseClient.close();
}

