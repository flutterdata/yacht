import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:isar/isar.dart';
import 'package:yacht/yacht.dart';

import 'city.dart';

part 'user.g.dart';

@collection
@CopyWith()
class User with DataModel<User> {
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
}
