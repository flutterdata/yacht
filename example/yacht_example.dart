import 'package:riverpod/riverpod.dart';
import 'package:yacht/yacht.dart';

import 'models/city.dart';
import 'models/user.dart';

Future<void> main() async {
  await initialize(schemas: [UserSchema, CitySchema]);

  final container = ProviderContainer();

  final newUser = User(name: 'Jane', age: 36).copyWith.name('Zoe');

  await newUser.save();

  final existingUser = await container.users.findOne(2);
  print(existingUser?.name);

  newUser.city.value = await City(id: 9, name: 'London').save();

  print(newUser.city.value!.name);

  await newUser.delete();

  final existingUser2 = await newUser.reload();
  print(existingUser2?.name);

  final cities = await container.cities.findAll();
  print(cities);
}

// gen

extension ProviderContainerX on ProviderContainer {
  Repository<User> get users => Repository<User>();
  Repository<City> get cities => Repository<City>();
}
