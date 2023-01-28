import 'package:riverpod/riverpod.dart';

class ValueNotifier<E> extends StateNotifier<E> {
  late Function onDispose;
  ValueNotifier(E value) : super(value);

  void updateWith(E value) => state = value;

  @override
  dispose() {
    super.dispose();
  }
}
