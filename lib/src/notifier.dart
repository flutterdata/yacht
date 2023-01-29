import 'package:riverpod/riverpod.dart';

class ValueNotifier<E> extends StateNotifier<E> {
  Function? onDispose;
  ValueNotifier(E value) : super(value);

  void updateWith(E value) => state = value;

  @override
  dispose() {
    onDispose?.call();
    super.dispose();
  }
}
