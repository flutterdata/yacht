import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:yacht/yacht.dart';

part 'city.g.dart';

@Collection(ignore: {'props', 'hashCode', 'stringify'})
@CopyWith()
@DataRepository([NothingSerializer])
class City with DataModel<City>, EquatableMixin {
  @Index()
  @override
  final String id;

  final String? name;
  final int? population;

  City({required this.id, this.name, this.population});

  @override
  List<Object?> get props => [id, name, population];
}

mixin NothingSerializer<T extends DataModel<T>> on Repository<T> {
  @override
  Future<Map<String, dynamic>> serialize(T model) {
    return super.serialize(model);
  }
}
