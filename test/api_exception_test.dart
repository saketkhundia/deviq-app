import 'package:deviq/core/errors/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException mapping', () {
    test('status codes map to kinds + human messages', () {
      expect(ApiException.fromStatus(401).kind,
          ApiErrorKind.unauthorized);
      expect(ApiException.fromStatus(404).kind, ApiErrorKind.notFound);
      expect(ApiException.fromStatus(429).kind, ApiErrorKind.rateLimited);
      expect(ApiException.fromStatus(500).kind, ApiErrorKind.server);
      // Never leak raw transport details.
      expect(ApiException.fromStatus(500).message, isNot(contains('Dio')));
      expect(ApiException.network.message, isNot(contains('DioException')));
    });
  });
}
