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
    ClassElement classElement = element as ClassElement;

    final mixins = annotation.read('adapters').listValue.map((obj) {
      final mixinType = obj.toTypeValue() as ParameterizedType;
      final args = mixinType.typeArguments;

      if (args.length > 1) {
        throw UnsupportedError(
            'LocalAdapter `$mixinType` MUST have at most one type argument (T extends DataModel<T>) is supported for $mixinType');
      }

      final mixinElement = mixinType.element as MixinElement;
      final instantiatedMixinType = mixinElement.instantiate(
        typeArguments: [if (args.isNotEmpty) element.thisType],
        nullabilitySuffix: NullabilitySuffix.none,
      );
      return instantiatedMixinType.getDisplayString(withNullability: false);
    });

    // relationship-related

    final relationships = classElement.relationshipFields
        .fold<Set<Map<String, String?>>>({}, (result, field) {
      final relationshipClassElement = field.typeElement;

      final relationshipAnnotation = TypeChecker.fromRuntime(DataRelationship)
          .firstAnnotationOfExact(field, throwOnUnresolved: false);
      final jsonKeyAnnotation = TypeChecker.fromUrl(
              'package:json_annotation/json_annotation.dart#JsonKey')
          .firstAnnotationOfExact(field, throwOnUnresolved: false);

      final jsonKeyIgnored =
          jsonKeyAnnotation?.getField('ignore')?.toBoolValue() ?? false;

      if (jsonKeyIgnored) {
        throw UnsupportedError('''
@JsonKey(ignore: true) is not allowed in Flutter Data relationships.

Please use @DataRelationship(serialized: false) to prevent it from
serializing and deserializing.
''');
      }

      // define inverse

      var inverse =
          relationshipAnnotation?.getField('inverse')?.toStringValue();

      if (inverse == null) {
        final possibleInverseElements =
            relationshipClassElement.relationshipFields.where((elem) {
          return (elem.type as ParameterizedType)
                  .typeArguments
                  .single
                  .element ==
              classElement;
        });

        if (possibleInverseElements.length > 1) {
          throw UnsupportedError('''
Too many possible inverses for relationship `${field.name}`
of type $className: ${possibleInverseElements.map((e) => e.name).join(', ')}

Please specify the correct inverse in the $className class, for example:

@DataRelationship(inverse: '${possibleInverseElements.first.name}')
final BelongsTo<${relationshipClassElement.name}> ${field.name};

and execute a code generation build again.
''');
        } else if (possibleInverseElements.length == 1) {
          inverse = possibleInverseElements.single.name;
        }
      }

      // prepare metadata

      result.add({
        'key': field.name,
        'name': field.name,
        'inverseName': inverse,
        'type': relationshipClassElement.name,
      });

      return result;
    }).toList();

    final relationshipMeta = {
      for (final rel in relationships)
        '\'${rel['key']}\'': '''RelationshipMeta<${rel['type']}>(
            name: '${rel['name']}',
            ${rel['inverseName'] != null ? 'inverseName: \'${rel['inverseName']}\',' : ''}
            type: '${rel['type']}',
            instance: (_) => (_ as $className).${rel['name']},
          )''',
    };

    return '''
// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin \$${className}Adapter on Repository<$className> {
  @override
  CollectionSchema<$className> get schema => ${className}Schema;

  static final Map<String, RelationshipMeta> _k${className}RelationshipMetas = 
    $relationshipMeta;

  @override
  Map<String, RelationshipMeta> get relationshipMetas => _k${className}RelationshipMetas;
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

// extensions

final relationshipTypeChecker = TypeChecker.fromRuntime(Relationship);
final dataModelTypeChecker = TypeChecker.fromRuntime(DataModel);

extension ClassElementX on ClassElement {
  // unique collection of constructor arguments and fields
  Iterable<VariableElement> get relationshipFields {
    Map<String, VariableElement> map;

    map = {
      for (final field in fields)
        if (field.type.element is ClassElement &&
            field.isPublic &&
            (field.type.element as ClassElement).supertype != null &&
            relationshipTypeChecker.isSuperOf(field.type.element!))
          field.name: field,
    };

    return map.values.toList();
  }
}

extension VariableElementX on VariableElement {
  ClassElement get typeElement =>
      (type as ParameterizedType).typeArguments.single.element as ClassElement;
}
