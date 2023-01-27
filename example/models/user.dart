import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:isar/isar.dart';
import 'package:yacht/yacht.dart';

import 'city.dart';

part 'user.g.dart';

@collection
@CopyWith()
class User with DataModel<User> {
  @override
  Id id;

  @Name("firstName")
  final String? name;
  final int? age;

  final city = IsarLink<City>();

  User({this.id = Isar.autoIncrement, this.name, this.age});
}
