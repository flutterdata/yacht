import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:isar/isar.dart';
import 'package:yacht/yacht.dart';

part 'city.g.dart';

@collection
@CopyWith()
class City with DataModel<City> {
  @Index()
  @override
  final String id;

  final String? name;
  final int? population;

  City({required this.id, this.name, this.population});
}
