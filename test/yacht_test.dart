import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:yacht/yacht.dart';

import '_support/city.dart';
import '_support/user.dart';

void main() {
  late ProviderContainer container;
  Function? dispose;

  setUpAll(() async {
    container = ProviderContainer();

    final yachtInitializer = Yacht.initialize([
      userRepositoryProvider,
      cityRepositoryProvider,
    ]);

    await container.read(yachtInitializer.future);
  });

  tearDown(() {
    Yacht.clear();
    dispose?.call();
  });

  tearDownAll(() async {
    await Yacht.dispose(destroy: true);
    container.dispose();
  });

  group('Basic operations', () {
    test('Write, read, serialize', () async {
      final zoe = User(id: 'zoe', name: 'Jane', age: 36).copyWith.name('Zoe');

      zoe.save();

      final existingUser = await container.users.findOne('zoe');
      expect(existingUser!.name, 'Zoe');

      zoe.hometown.value = City(id: '9', name: 'London').save();
      zoe.bucketList.addAll([City(id: '92', name: 'Jakarta').save()]);

      expect(zoe.hometown.value!.name, 'London');

      expect(zoe.toJson(), {
        'id': 'zoe',
        'firstName': 'Zoe',
        'age': 36,
        'hometown': '9',
        'bucketList': ['92']
      });

      zoe.delete();

      expect(zoe.reload(), isNull);

      final cities = container.cities.findAll();
      expect(cities.first.toJson(), {
        'id': '9',
        'name': 'London',
      });
    });
    test('remote', () async {
      container.read(testResponseProvider.notifier).state =
          TestResponse.text('zorete');
      final z = await container.cities.zzz();
      print(z);
    });
    test('notifiers', () async {
      final listener = Listener<List<City>>();

      final notifier = container.cities.watchAll();

      dispose = notifier.addListener(listener);

      verify(listener([])).called(1);

      final rio = City(id: '1', name: 'Rio de Janeiro').save();
      await oneMs();

      verify(listener([rio])).called(1);

      verifyNoMoreInteractions(listener);
    });
  });
}

// test utils

class Listener<T> extends Mock {
  void call(T value);
}

/// Waits 1 millisecond
Future<void> oneMs() async {
  await Future.delayed(const Duration(milliseconds: 1));
}

final testResponseProvider =
    StateProvider<TestResponse>((_) => TestResponse.text(''));

class TestResponse {
  final Future<String> Function(http.Request) callback;
  final int statusCode;
  final Map<String, String> headers;

  const TestResponse(
    this.callback, {
    this.statusCode = 200,
    this.headers = const {},
  });

  factory TestResponse.text(String text) => TestResponse((_) async => text);
}

mixin TestAdapter<T extends DataModel<T>> on Repository<T> {
  http.Client get httpClient {
    return MockClient((req) async {
      final response = ref.watch(testResponseProvider);
      final text = await response.callback(req);
      return http.Response(
        text,
        response.statusCode,
        headers: response.headers,
      );
    });
  }
}
