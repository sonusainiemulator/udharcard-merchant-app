import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:paysecure/controllers/udhar_controller.dart';

class TestUdharController extends UdharController {
  int fetchUsersCalls = 0;

  @override
  Future<void> fetchUsers() async {
    fetchUsersCalls++;
  }

  @override
  Future<void> checkConnection() async {
    isOffline = false;
  }
}

class FakeConnectivityPlatform extends ConnectivityPlatform {
  @override
  Future<ConnectivityResult> checkConnectivity() async {
    return ConnectivityResult.wifi;
  }

  @override
  Stream<ConnectivityResult> get onConnectivityChanged =>
      const Stream<ConnectivityResult>.empty();
}

class FakeHttpOverrides extends HttpOverrides {
  FakeHttpOverrides(this.responseBody, this.statusCode);

  final String responseBody;
  final int statusCode;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return FakeHttpClient(responseBody: responseBody, statusCode: statusCode);
  }
}

class FakeHttpClient implements HttpClient {
  FakeHttpClient({required this.responseBody, required this.statusCode});

  final String responseBody;
  final int statusCode;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return FakeHttpClientRequest(
      method: method,
      url: url,
      responseBody: responseBody,
      statusCode: statusCode,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpClientRequest implements HttpClientRequest {
  FakeHttpClientRequest({
    required this.method,
    required this.url,
    required this.responseBody,
    required this.statusCode,
  });

  @override
  final String method;

  final Uri url;

  final String responseBody;
  final int statusCode;

  final FakeHttpHeaders _headers = FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  int contentLength = 0;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  bool bufferOutput = true;

  @override
  Encoding encoding = utf8;

  @override
  void add(List<int> data) {}

  @override
  Future addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = '']) {}

  @override
  Future<HttpClientResponse> close() async {
    throw const SocketException('test transport failure');
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  Future<HttpClientResponse> get done async => throw const SocketException('test transport failure');

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpHeaders implements HttpHeaders {
  FakeHttpHeaders({Map<String, List<String>>? initialValues}) {
    if (initialValues != null) {
      _values.addAll(initialValues);
    }
  }

  final Map<String, List<String>> _values = {};

  void _setValue(String name, String value) {
    _values[name.toLowerCase()] = [value];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  void addAll(Map<String, String> values) {
    values.forEach((key, value) => _setValue(key, value));
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _setValue(name, value.toString());
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  String? value(String name) {
    final values = _values[name.toLowerCase()];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  @override
  void removeAll(String name, {bool preserveHeaderCase = false}) {
    _values.remove(name.toLowerCase());
  }

  @override
  void clear() {
    _values.clear();
  }

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  void operator []=(String name, Object value) =>
      _setValue(name, value.toString());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UdharController sync flow', () {
    late ConnectivityPlatform originalPlatform;

    setUp(() {
      Get.testMode = true;
      originalPlatform = ConnectivityPlatform.instance;
      ConnectivityPlatform.instance = FakeConnectivityPlatform();
    });

    tearDown(() {
      ConnectivityPlatform.instance = originalPlatform;
      Get.reset();
    });

    test('syncManual triggers one realtime refresh via fetchUsers', () async {
      final controller = TestUdharController();

      await HttpOverrides.runZoned(() async {
        await controller.syncManual();
      }, createHttpClient: (_) {
        return FakeHttpClient(
          responseBody: jsonEncode({
            'status': 'success',
            'data': {'customers': [], 'contacts': []},
          }),
          statusCode: 200,
        );
      });

      expect(controller.fetchUsersCalls, 1);
    });
  });
}