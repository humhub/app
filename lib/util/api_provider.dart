import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class APIProvider {
  final WidgetRef _ref;

  APIProvider(this._ref);
  
  static Map<String, String> get jsonContent => {
    'content-type': 'application/json',
    'accept': 'application/json',
  };

  static APIProvider of(WidgetRef ref) => APIProvider(ref);

  Future<AsyncValue<T>> request<T>(
      Future<T> Function(Dio dio) fetcher, {
        Dio? dio,
      }) async {
    dio = dio ?? _ref.read(dioProvider);
    try {
      final value = await fetcher(dio!);
      return AsyncValue.data(value);
    } catch (err, stackTrace) {
      return AsyncValue.error(err, stackTrace);
    }
  }

  final dioProvider = Provider<Dio>((ref) {
    final api = Dio(BaseOptions(
      headers: APIProvider.jsonContent,
    ));
    return api;
  });
}