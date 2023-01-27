import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:yacht/yacht.dart';

import '_support/city.dart';
import '_support/user.dart';

void main() {
  group('Basic operations', () {
    test('Write, read, serialize', () async {
      await initialize(schemas: [UserSchema, CitySchema], clear: true);
      final container = ProviderContainer();

      final zoe = User(id: 'zoe', name: 'Jane', age: 36).copyWith.name('Zoe');

      zoe.save();

      final existingUser = container.users.findOne('zoe');
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
  });
}

// gen

extension ProviderContainerX on ProviderContainer {
  Repository<User> get users => Repository<User>();
  Repository<City> get cities => Repository<City>();
}
