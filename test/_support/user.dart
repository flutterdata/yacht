import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yacht/yacht.dart';

import 'city.dart';

part 'user.g.dart';

mixin RemoteSoreteAdapter<T extends DataModel<T>> on Repository<T> {}

@Collection(ignore: {'props', 'hashCode', 'stringify'})
@CopyWith()
class User with DataModel<User>, EquatableMixin {
  @Index()
  @override
  final String? id;

  @Name("firstName")
  final String? name;
  final int? age;
  final DateTime? dob;
  @Enumerated(EnumType.name)
  final Priority priority;
  final Job? job;

  // relationships
  final hometown = IsarLink<City>();
  final bucketList = IsarLinks<City>();

  User({
    this.id,
    this.name,
    this.age,
    this.dob,
    this.job,
    this.priority = Priority.first,
  });

  @override
  String toString() {
    return 'User $id [$yachtKey] ($name ($age))';
  }

  @override
  List<Object?> get props => [id, name, age];
}

enum Priority {
  first(10),
  second(100),
  third(1000);

  const Priority(this.myValue);

  final short myValue;
}

@embedded
class Job {
  late String title;
  late String employer;
}
