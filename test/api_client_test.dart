import 'package:deviq/core/errors/api_exception.dart';
import 'package:deviq/core/networking/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// ApiClient transport behavior: single retry for idempotent GETs on
/// transport failures, no retry on app errors or writes.
Dio _failingThenOk({
  required List<DioException Function(RequestOptions o)> script,
  Map<String, dynamic>? okData,
}) {
  var calls = 0;
  final dio = Dio(BaseOptions(baseUrl: 'https://x.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) {
        calls++;
        if (calls <= script.length) {
          h.reject(script[calls - 1](o));
        } else {
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: okData ?? {'ok': true},
            ),
          );
        }
      },
    ),
  );
  return dio;
}

DioException _conn(RequestOptions o) =>
    DioException(requestOptions: o, type: DioExceptionType.connectionError);

void main() {
  group('GET retry', () {
    test('retries once on connection error, then succeeds', () async {
      var calls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://x.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            calls++;
            if (calls == 1) {
              h.reject(_conn(o));
            } else {
              h.resolve(
                Response(
                    requestOptions: o,
                    statusCode: 200,
                    data: {'ok': true}),
              );
            }
          },
        ),
      );
      final api = ApiClient(dio: dio, baseUrl: 'https://x.test');
      final r = await api.get<Map<String, dynamic>>(
        '/health',
        decode: (d) => (d as Map).cast<String, dynamic>(),
      );
      expect(r['ok'], isTrue);
      expect(calls, 2);
    });

    test('surfaces mapped error after the retry also fails', () async {
      final api = ApiClient(
        dio: _failingThenOk(script: [
          _conn,
          _conn,
          (o) => DioException(
                requestOptions: o,
                type: DioExceptionType.connectionError,
              ),
        ]),
        baseUrl: 'https://x.test',
      );
      await expectLater(
        api.get<dynamic>('/health'),
        throwsA(isA<ApiException>().having(
            (e) => e.kind, 'kind', ApiErrorKind.network)),
      );
    });

    test('does not retry HTTP application errors', () async {
      var calls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://x.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            calls++;
            h.reject(
              DioException(
                requestOptions: o,
                type: DioExceptionType.badResponse,
                response: Response(
                    requestOptions: o,
                    statusCode: 404,
                    data: {'detail': 'nope'}),
              ),
            );
          },
        ),
      );
      final api = ApiClient(dio: dio, baseUrl: 'https://x.test');
      await expectLater(api.get<dynamic>('/nope'), throwsA(isA<ApiException>()));
      expect(calls, 1);
    });

    test('POST never retries (not idempotent)', () async {
      var calls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://x.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            calls++;
            h.reject(_conn(o));
          },
        ),
      );
      final api = ApiClient(dio: dio, baseUrl: 'https://x.test');
      await expectLater(
          api.post<dynamic>('/auth/login'), throwsA(isA<ApiException>()));
      expect(calls, 1);
    });
  });
}
