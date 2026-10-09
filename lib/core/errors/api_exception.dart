/// Human-readable API errors. Never surface raw Dio exceptions to users.
enum ApiErrorKind {
  network, // no connectivity / timeout
  unauthorized, // 401 — session expired
  forbidden, // 403
  notFound, // 404 — unknown username etc.
  rateLimited, // 429
  server, // 5xx
  badRequest, // 400/422 — invalid input
  malformed, // unparsable response
  unknown,
}

class ApiException implements Exception {
  const ApiException(this.kind, this.message, {this.statusCode});

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
  static ApiException fromStatus(int? status, {String? detail}) {
    switch (status) {
      case 401:
        return ApiException(
          ApiErrorKind.unauthorized,
          detail ?? 'Your session has expired. Please sign in again.',
          statusCode: status,
        );
      case 403:
        return const ApiException(
          ApiErrorKind.forbidden,
          'You don\u2019t have access to this resource.',
        );
      case 404:
        return ApiException(
          ApiErrorKind.notFound,
          detail ?? 'Not found. Check the username and try again.',
          statusCode: status,
        );
      case 429:
        return const ApiException(
          ApiErrorKind.rateLimited,
          'Rate limit reached. Please wait a moment and try again.',
        );
      case 400:
      case 422:
        return ApiException(
          ApiErrorKind.badRequest,
          detail ?? 'Invalid request. Check your input and try again.',
          statusCode: status,
        );
      default:
        if (status != null && status >= 500) {
          return ApiException(
            ApiErrorKind.server,
            detail ?? 'DevIQ servers are having trouble. Try again shortly.',
            statusCode: status,
          );
        }
        return ApiException(
          ApiErrorKind.unknown,
          detail ?? 'Something went wrong. Please try again.',
          statusCode: status,
        );
    }
  }

  static const ApiException network = ApiException(
    ApiErrorKind.network,
    'No connection. Check your network and retry.',
  );
  static const ApiException timeout = ApiException(
    ApiErrorKind.network,
    'The request timed out. The server may be waking up — retry shortly.',
  );
  static const ApiException githubUnreachable = ApiException(
    ApiErrorKind.network,
    'GitHub couldn\u2019t be reached right now. Please try again.',
  );
  static const ApiException malformed = ApiException(
    ApiErrorKind.malformed,
    'Unexpected response from the server. Please try again.',
  );
}

/// AI endpoints require a valid session token. When the backend reports
/// an authorization/session failure, returns actionable sign-in copy;
/// otherwise returns null (message is already user-friendly).
String? signInNeededMessage(String message) {
  final m = message.toLowerCase();
  if (m.contains('authorization') ||
      m.contains('invalid or expired session') ||
      m.contains('unauthorized') ||
      m.contains('session expired')) {
    return 'AI features need a signed-in DevIQ account. Please sign in to continue.';
  }
  return null;
}
