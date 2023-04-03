import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:app/config.dart';

void shelf_serve_main() async {
  var server = await shelf_io.serve(
    proxyHandler(SHELF_PROXY_HOST),
    '127.0.0.1',
    8888,
  );

  print('Proxying at http://${server.address.host}:${server.port}');
}