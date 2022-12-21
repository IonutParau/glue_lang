import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;

import 'values/values.dart';

class GlueStackVar {
  String name;
  GlueValue val;

  GlueStackVar(this.name, this.val);
}

class GlueStack {
  final List<GlueStackVar> _stack = [];

  void push(String name, GlueValue val) {
    _stack.add(GlueStackVar(name, val));
  }

  void empty() {
    _stack.clear();
  }

  GlueValue? read(String name) {
    var i = _stack.length - 1;

    while (i >= 0) {
      if (_stack[i].name == name) return _stack[i].val;
      i--;
    }

    return null;
  }

  GlueValue? operator [](String name) {
    return read(name);
  }

  void operator []=(String name, GlueValue val) {
    return push(name, val);
  }
}

String glueFixPath(String p) {
  return path.joinAll(p.split('/'));
}

class GlueVM {
  final Map<String, GlueValue> globals = {};

  List<GlueValue> processedArgs(GlueStack stack, List<GlueValue> args) {
    return args.map((e) => e.toValue(this, stack)).toList();
  }

  void loadStandard() {
    globals["print"] = GlueExternalFunction((vm, stack, args) {
      for (var arg in args) {
        print(arg.toValue(vm, stack).asString(vm, stack));
      }
      return GlueNull();
    });

    globals["write"] = GlueExternalFunction((vm, stack, args) {
      stdout.writeAll(args.map((arg) => arg.toValue(vm, stack).asString(vm, stack)).toList(), ' ');
      return GlueNull();
    });

    globals["read"] = GlueExternalFunction((vm, stack, args) {
      return GlueString(stdin.readLineSync()!);
    });

    globals["exit"] = GlueExternalFunction((vm, stack, args) {
      exit(0);
    });

    globals["if"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "if wasn't given 2 arguments (more specifically, was given ${args.length})";

      final condition = args[0].toValue(vm, stack);
      final body = args[1];

      if (condition is GlueBool) {
        if (condition.b) return body.toValue(vm, stack);
      }

      return GlueNull();
    });

    globals["if-else"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 3) throw "if-else wasn't given 3 arguments (more specifically, was given ${args.length})";

      final condition = args[0].toValue(vm, stack);
      final body = args[1];
      final fallback = args[2];

      if (condition is GlueBool) {
        if (condition.b) return body.toValue(vm, stack);
      }

