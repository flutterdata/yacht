library yacht;

import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:inflection3/inflection3.dart' as inflection;
import 'package:isar/isar.dart' hide collection;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path_helper;
import 'package:riverpod/riverpod.dart';

part 'src/data_model.dart';
part 'src/repository/remote_adapter.dart';
part 'src/repository/repository.dart';
part 'src/util/data.dart';
part 'src/util/framework.dart';
part 'src/util/notifier.dart';
