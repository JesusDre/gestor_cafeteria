import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const baseUrl = 'http://api.test';

void main() {
  group('ApiClient · respuestas exitosas', () {
    test('200 con JSON válido devuelve el cuerpo decodificado', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '$baseUrl/orders');
        return http.Response(
          jsonEncode([
            {'id': 1, 'customer': 'Ana', 'drink': 'latte'},
          ]),
          200,
        );
      });
      final api = ApiClient(client: mock, baseUrl: baseUrl);

      final resultado = await api.get('/orders');

      expect(resultado, [
        {'id': 1, 'customer': 'Ana', 'drink': 'latte'},
      ]);
    });
  });

  group('ApiClient · respuestas de error del servidor', () {
    test('404 lanza NotFoundFailure con el mensaje de detail', () {
      final mock = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Order 9 not found'}), 404);
      });
      final api = ApiClient(client: mock, baseUrl: baseUrl);

      expect(
        api.get('/orders/9'),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.message,
            'message',
            'Order 9 not found',
          ),
        ),
      );
    });

    test('409 lanza ConflictFailure con el mensaje de detail', () {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Cannot change status from pending to delivered'}),
          409,
        );
      });
      final api = ApiClient(client: mock, baseUrl: baseUrl);

      expect(
        api.patch('/orders/1', {'status': 'delivered'}),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'Cannot change status from pending to delivered',
          ),
        ),
      );
    });

    test('422 lanza ValidationFailure con fields armado desde loc[1] y msg', () {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['body', 'customer'],
                'msg': 'Must be 1-50 characters',
              },
            ],
          }),
          422,
        );
      });
      final api = ApiClient(client: mock, baseUrl: baseUrl);

      expect(
        api.post('/orders', {'customer': '', 'drink': 'latte', 'size': 'M'}),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.fields,
            'fields',
            {'customer': 'Must be 1-50 characters'},
          ),
        ),
      );
    });

    test('503 lanza ServerFailure con statusCode 503', () {
      final mock = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Simulated failure'}), 503);
      });
      final api = ApiClient(client: mock, baseUrl: baseUrl);

      expect(
        api.get('/orders'),
        throwsA(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  group('ApiClient · fallos de conexión', () {
    test('si el cliente lanza ClientException se convierte en NetworkFailure', () {
      final mock = MockClient((request) async {
        throw http.ClientException('sin red');
      });
      final api = ApiClient(client: mock, baseUrl: baseUrl);

      expect(api.get('/orders'), throwsA(isA<NetworkFailure>()));
    });

    test('si la respuesta tarda más que el timeout se lanza NetworkFailure', () {
      final mock = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('[]', 200);
      });
      final api = ApiClient(
        client: mock,
        baseUrl: baseUrl,
        timeout: const Duration(milliseconds: 50),
      );

      expect(api.get('/orders'), throwsA(isA<NetworkFailure>()));
    });
  });
}