      return fallback.toValue(vm, stack);
    });

    globals["unless"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "if wasn't given 2 arguments (more specifically, was given ${args.length})";

      final condition = args[0].toValue(vm, stack);
      final body = args[1];

      if (condition is GlueBool) {
        if (!condition.b) return body.toValue(vm, stack);
      }

      return GlueNull();
    });

    globals["+"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "+ wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueNumber(a.n + b.n);
      }

      if (a is GlueString && b is GlueString) {
        return GlueString(a.str + b.str);
      }

      if (a is GlueRegex && b is GlueRegex) {
        return GlueRegex(RegExp(a.str.pattern + b.str.pattern));
      }

      if (a is GlueList && b is GlueList) {
        return GlueList([...a.vals, ...b.vals]);
      }

      if (a is GlueTable && b is GlueTable) {
        return GlueTable({...a.val, ...b.val});
      }

      return args[0];
    });

    globals["-"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "- wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueNumber(a.n - b.n);
      }

      if (a is GlueString && b is GlueString) {
        return GlueString(a.str.replaceFirst(b.str, ''));
      }

      if (a is GlueRegex && b is GlueRegex) {
        return GlueRegex(RegExp(a.str.pattern.replaceFirst(b.str.pattern, '')));
      }

      return args[0];
    });

    globals["*"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "* wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueNumber(a.n * b.n);
      }

      return args[0];
    });

    globals["/"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "/ wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        if (b.n == 0) {
          if (a.n == 0) return GlueNumber(double.nan);
          if (a.n > 0) return GlueNumber(double.infinity);
          if (a.n < 0) return GlueNumber(double.negativeInfinity);
        }

        return GlueNumber(a.n / b.n);
      }

      return args[0];
    });

    globals["%"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "% wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        if (b.n == 0) {
          if (a.n == 0) return GlueNumber(double.nan);
          if (a.n > 0) return GlueNumber(double.infinity);
          if (a.n < 0) return GlueNumber(double.negativeInfinity);
        }

        return GlueNumber(a.n % b.n);
      }

      return args[0];
    });

    globals["^"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "^ wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueNumber(pow(a.n, b.n).toDouble());
      }

      return args[0];
    });

    globals["="] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "= wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueBool && b is GlueBool) {
        return GlueBool(a.b == b.b);
      }

      if (a is GlueNumber && b is GlueNumber) {
        return GlueBool(a.n == b.n);
      }

      if (a is GlueString && b is GlueString) {
        return GlueBool(a.str == b.str);
      }

      if (a is GlueRegex && b is GlueRegex) {
        return GlueBool(a.str == b.str);
      }

      if (a is GlueString && b is GlueRegex) {
        return GlueBool(b.str.hasMatch(a.str));
      }

      return GlueBool(a == b);
    });

    globals[">"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "> wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueBool(a.n > b.n);
      }

      return GlueBool(false);
    });

    globals["<"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "< wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueBool(a.n > b.n);
      }

      return GlueBool(false);
    });

    globals[">="] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw ">= wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueBool(a.n >= b.n);
      }

      return GlueBool(false);
    });

    globals["<="] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "<= wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueBool(a.n <= b.n);
      }

      return GlueBool(false);
    });

    globals["!="] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "!= wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is GlueBool && b is GlueBool) {
        return GlueBool(a.b != b.b);
      }

      if (a is GlueNumber && b is GlueNumber) {
        return GlueBool(a.n != b.n);
      }

      if (a is GlueString && b is GlueString) {
        return GlueBool(a.str != b.str);
      }

      if (a is GlueRegex && b is GlueRegex) {
        return GlueBool(a.str.pattern != b.str.pattern);
      }

      if (a is GlueString && b is GlueRegex) {
        return GlueBool(!b.str.hasMatch(a.str));
      }

      return GlueBool(false);
    });

    globals["!"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) throw "! wasn't given 1 argument (more specifically, was given ${args.length})";

      final a = args[0];

      if (a is GlueBool) {
        return GlueBool(!a.b);
      }

      return GlueBool(false);
    });

    globals["fn"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 3) throw "Function definitions need 3 arguments: Name, parameters and body.";

      final name = args[0];
      final params = args[1];
      final body = args[2];

      if (name is! GlueVariable) throw "Function name must be a variable.";
      if (params is! GlueList) throw "Parameters must be list expression.";

      final a = <String>[];

      for (var param in params.vals) {
        if (param is GlueVariable) a.add(param.varname);
      }

      final func = GlueFunction(a, body);

      stack.push(name.varname, func);

      return func;
    });

    globals["macro"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "Macro definitions need 2 arguments: Name and body. (If you need arguments, for obvious reasons, use the @args variable)";

      final name = args[0];
      final body = args[1];

      if (name is! GlueVariable) throw "Macro name must be a variable.";

      final macro = GlueMacro(body);

      stack.push(name.varname, macro);

      return macro;
    });

    globals["and"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "and wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is! GlueBool) return GlueBool(false);
      if (b is! GlueBool) return GlueBool(false);

      return GlueBool(a.b && b.b);
    });

    globals["or"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "or wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is! GlueBool) return GlueBool(false);
      if (b is! GlueBool) return GlueBool(false);

      return GlueBool(a.b || b.b);
    });

    globals["list-get"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "list-get wasn't given 2 arguments (more specifically, was given ${args.length})";

      final list = args[0];
      final i = args[1];

      if (list is! GlueList) return GlueNull();
      if (i is! GlueNumber) return GlueNull();

      if (i.n.isInfinite || i.n.isNaN || i.n.isNegative) return GlueNull();

      var idx = i.n.toInt();

      if (idx >= list.vals.length) return GlueNull();

      return list.vals[idx];
    });

    globals["list-set"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 3) throw "list-set wasn't given 3 arguments (more specifically, was given ${args.length})";

      final list = args[0];
      final i = args[1];
      final v = args[2];

      if (list is! GlueList) return GlueNull();
      if (i is! GlueNumber) return GlueNull();

      if (i.n.isInfinite || i.n.isNaN || i.n.isNegative) return GlueNull();

      var idx = i.n.toInt();

      if (idx >= list.vals.length) return GlueNull();

      final l = [...list.vals];
      l[idx] = v;

      return GlueList(l);
    });

    globals["list-size"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "list-size wasn't given 1 argument (more specifically, was given ${args.length})";

      final list = args[0];

      if (list is! GlueList) return GlueNumber(0);

      return GlueNumber(list.vals.length.toDouble());
    });

    globals["table-get"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "list-get wasn't given 2 arguments (more specifically, was given ${args.length})";

      final table = args[0];
      final i = args[1];

      if (table is! GlueTable) return GlueNull();

      return table.read(vm, i);
    });

    globals["table-set"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 3) throw "table-set wasn't given 3 arguments (more specifically, was given ${args.length})";

      final table = args[0];
      final i = args[1];
      final v = args[2];

      if (table is! GlueTable) return GlueNull();

      return table.write(vm, i, v);
    });

    globals["table-size"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "table-size wasn't given 1 argument (more specifically, was given ${args.length})";

      final table = args[0];

      if (table is! GlueTable) return GlueNumber(0);

      return GlueNumber(table.val.length.toDouble());
    });

    globals["read-file"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "read-file wasn't given 1 argument (more specifically, was given ${args.length})";

      final path = glueFixPath(args[0].asString(vm, stack));

      var content = "";

      final f = File(path);
      if (f.existsSync()) content = f.readAsStringSync();

      return GlueString(content);
    });

    globals["write-file"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "write-file wasn't given 2 arguments (more specifically, was given ${args.length})";

      final path = glueFixPath(args[0].asString(vm, stack));
      final content = args[1].asString(vm, stack);

      final f = File(path);
      if (f.existsSync()) f.writeAsStringSync(content);

      return GlueNull();
    });

    globals["create-file"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "create-file wasn't given 1 argument (more specifically, was given ${args.length})";

      final path = glueFixPath(args[0].asString(vm, stack));

      final f = File(path);
      f.createSync();

      return GlueNull();
    });

    globals["delete-file"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "delete-file wasn't given 1 argument (more specifically, was given ${args.length})";

      final path = glueFixPath(args[0].asString(vm, stack));

      final f = File(path);
      if (f.existsSync()) f.deleteSync();

      return GlueNull();
    });

    globals["list-dir"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "list-dir wasn't given 1 argument (more specifically, was given ${args.length})";

      final p = glueFixPath(args[0].asString(vm, stack));

      final f = Directory(p);
      if (f.existsSync()) {
        return GlueList(
          f
              .listSync()
              .map(
                (e) => GlueString(
                  e.path.split(path.separator).join('/'),
                ),
              )
              .toList(),
        );
      }

      return GlueList([]);
    });

    globals["create-dir"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "create-dir wasn't given 1 argument (more specifically, was given ${args.length})";

      final p = glueFixPath(args[0].asString(vm, stack));

      final f = Directory(p);
      f.createSync();

      return GlueNull();
    });

    globals["eval"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "eval wasn't given 1 argument (more specifically, was given ${args.length})";

      final code = args[0].asString(vm, stack);

      return vm.evaluate(code);
    });

    globals["var"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "var wasn't given 2 arguments (more specifically, was given ${args.length})";

      final name = args[0];
      final val = args[1].toValue(vm, stack);

      if (name is GlueVariable) {
        stack.push(name.varname, val);
      }
      if (name is GlueString) {
        stack.push(name.str, val);
      }

      return val;
    });

    globals["typeof"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "typeof wasn't given 1 argument (more specifically, was given ${args.length})";

      final val = args.first.toValue(vm, stack);

      if (val is GlueNull) {
        return GlueString("null");
      }

      if (val is GlueNumber) {
        return GlueString("number");
      }

      if (val is GlueString) {
        return GlueString("string");
      }

      if (val is GlueList) {
        return GlueString("list");
      }

      if (val is GlueTable) {
        return GlueString("table");
      }

      if (val is GlueFunction) {
        return GlueString("function");
      }

      if (val is GlueExternalFunction) {
        return GlueString("function");
      }

      if (val is GlueMacro) {
        return GlueString("macro");
      }

      return GlueString("unknown");
    });

    globals["tostring"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "tostring wasn't given 1 argument (more specifically, was given ${args.length})";

      return GlueString(args[0].asString(vm, stack));
    });

    globals["tonumber"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "tonumber wasn't given 1 argument (more specifically, was given ${args.length})";

      final str = args[0].asString(vm, stack);

      final n = double.tryParse(str);

      return n == null ? GlueNull() : GlueNumber(n);
    });

    globals["import"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "import wasn't given 1 argument (more specifically, was given ${args.length})";

      final p = glueFixPath(args[0].asString(vm, stack));

      final file = File(p);

      if (file.existsSync()) {
        return vm.evaluate(file.readAsStringSync());
      }
      return GlueNull();
    });

    globals["math-floor"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "math-floor wasn't given 1 argument (more specifically, was given ${args.length})";

      final p = args[0].toValue(vm, stack);

      if (p is GlueNumber) {
        return GlueNumber(p.n.floorToDouble());
      }
      return GlueNull();
    });

    globals["math-ceil"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "math-ceil wasn't given 1 argument (more specifically, was given ${args.length})";

      final p = args[0].toValue(vm, stack);

      if (p is GlueNumber) {
        return GlueNumber(p.n.ceilToDouble());
      }
      return GlueNull();
    });

    globals["math-round"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "math-round wasn't given 1 argument (more specifically, was given ${args.length})";

      final p = args[0].toValue(vm, stack);

      if (p is GlueNumber) {
        return GlueNumber(p.n.roundToDouble());
      }
      return GlueNull();
    });
  }

  GlueValue evaluate(String str, [GlueStack? vmStack]) {
    final expr = GlueValue.fromString(str);

    final stack = vmStack ?? GlueStack();
    if (vmStack == null) loadStandard();

    return expr.toValue(this, stack);
  }
}
