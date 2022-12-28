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

  /// For lexical scoping
  GlueStack get linked {
    final gs = GlueStack();
    gs._stack.addAll(_stack);
    gs._cache.addAll(_cache);
    return gs;
  }

  final _cache = <String, GlueStackVar>{};

  void push(String name, GlueValue val) {
    final v = GlueStackVar(name, val);
    _stack.add(v);
    _cache[name] = v;
  }

  void set(String name, GlueValue val) {
    _cache[name]?.val = val;
  }

  void empty() {
    _stack.clear();
    _cache.clear();
  }

  GlueValue? read(String name) {
    if (_cache[name] != null) {
      return _cache[name]?.val;
    }

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
      if (args.length != 2) {
        throw "if wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final condition = args[0].toValue(vm, stack);
      final body = args[1];

      if (condition is GlueBool) {
        if (condition.b) return body.toValue(vm, stack.linked);
      }

      return GlueNull();
    });

    globals["if-else"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 3) {
        throw "if-else wasn't given 3 arguments (more specifically, was given ${args.length})";
      }

      final condition = args[0].toValue(vm, stack);
      final body = args[1];
      final fallback = args[2];

      if (condition is GlueBool) {
        if (condition.b) return body.toValue(vm, stack.linked);
      }

      return fallback.toValue(vm, stack);
    });

    globals["unless"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) {
        throw "if wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final condition = args[0].toValue(vm, stack);
      final body = args[1];

      if (condition is GlueBool) {
        if (!condition.b) return body.toValue(vm, stack.linked);
      }

      return GlueNull();
    });

    globals["+"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) {
        throw "+ wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

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
      if (args.length != 2) {
        throw "- wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueNumber(a.n - b.n);
      }

      if (a is GlueString && b is GlueString) {
        return GlueString(a.str.replaceFirst(b.str, ''));
      }

      if (a is GlueString && b is GlueRegex) {
        return GlueString(a.str.replaceFirst(b.str, ''));
      }

      if (a is GlueRegex && b is GlueRegex) {
        return GlueRegex(RegExp(a.str.pattern.replaceFirst(b.str.pattern, '')));
      }

      return args[0];
    });

    globals["*"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) {
        throw "* wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final a = args[0];
      final b = args[1];

      if (a is GlueNumber && b is GlueNumber) {
        return GlueNumber(a.n * b.n);
      }

      return args[0];
    });

    globals["/"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) {
        throw "/ wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

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

      if (a is GlueNull) {
        return GlueBool(b is GlueNull);
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
        return GlueBool(a.n < b.n);
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

      if (a is GlueNull) {
        return GlueBool(b is! GlueNull);
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

    globals["lambda"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "Lambda definitions need 2 arguments: Parameters and body.";

      final params = args[0];
      final body = args[1];

      if (params is! GlueList) throw "Parameters must be list expression.";

      final a = <String>[];

      for (var param in params.vals) {
        if (param is GlueVariable) a.add(param.varname);
      }

      return GlueFunction(a, body, stack.linked);
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

      final func = GlueFunction(a, body, stack.linked);

      stack.push(name.varname, func);

      return func;
    });

    globals["set-fn"] = GlueExternalFunction((vm, stack, args) {
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

      final func = GlueFunction(a, body, stack.linked);

      stack.set(name.varname, func);

      return func;
    });

    globals["global-fn"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 3) throw "Global Function definitions need 3 arguments: Name, parameters and body.";

      final name = args[0];
      final params = args[1];
      final body = args[2];

      if (name is! GlueVariable) throw "Global Function name must be a variable.";
      if (params is! GlueList) throw "Parameters must be list expression.";

      final a = <String>[];

      for (var param in params.vals) {
        if (param is GlueVariable) a.add(param.varname);
      }

      final func = GlueFunction(a, body, stack.linked);

      vm.globals[name.varname] = func;

      return func;
    });

    globals["macro"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "Macro definitions need 2 arguments: Name and body. (If you need arguments, for obvious reasons, use the @args variable)";

      final name = args[0];
      final body = args[1];

      if (name is! GlueVariable) throw "Macro name must be a variable.";

      final macro = GlueMacro(body, stack.linked);

      stack.push(name.varname, macro);

      return macro;
    });

    globals["set-macro"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "Macro definitions need 2 arguments: Name and body. (If you need arguments, for obvious reasons, use the @args variable)";

      final name = args[0];
      final body = args[1];

      if (name is! GlueVariable) throw "Macro name must be a variable.";

      final macro = GlueMacro(body, stack.linked);

      stack.set(name.varname, macro);

      return macro;
    });

    globals["global-macro"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "Global Macro definitions need 2 arguments: Name and body. (If you need arguments, for obvious reasons, use the @args variable)";

      final name = args[0];
      final body = args[1];

      if (name is! GlueVariable) throw "Global Macro name must be a variable.";

      final macro = GlueMacro(body, stack.linked);

      vm.globals[name.varname] = macro;

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
      args = processedArgs(stack, args);
      if (args.length != 2) throw "or wasn't given 2 arguments (more specifically, was given ${args.length})";

      final a = args[0];
      final b = args[1];

      if (a is! GlueBool) return GlueBool(false);
      if (b is! GlueBool) return GlueBool(false);

      return GlueBool(a.b || b.b);
    });

    globals["list-get"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
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
      args = processedArgs(stack, args);
      if (args.length != 3) throw "list-set wasn't given 3 arguments (more specifically, was given ${args.length})";

      final list = args[0];
      final i = args[1];
      final v = args[2];

      if (list is! GlueList) return list;
      if (i is! GlueNumber) return list;

      if (i.n.isInfinite || i.n.isNaN || i.n.isNegative) return list;

      var idx = i.n.toInt();

      final l = [...list.vals];

      while (l.length < (idx + 1)) {
        l.add(GlueNull());
      }

      l[idx] = v;

      return GlueList(l);
    });

    globals["list-size"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) throw "list-size wasn't given 1 argument (more specifically, was given ${args.length})";

      final list = args[0];

      if (list is! GlueList) return GlueNumber(0);

      return GlueNumber(list.vals.length.toDouble());
    });

    globals["list-remove-at"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "list-remove-at wasn't given 2 arguments (more specifically, was given ${args.length})";

      final list = args[0];
      final i = args[1];

      if (list is! GlueList) return list;
      if (i is! GlueNumber) return list;

      if (i.n.isInfinite || i.n.isNaN || i.n.isNegative) return list;

      final idx = i.n.toInt();
      if (idx >= list.vals.length) return list;

      final v = [...list.vals];

      v.removeAt(idx);

      return GlueList(v);
    });

    globals["table-get"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) throw "table-get wasn't given 2 arguments (more specifically, was given ${args.length})";

      final table = args[0];
      final i = args[1];

      if (table is! GlueTable) return GlueNull();

      return table.read(vm, stack, i);
    });

    globals["table-set"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 3) throw "table-set wasn't given 3 arguments (more specifically, was given ${args.length})";

      final table = args[0];
      final i = args[1];
      final v = args[2];

      if (table is! GlueTable) return GlueNull();

      return table.write(vm, stack, i, v);
    });

    globals["table-size"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
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

    globals["file-exists"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "file-exists wasn't given 1 argument (more specifically, was given ${args.length})";

      final path = glueFixPath(args[0].asString(vm, stack));

      final f = File(path);

      return GlueBool(f.existsSync());
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

    globals["delete-dir"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) throw "delete-dir wasn't given 1 argument (more specifically, was given ${args.length})";

      final p = glueFixPath(args[0].asString(vm, stack));

      final f = Directory(p);
      if (f.existsSync()) f.deleteSync();

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

    globals["set"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) throw "var wasn't given 2 arguments (more specifically, was given ${args.length})";

      final name = args[0];
      final val = args[1].toValue(vm, stack);

      if (name is GlueVariable) {
        stack.set(name.varname, val);
      }
      if (name is GlueString) {
        stack.set(name.str, val);
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
      if (args.length != 1) {
        throw "import wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      final p = glueFixPath(args[0].asString(vm, stack));

      final file = File(p);

      if (file.existsSync()) {
        return vm.evaluate(file.readAsStringSync());
      }
      return GlueNull();
    });

    globals["math-floor"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) {
        throw "math-floor wasn't given 1 argument (more specifically, was given ${args.length})";
      }

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
      if (args.length != 1) {
        throw "math-round wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      final p = args[0].toValue(vm, stack);

      if (p is GlueNumber) {
        return GlueNumber(p.n.roundToDouble());
      }
      return GlueNull();
    });

    globals["read-var"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "read-var wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      final name = args[0].asString(vm, stack);

      return stack.read(name) ?? vm.globals[name] ?? GlueNull();
    });

    globals["global"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) {
        throw "global wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final name = args[0];
      final val = args[1].toValue(vm, stack);

      if (name is! GlueVariable) throw "global must be a variable name";

      vm.globals[name.varname] = val;

      return val;
    });

    globals["for-macros"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "for-macros wasn't given 1 argument (more specifically, was given ${args.length}";
      }

      return args[0].forMacros();
    });

    globals["for-macros-unprocessed"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 1) {
        throw "for-macros-unprocessed wasn't given 1 argument (more specifically, was given ${args.length}";
      }

      return args[0].forMacros();
    });

    globals["fn-body"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "fn-body wasn't given 1 argument (more specifically, was given ${args.length}";
      }

      final fn = args[0];

      if (fn is! GlueFunction) return GlueNull();

      return fn.body.forMacros();
    });

    globals["fn-args"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "fn-body wasn't given 1 argument (more specifically, was given ${args.length}";
      }

      final fn = args[0];

      if (fn is! GlueFunction) return GlueNull();

      return GlueList(fn.args.map((a) => GlueString(a)).toList());
    });

    globals["for"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 4) {
        throw "for wasn't given 4 arguments (more specifically, was given ${args.length})";
      }

      final setup = args[0];
      final condition = args[1];
      final next = args[2];
      final body = args[3];

      GlueValue last = GlueNull();

      setup.toValue(vm, stack);
      while (true) {
        final result = condition.toValue(vm, stack);
        if (result is! GlueBool) break;
        if (!result.b) break;
        last = body.toValue(vm, stack.linked);
        next.toValue(vm, stack);
      }

      return last;
    });

    globals["while"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 2) {
        throw "while wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      GlueValue last = GlueNull();

      final condition = args[0];
      final body = args[1];

      while (true) {
        final result = condition.toValue(vm, stack.linked);
        if (result is! GlueBool) break;
        if (!result.b) break;
        last = body.toValue(vm, stack.linked);
      }

      return last;
    });

    globals["for-each"] = GlueExternalFunction((vm, stack, args) {
      if (args.length != 3) {
        throw "for-each wasn't given 3 arguments (more specifically, was given ${args.length})";
      }

      final val = args[0].toValue(vm, stack);
      final vars = args[1];

      if (val is! GlueList && val is! GlueTable) return GlueNull();
      if (vars is! GlueList) return GlueNull();

      final body = args[2];
      GlueValue last = GlueNull();

      final varNames = [];

      for (var v in vars.vals) {
        if (v is GlueVariable) {
          varNames.add(v.varname);
        }
      }

      if (varNames.length != 2) {
        throw "for-each callback must have 2 arguments (and those arguments must be variables)";
      }

      if (val is GlueList) {
        var i = 0;
        for (var v in val.vals) {
          stack.push(varNames[0], GlueNumber(i.toDouble()));
          stack.push(varNames[1], v);
          last = body.toValue(vm, stack.linked);
          i++;
        }
      } else if (val is GlueTable) {
        val.val.forEach(
          (key, value) {
            stack.push(varNames[0], key.toValue(vm, stack));
            stack.push(varNames[1], value.toValue(vm, stack));
            last = body.toValue(vm, stack);
          },
        );
      }

      return last;
    });

    globals["disassemble"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "disassemble wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      return GlueString(glueDisassemble(args[0]));
    });

    globals["disassemble-code"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "disassemble-code wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      return GlueString(glueDisassemble(GlueValue.fromMacro(args[0])));
    });

    globals["disassemble-ast"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);

      return GlueList(args.map(GlueValue.fromMacro).toList()).toValue(vm, stack);
    });

    globals["disassemble-ast-str"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);

      return GlueString(glueDisassemble(GlueList(args.map(GlueValue.fromMacro).toList())));
    });

    globals["disassemble-ast-code"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);

      return GlueList(args.map(GlueValue.fromMacro).toList());
    });

    globals["str-split"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) {
        throw "str-split wasn't given 2 arguments (more specifically, it was given ${args.length})";
      }

      final str = args[0].asString(vm, stack);
      final other = args[1];
      final sep = other is GlueRegex ? other.str : other.asString(vm, stack);

      return GlueList(str.split(sep).map((e) => GlueString(e)).toList());
    });

    globals["str-len"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "str-len wasn't given 1 argument (more specifically, it was given ${args.length})";
      }

      final str = args[0].asString(vm, stack);

      return GlueNumber(str.length.toDouble());
    });

    globals["ascii"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "ascii wasn't given 1 argument (more specifically, it was given ${args.length})";
      }

      final val = args[0];

      if (val is GlueString) {
        if (val.str.isEmpty) return GlueNull();
        return GlueNumber(val.str.codeUnits.first.toDouble());
      }

      if (val is GlueNumber) {
        if (val.n.isNaN) return GlueNull();
        if (val.n.isInfinite) return GlueNull();
        if (val.n.isNegative) return GlueNull();
        return GlueString(String.fromCharCode(val.n.toInt()));
      }

      return GlueNull();
    });

    globals["field"] = GlueMacro(GlueValue.fromString('''(if-else (= (list-size @args) 3)
    ["expression" ["var" "table-set"] [(list-get @args 0) ["string" (list-get (list-get @args 1) 1)] (list-get @args 2)]]
    ["expression" ["var" "table-get"] [(list-get @args 0) ["string" (list-get (list-get @args 1) 1)]]]
  )'''), GlueStack());

    globals["struct"] = GlueMacro(GlueValue.fromString('''(var structName (list-get @args 0))
  (var structParts (list-get @args 1))

  (var structFuncBody {})

  (var structArgs (list-get structParts 1))

  (for-each structArgs [i field] (
    (var structFuncBody (table-set structFuncBody ["string" (list-get field 1)] field))
  ))

  ["expression" ["var" "global-fn"] [structName structParts ["table" structFuncBody]]]'''), GlueStack());

    globals["str-at"] = GlueMacro(GlueValue.fromString(r'["expression" ["var" "list-get"] [["expression" ["var" "str-split"] [(list-get @args 0) ["string" ""]]] (list-get @args 1)]]'), GlueStack());

    globals["list-insert-at"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);

      if (args.length != 3) {
        throw "list-insert-at wasn't given 3 arguments (more specifically, was given ${args.length})";
      }

      final list = args[0];
      final val = args[1];
      final idx = args[2];

      if (list is! GlueList) return list;
      if (idx is! GlueNumber) return list;

      if (idx.n.isNegative) return list;
      if (idx.n.isInfinite) return list;
      if (idx.n.isNaN) return list;

      final i = idx.n.toInt();

      final l = [...list.vals];
      l.insert(i, val);

      return GlueList(l);
    });

    globals["set-field"] = GlueMacro(GlueValue.fromString('["expression" ["var" "set"] [(list-get @args 0) ["expression" ["var" "field"] @args]]]'), GlueStack());

    globals["str-trim"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) throw "str-trim wasn't given 1 argument (more specifically, was given ${args.length})";

      final str = args[0].asString(vm, stack);

      return GlueString(str.trim());
    });

    globals["str-sub"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);

      if (args.length != 3) {
        throw "str-sub wasn't given 3 arguments (more specifically, was given ${args.length})";
      }

      final str = args[0].asString(vm, stack);
      final start = args[1];
      final end = args[2];

      if (start is! GlueNumber) return GlueString(str);
      if (end is! GlueNumber) return GlueString(str);

      if (start.n.isInfinite || start.n.isNaN || start.n.isNegative) return GlueString(str);
      if (end.n.isInfinite || end.n.isNaN || end.n.isNegative) return GlueString(str);

      return GlueString(str.substring(start.n.toInt(), end.n.toInt()));
    });

    globals["inf"] = GlueNumber(double.infinity);
    globals["-inf"] = GlueNumber(double.negativeInfinity);
    globals["nan"] = GlueNumber(double.nan);

    globals["list-join"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);

      if (args.length != 2) {
        throw "list-join wasn't given 3 arguments (more specifically, was given ${args.length})";
      }

      final l = args[0];
      final sep = args[1].asString(vm, stack);

      if (l is! GlueList) return l;

      return GlueString(l.vals.join(sep));
    });

    globals["str-indexof"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);

      if (args.length != 2) {
        throw "str-indexof wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final str = args[0].asString(vm, stack);
      final rawmatch = args[1];
      final pattern = rawmatch is GlueRegex ? rawmatch.str : rawmatch.asString(vm, stack);

      return GlueNumber(str.indexOf(pattern).toDouble());
    });

    globals["math-sqrt"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);

      if (args.length != 1) {
        throw "math-sqrt wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      final n = args[0];

      if (n is! GlueNumber) return n;

      return GlueNumber(sqrt(n.n));
    });

    globals["rng-bool"] = GlueExternalFunction((vm, stack, args) {
      return GlueBool(rng.nextBool());
    });

    globals["rng-num"] = GlueExternalFunction((vm, stack, args) {
      return GlueNumber(rng.nextDouble());
    });

    globals["rng-str"] = GlueExternalFunction((vm, stack, args) {
      var s = "";
      final chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".split('');

      for (var i = 0; i < 256; i++) {
        chars.shuffle();
        s += chars.first;
      }

      return GlueString(s);
    });

    globals["start-timer"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "start-timer wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      final id = args[0].asString(vm, stack);

      timers[id]?.stop();
      timers[id] = Stopwatch()..start();

      return GlueString(id);
    });

    globals["end-timer"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "end-timer wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      final id = args[0].asString(vm, stack);

      timers[id]?.stop();

      return GlueString(id);
    });

    globals["time-of-timer"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "end-timer wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      final id = args[0].asString(vm, stack);

      return GlueNumber(timers[id]?.elapsedMilliseconds.toDouble() ?? 0);
    });

    globals["str-has"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) {
        throw "str-has wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final str = args[0].asString(vm, stack);
      final patternVal = args[1];
      final pattern = patternVal is GlueRegex ? patternVal.str : patternVal.asString(vm, stack);

      return GlueBool(pattern is String ? str.contains(pattern) : (pattern as RegExp).hasMatch(str));
    });

    globals["str-starts"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) {
        throw "str-starts wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final str = args[0].asString(vm, stack);
      final patternVal = args[1];
      final pattern = patternVal is GlueRegex ? patternVal.str : patternVal.asString(vm, stack);

      return GlueBool(str.startsWith(pattern));
    });

    globals["str-ends"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) {
        throw "str-ends wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final str = args[0].asString(vm, stack);
      final pattern = args[1].asString(vm, stack);

      return GlueBool(str.endsWith(pattern));
    });

    globals["str-replace"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 3) {
        throw "str-replace wasn't given 3 arguments (more specifically, was given ${args.length})";
      }

      final str = args[0].asString(vm, stack);
      final patternVal = args[1];
      final pattern = patternVal is GlueRegex ? patternVal.str : patternVal.asString(vm, stack);
      final replacement = args[2].asString(vm, stack);

      return GlueString(str.replaceAll(pattern, replacement));
    });

    globals["assert"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 2) {
        throw "assert wasn't given 2 arguments (more specifically, was given ${args.length})";
      }

      final condition = args[0];
      final error = args[1].asString(vm, stack);

      if (condition is! GlueBool || !condition.b) {
        throw error;
      }

      return condition;
    });

    globals["error"] = GlueExternalFunction((vm, stack, args) {
      args = processedArgs(stack, args);
      if (args.length != 1) {
        throw "error wasn't given 1 argument (more specifically, was given ${args.length})";
      }

      throw args[0].asString(vm, stack);
    });
  }

  final rng = Random();
  final timers = <String, Stopwatch>{};

  // (list-extract)
  // (list-var-extract)

  GlueValue evaluate(String str, [GlueStack? vmStack]) {
    final expr = GlueValue.fromString(str);

    final stack = vmStack ?? GlueStack();
    loadStandard();

    return expr.toValue(this, stack);
  }
}
