import 'dart:io';

import 'vm.dart';

void repl() {
  print("[ Glue v0.0.1 ]");
  final vm = GlueVM();
  final stack = GlueStack();
  vm.loadStandard();
  while (true) {
    stdout.write('> ');
    final code = stdin.readLineSync()!;

    final res = vm.evaluate(code, stack);

    print("Result: ${res.asString(vm, stack)}");
  }
}

void main(List<String> arguments) {
  repl();
}
