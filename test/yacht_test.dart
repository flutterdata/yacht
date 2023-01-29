import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:isar/isar.dart';
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
    final yachtInitializer = Yacht.initialize([
      userRepositoryProvider,
      cityRepositoryProvider,
    ]);

    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWith((ref) => TestUserRepository(ref)),
        cityRepositoryProvider.overrideWith((ref) => TestCityRepository(ref)),
      ],
    );

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

  group('basic >', () {
    test('save, find, serialize', () async {
      final u1 = User(id: '1', name: 'Jane', age: 36);

      expect(u1.isNew, isTrue);
      u1.save();
      expect(u1.isNew, isFalse);

      final zoe = User(id: '1', name: 'Zoe', age: 36).save();

      expect(u1.yachtKey, zoe.yachtKey);
      expect(zoe.yachtKey, zoe.reload()!.yachtKey);

      final existingUser = container.users.findOne('1');
      expect(existingUser!.name, 'Zoe');

      zoe.hometown.value = City(id: '9', name: 'London').save();
      zoe.bucketList.addAll([City(id: '92', name: 'Jakarta').save()]);

      expect(zoe.hometown.value!.name, 'London');

      expect(zoe.toJson(), {
        'id': '1',
        'firstName': 'Zoe',
        'age': 36,
        'hometown': '9',
        'bucketList': ['92']
      });

      zoe.delete();

      expect(zoe.reload(), isNull);

      final cities = container.cities.findAll();
      expect(cities, hasLength(2));

      final citiesFilter = container.cities.findAll(
        where: (_) => _.filter().nameContains('don'),
      );
      expect(citiesFilter, hasLength(1));
      expect(citiesFilter.first.toJson(), {
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
  });
  group('notifiers >', () {
    test('watchAll', () async {
      final listener = Listener<List<City>>();

      final notifier = container.cities.watchAll();

      dispose = notifier.addListener(listener);

      verify(listener([])).called(1);

      final rio = City(id: '1', name: 'Rio de Janeiro').save();
      await oneMs();

      verify(listener([rio])).called(1);

      verifyNoMoreInteractions(listener);
    });

    test('watchAll with query', () async {
      final listener = Listener<List<City>>();

      City(id: '1', name: 'Rio de Janeiro').save();
      await oneMs();
      final hk = City(id: '2', name: 'Hong Kong').save();
      await oneMs();

      final notifier = container.cities
          .watchAll(where: (_) => _.filter().nameContains('on'));
      dispose = notifier.addListener(listener);

      verify(listener([hk])).called(1);

      final london = City(id: '3', name: 'London').save();
      await oneMs();
      await oneMs();

      verify(listener([hk, london])).called(1);

      verifyNoMoreInteractions(listener);
    });

    test('watchOne', () async {
      final listener = Listener<City?>();

      final rio = City(id: '91', name: 'Rio de Janeiro').save();

      final notifier = container.cities.watchOne(rio);

      dispose = notifier.addListener(listener);

      verify(listener(rio)).called(1);

      final rio2 = rio.copyWith(population: 2887614).save();
      await oneMs();

      verify(listener(argThat(
              isA<City>().having((c) => c.population, 'population', 2887614))))
          .called(1);

      rio2.delete();
      await oneMs();

      verify(listener(argThat(isNull)));

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
