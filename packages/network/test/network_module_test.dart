import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

class _SuccessfulAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"access_token":"response-secret"}',
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('development logging excludes credentials and payloads', () async {
    final logs = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _SuccessfulAdapter()
      ..interceptors.add(devLogInterceptor(logPrint: logs.add));

    await dio.post<void>(
      '/sessions?token=query-secret',
      data: const {'password': 'body-secret'},
      options: Options(
        headers: const {'Authorization': 'Bearer header-secret'},
      ),
    );

    final output = logs.join('\n');
    expect(output, contains('POST /sessions'));
    expect(output, contains('-> 200'));
    expect(output, isNot(contains('query-secret')));
    expect(output, isNot(contains('body-secret')));
    expect(output, isNot(contains('header-secret')));
    expect(output, isNot(contains('response-secret')));
    expect(output, isNot(contains('Authorization')));
    expect(output, isNot(contains('access_token')));
  });
}
