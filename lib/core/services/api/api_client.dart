import 'package:dio/dio.dart';

class ApiClient {
  static ApiClient? _instance;
  late Dio client;

  ApiClient._internal() {
    client = Dio();
    client.options.baseUrl = 'https://your-api-base-url.com';
    client.options.connectTimeout = const Duration(seconds: 30);
    client.options.receiveTimeout = const Duration(seconds: 30);
  }

  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }
}




