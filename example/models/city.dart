import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:isar/isar.dart';
import 'package:yacht/yacht.dart';

part 'city.g.dart';

@collection
@CopyWith()
class City with DataModel<City> {
  @override
  Id id;

  final String? name;
  final int? population;

  City({this.id = Isar.autoIncrement, this.name, this.population});
}
