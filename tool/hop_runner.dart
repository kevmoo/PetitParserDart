library hop_runner;

import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';
import '../test/all_test.dart' as test;
import '../test/dart_test.dart' as dart_test;

void main() {
  addTask('test', createUnitTestTask(test.testCore));

  addTask('test_dart', createUnitTestTask(dart_test.testDart));

  addTask('docs', createDartDocTask(_getLibs, linkApi: true));

  runHop();
}

Future<List<String>> _getLibs() {
  return new Directory('lib').list()
      .where((FileSystemEntity fse) => fse is File)
      .map((File file) => file.path)
      .toList();
}
