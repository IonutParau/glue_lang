import 'dart:convert';
import 'dart:io';

import 'values/values.dart';
import 'vm.dart';

void repl() {
  print("Glue REPL v0.0.1");
  print("Copyright (c) 2022 Parau Ionut Alexandru");
  print("License available at https://github.com/IonutParau/glue_lang/blob/main/LICENSE");
  final vm = GlueVM();
  final stack = GlueStack();
  vm.loadStandard();
  while (true) {
    stdout.write('> ');
    final code = stdin.readLineSync()!;

    final stopwatch = Stopwatch()..start();
    GlueValue res = GlueNull();
    try {
      res = vm.evaluate(code, stack);
      print("Result: ${res.asString(vm, stack)}");
    } catch (e) {
      print("Error: $e");
    }
    stopwatch.stop();

    print("Took: ${stopwatch.elapsedMilliseconds}ms");
  }
}

void main(List<String> arguments) {
  if (arguments.isEmpty) repl();

  final filename = arguments[0];

  if (filename == "parse") {
    if (arguments.length >= 2) {
      final file = File(arguments[1]);

      if (!file.existsSync()) {
        return print("Error: File \"${arguments[1]}\" does not exist");
      }

      print(
        jsonEncode(
          glueSendAsExpressionJSON(
            GlueValue.fromString(file.readAsStringSync()),
          ),
        ),
      );
    } else {
      print("Usage: glue parse <filename>");
    }
  } else {
    final file = File(filename);

    if (!file.existsSync()) {
      return print("Error: File \"$filename\" does not exist");
    }

    final vm = GlueVM();
    vm.loadStandard();
    vm.evaluate(file.readAsStringSync());
  }
}
