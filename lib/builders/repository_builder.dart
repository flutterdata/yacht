import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yacht/yacht.dart';

Builder repositoryBuilder(options) =>
    SharedPartBuilder([RepositoryGenerator()], 'yacht');

class RepositoryGenerator extends GeneratorForAnnotation<DataRepository> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final className = element.name!;
    final classNameLower = className.decapitalize().pluralize();
    final classNamePlural = className.toString().pluralize();
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

    final mixins = annotation.read('adapters').listValue.map((obj) {
      final mixinType = obj.toTypeValue() as ParameterizedType;
      final args = mixinType.typeArguments;

      if (args.length > 1) {
        throw UnsupportedError(
            'LocalAdapter `$mixinType` MUST have at most one type argument (T extends DataModel<T>) is supported for $mixinType');
      }

      final mixinElement = mixinType.element as MixinElement;
      final instantiatedMixinType = mixinElement.instantiate(
        typeArguments: [
          if (args.isNotEmpty) (element as ClassElement).thisType
        ],
        nullabilitySuffix: NullabilitySuffix.none,
      );
      return instantiatedMixinType.getDisplayString(withNullability: false);
    });

    return '''
// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin \$${className}Adapter on Repository<$className> {
  @override
  CollectionSchema<$className> get schema => ${className}Schema;
}

class ${classNamePlural}Repository = Repository<$className> with \$${className}Adapter${mixins.map((e) => ', $e').join()};

//

final ${classNameLower}RepositoryProvider =
    Provider<Repository<$className>>((ref) => ${classNamePlural}Repository(ref));

extension ProviderContainer${className}X on ProviderContainer {
  Repository<$className> get $classNameLower => read(${classNameLower}RepositoryProvider);
}
''';
  }
}
