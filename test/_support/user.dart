import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yacht/yacht.dart';

import '../yacht_test.dart';
import 'city.dart';

part 'user.g.dart';

@collection
@CopyWith()
class User with DataModel<User>, EquatableMixin {
  @Index()
  @override
  final String? id;

  @Name("firstName")
  final String? name;
  final int? age;

  // relationships
  final hometown = IsarLink<City>();
  final bucketList = IsarLinks<City>();

  User({this.id, this.name, this.age});

  @override
  String toString() {
    return 'User $id [$internalKey] ($name ($age))';
  }

  @override
  List<Object?> get props => [id, name, age];
}

mixin UserAdapter on Repository<User> {
  @override
  String get baseUrl => super.baseUrl;

  @override
  CollectionSchema<User> get schema => UserSchema;
}

class UserRepository = Repository<User> with UserAdapter, TestAdapter;

final userRepositoryProvider =
    Provider<Repository<User>>((ref) => UserRepository(ref));

extension ProviderContainerUserX on ProviderContainer {
  Repository<User> get users => read(userRepositoryProvider);
}