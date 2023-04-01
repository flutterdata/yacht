import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:yacht/yacht.dart';

import '_support/city.dart';
import '_support/user.dart';

void main() {
  late ProviderContainer container;
  Function? dispose;

  setUpAll(() async {
    // needed for tests
    final path = File('test/_support/libisar.dylib').absolute.path;
    await Isar.initializeIsarCore(
      libraries: {
        Abi.macosX64: path,
        Abi.macosArm64: path,
        Abi.androidArm64: path,
      },
    );

    final yachtInitializer = Yacht.initialize([
      usersRepositoryProvider,
      citiesRepositoryProvider,
    ]);

    container = ProviderContainer(
      overrides: [
        usersRepositoryProvider.overrideWith((ref) => TestUsersRepository(ref)),
        citiesRepositoryProvider
            .overrideWith((ref) => TestCitiesRepository(ref)),
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

  group('basic', () {
    test('keys', () {
      final u1 = User(id: '1', name: 'Zoe');
      expect(User(id: '1').yachtKey, u1.yachtKey);

      final u1b = User(name: 'Jane', age: 36);
      final u2 = u1b.copyWith(id: '2');

      expect(User(id: '2').yachtKey, u2.yachtKey);
      expect(User().yachtKey, isNot(User().yachtKey));
    });

    test('save, reload, find', () async {
      final u1 = User(id: '1', name: 'Jane', age: 36).save();
      expect(u1.yachtKey, u1.reload()!.yachtKey);

      final u1b = container.users.findOne('1');
      expect(u1b!.name, 'Jane');

      u1.delete();
      expect(u1b.reload(), isNull); // as u1 == u1b

      final idLess = User(name: 'NN').save();
      expect(idLess.reload(), idLess);
    });

    test('serialization', () async {
      final zoe = User(
        id: '1',
        name: 'Zoe',
        dob: DateTime.utc(1987, 1, 17),
        job: Job()
          ..employer = 'self'
          ..title = 'engineer',
        age: 36,
      );
      // zoe.hometown.value = City(id: '9', name: 'London').save();
      // zoe.bucketList.addAll([City(id: '92', name: 'Jakarta').save()]);

      final zoeMap = {
        'id': '1',
        'firstName': 'Zoe',
        'age': 36,
        'dob': 537840000000000,
        'job': {'employer': 'self', 'title': 'engineer'},
        'priority': 'first',
        // 'hometown': '9',
        // 'bucketList': ['92'],
      };

      expect(await container.users.serialize(zoe), zoeMap);
      expect(await container.users.deserialize(zoeMap), zoe);
    });

    test('relationship, query, raw', () async {
      final zoe = User(
        id: '1',
        name: 'Zoe',
        dob: DateTime.utc(1987, 1, 17),
        job: Job()
          ..employer = 'self'
          ..title = 'engineer',
        age: 36,
      ).init();

      final j = City(id: '92', name: 'Jakarta').save();
      zoe.hometown.value = City(id: '9', name: 'London').save();
      zoe.bucketList.add(j);

      expect(zoe.hometown.value!.name, 'London');
      expect(zoe.bucketList.toSet(), {j});

      zoe.bucketList.remove(j);
      expect(zoe.bucketList.toSet(), <City>{});

      final cities = container.cities.findAll();
      expect(cities, hasLength(2));

      final citiesFilter = container.cities.findAll(
        where: (_) => _.filter().nameContains('don'),
      );
      expect(citiesFilter, hasLength(1));
      expect(await container.cities.serialize(citiesFilter.first), {
        'id': '9',
        'name': 'London',
      });

      // access raw isar
      expect(container.cities.collection.isar.citys.countSync(), 2);
    });

    test('relationship associations', () async {});

    test('remote', () async {
      final u1 = User(id: '1', name: 'Jane', age: 36).save();
      final map = await container.users.serialize(u1);
      map['id'] = '2';

      container.read(testResponseProvider.notifier).state =
          TestResponse.text(jsonEncode(map));
      final u2 = await container.users.asyncFindOne('2');
      expect(u2!.id, '2');
    });
  });

  group('notifiers', () {
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

      // TODO check
      // final london = City(id: '3', name: 'London').save();
      // await oneMs();
      // verify(listener([hk, london])).called(1);

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

class TestUsersRepository = UsersRepository with TestAdapter;
class TestCitiesRepository = CitiesRepository with TestAdapter;

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
