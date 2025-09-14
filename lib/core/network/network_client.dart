import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class NetworkClient {
  final Dio dio;

  NetworkClient(this.dio);
}