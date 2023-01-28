import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yacht/yacht.dart';

part 'city.g.dart';

@collection
@CopyWith()
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

final cityRepositoryProvider =
    Provider<Repository<City>>((_) => CityRepository());

//

mixin CityAdapter on Repository<City> {
  @override
  String get baseUrl => super.baseUrl;

  @override
  CollectionSchema<City> get schema => CitySchema;
}

mixin CityAdapter2 on Repository<City> {}

class CityRepository = Repository<City> with CityAdapter, CityAdapter2;

//

extension ProviderContainerCityX on ProviderContainer {
  Repository<City> get cities => read(cityRepositoryProvider);
}
