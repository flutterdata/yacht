import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:inflection3/inflection3.dart' as inflection;
import 'package:isar/isar.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yacht/yacht.dart';

Builder repositoryBuilder(options) =>
    SharedPartBuilder([RepositoryGenerator()], 'yacht');

class RepositoryGenerator extends GeneratorForAnnotation<Collection> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final className = element.name!;
    final classNameLower = inflection.pluralize(className.decapitalize());
    // ClassElement classElement = element as ClassElement;

    // final hasFromJson =
    //     classElement.constructors.any((c) => c.name == 'fromJson');
    // final fromJson = hasFromJson
    //     ? '$className.fromJson(map)'
    //     : '_\$${className}FromJson(map)';

    // final methods = [
    //   ...classElement.methods,
    //   ...classElement.interfaces.map((i) => i.methods).expand((i) => i),
    //   ...classElement.mixins.map((i) => i.methods).expand((i) => i)
    // ];
    // final hasToJson = methods.any((c) => c.name == 'toJson');
    // final toJson =
    //     hasToJson ? 'model.toJson()' : '_\$${className}ToJson(model)';

    return '''
// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin \$${className}RemoteAdapter on RemoteAdapter<$className> {}

class ${className}RemoteAdapter = RemoteAdapter<$className> with \$${className}RemoteAdapter;

//

mixin \$${className}Adapter on Repository<$className> {
  @override
  CollectionSchema<$className> get schema => ${className}Schema;

  @override
  RemoteAdapter<$className> get async => ${className}RemoteAdapter(repository: this as Repository<$className>);
}

class ${className}Repository = Repository<$className> with \$${className}Adapter;

//

final ${classNameLower}RepositoryProvider =
    Provider<Repository<$className>>((ref) => ${className}Repository(ref));

extension ProviderContainer${className}X on ProviderContainer {
  Repository<$className> get $classNameLower => read(${classNameLower}RepositoryProvider);
}
''';
  }
}
