# yacht

If you're going down the [Isar](https://isar.dev) river on a [pod](https://riverpod.dev), you might as well go on a yacht.

## what?

Yacht wraps Isar with Riverpod in a cleaner API and seamlessly integrates remote requests and offline support.

STILL WIP!

## why?

- Better DX than pure Isar but still blazing fast
- Integrated remote requests and offline support like Flutter Data
- Low learning curve

## example

Simplified unfinished pseudo-code:

```dart
@collection
class User with DataModel<User> {
  @Index()
  @override
  final String? id;
  final String? name;
  final int? age;

  // relationships
  final hometown = IsarLink<City>();

  User({this.id, this.name, this.age});
}

// TODO initialize container

final jane = User(id: '1', name: 'Jane', age: 36).save();
assert(jane == container.users.findOne('1'));

jane.hometown.value = City(id: 'LON', name: 'London').save();
assert(jane.hometown.value!.name == 'London');

assert(jane.toJson() == {
    'id': '1',
    'firstName': 'Jane',
    'age': 36,
    'hometown': 'LON',
    });

jane.delete();
assert(jane.reload() == null);

await jane.save.remote();

await container.users.findOne.remote('1');
assert(jane.reload() != null);
```

Watchers in Flutter:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.users.watchOne('1');
  if (state.isLoading) {
    return Center(child: const CircularProgressIndicator());
  }
  final user = state.model;
  return Text(user.name); // Jane
}
```

## license

Public domain