// Copyright (c) 2013, Lukas Renggli <renggli@gmail.com>

library dart_test;

import 'dart:io';
import 'dart:async';

import 'package:petitparser/petitparser.dart' as pp;
import 'package:petitparser/dart.dart';
import 'package:unittest/unittest.dart';

void generateTests(String title, String path) {
  group(title, () {
    new Directory(path)
      .listSync(recursive: true, followLinks: false)
      .where((file) => file is File && file.path.endsWith('.dart'))
      .forEach((file) {
        test(file.path, () {
          var result = dart.parse(file.readAsStringSync());
          if (result.isFailure) {
            fail(result.toString());
          }
        });
      });
  });
}

final dart = new DartGrammar();

void main() {
  testDart(new Configuration());
}

void testDart(Configuration config) {
  unittestConfiguration = config;
  groupSep = ' - ';

  test('basic files', () {
    expect(dart.accept('library test;'), isTrue);
    expect(dart.accept('library test; void main() { }'), isTrue);
    expect(dart.accept('library test; void main() { print(2 + 3); }'), isTrue);
  });
  test('basic whitespace', () {
    expect(dart.accept('library test;'), isTrue);
    expect(dart.accept('  library test;'), isTrue);
    expect(dart.accept('library test;  '), isTrue);
    expect(dart.accept('library  test ;'), isTrue);
  });
  test('single line comment', () {
    expect(dart.accept('library test;'), isTrue);
    expect(dart.accept('library// foo\ntest;'), isTrue);
    expect(dart.accept('library test // foo \n;'), isTrue);
    expect(dart.accept('library test; // foo'), isTrue);
  });
  test('multi line comment', () {
    expect(dart.accept('/* foo */ library test;'), isTrue);
    expect(dart.accept('library /* foo */ test;'), isTrue);
    expect(dart.accept('library test; /* foo */'), isTrue);
  });

  group('silly', _silly);

  group('sub-parser tests', () {
    final map = {
                 'NEWLINE' : {
                   '\n' : true,
                   '\r\n': true,
                   '\r': false,
                   '\t': false,
                 },
                 'stringInterpolation' : {
                   "\$cool" : true,
                   "\${nice}" : true,
                   "a string": false,
                   "\${missingCloseBracket" : false,
                 },
                 'stringContentDQ' : {
                   '"' : false,
                   r'\' : false,
                   '\$' : false,
                   '\n' : false,
                   '\r\n' : false,
                   r'\$': true,
                   'So this does work fine "foo"': false,
                   "So this does work fine 'foo'": true
                 },
                 'stringContentSQ' : {
                     'So this does work fine "foo"': true,
                     "So this does work fine 'foo'": false
                 }
    };

    map.forEach((String parserName, Map<String, bool> tests) {
      group(parserName, () {
        var parser = dart[parserName].plus().end();
        tests.forEach((String val, bool success) {
          if(success) {
            test('work on ::: ${Error.safeToString(val)}', () {
              _testParse(parser, val);
            });
          } else {
            test('fail on ::: ${Error.safeToString(val)}', () {
              var result = parser.parse(val);
              if(!result.isFailure) {
                //print(result);
                //print([result.result, result.value, result.message]);
                print(result.toPositionString());
                fail('Should have failed');
              }
            });
          }
        });
      });

    });
  });

  // generateTests('Dart SDK Sources', '/Applications/Dart/dart-sdk');
  // generateTests('PetitParser Sources', '.');
}

void _silly() {
  var backSlash = pp.char('\\');
  var doubleQuote = dart['doubleQuote'];
  var dollar = dart['dollar'];
  var NEWLINE = dart['NEWLINE']; //pp.char('\n').or(pp.string('\r\n'));

  var first = (backSlash | doubleQuote | dollar | NEWLINE).not();

  test('first', () {
    expect(first.accept('\\'), isFalse);
    expect(first.accept('"'), isFalse);
    expect(first.accept('\$'), isFalse);
    expect(first.accept('\n'), isFalse);
    expect(first.accept('\r\n'), isFalse);
  });

  var second = backSlash & NEWLINE.not();
  test('second', () {
    expect(second.accept(r'\\'), isTrue);
    expect(second.accept(r'\t'), isTrue);
    var foo = '\\\n';
    print(Error.safeToString(foo));
    expect(second.accept(foo), isFalse);
  });

  var oneAndTwo = (first | second).plus().end();
  test('third', () {
    var foo = '\\\n';
    print(Error.safeToString(foo));
    expect(oneAndTwo.accept(r'\\'), isTrue);
    expect(oneAndTwo.accept(r'\t'), isTrue);
    var foo = '\\\n';
    print(Error.safeToString(foo));
    expect(oneAndTwo.accept(foo), isFalse);
  });


  /*

  stringContentDQ = (backSlash | doubleQuote | dollar | NEWLINE).not() |
      backSlash & NEWLINE.not() |
      stringInterpolation;
      */

}

void _testParse(pp.Parser parser, String input) {
  var result = parser.parse(input);
  if(result.isFailure) {
    fail(result.toString());
  }
}
