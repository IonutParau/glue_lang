library glue_values;

import 'dart:convert';

import '../vm.dart';

part 'null.dart';
part 'string.dart';
part 'regex.dart';
part 'number.dart';
part 'bool.dart';
part 'expression.dart';
part 'list.dart';
part 'table.dart';
part 'macro.dart';
part 'function.dart';
part 'variable.dart';

List<String> glueSeperate(String str) {
  final openers = ['(', '[', '{'];
  final closers = [')', ']', '}'];
  final seperators = ['\n', ' ', '\t'];
  var l = <String>[""];

  final chars = str.split('');
  var inString = false;
  var inRegex = false;
  var bias = 0;

  for (var char in chars) {
    if (char == '"' && !inRegex) {
      inString = !inString;
      l.last += char;
      continue;
    }
    if (char == '`' && !inString) {
      inRegex = !inRegex;
      l.last += char;
      continue;
    }

    if (openers.contains(char) && !inString && !inRegex) {
      bias++;
      l.last += char;
      continue;
    }

    if (closers.contains(char) && !inString && !inRegex) {
      bias--;
      l.last += char;
      continue;
    }

    if (seperators.contains(char) && !inString && !inRegex && bias == 0) {
      l.add("");
      continue;
    }

    l.last += char;
  }

  l = l.map((str) => str.trim()).toList();
  l.removeWhere((e) => e == "");

  return l;
}

String glueFixStr(String str) {
  var s = str;

  while (s.startsWith(' ') || s.startsWith('\n') || s.startsWith('\t')) {
    s = s.substring(1);
  }

  while (s.endsWith(' ') || s.endsWith('\n') || s.endsWith('\t')) {
    s = s.substring(0, s.length - 1);
  }

  return s.trim();
}

abstract class GlueValue {
  GlueValue toValue(GlueVM vm, GlueStack stack) => this;
  GlueValue forMacros();

  String asString(GlueVM vm, GlueStack stack);

  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args);

  static GlueValue fromMacro(GlueValue val) {
    if (val is! GlueList) return GlueNull();

    if (val.vals.isEmpty) return GlueNull();

    final typeExpr = val.vals[0];

    if (typeExpr is! GlueString) return GlueNull();

    final type = typeExpr.str;

    if (type == "null") return GlueNull();

    final justOnTheSide = ["external-function", "number", "string", "regex", "bool"];

    if (justOnTheSide.contains(type) && val.vals.length > 1) {
      return val.vals[1];
    }

    if (type == "var" && val.vals.length > 1) {
      if (val.vals[1] is! GlueString) return GlueNull();
      return GlueVariable((val.vals[1] as GlueString).str);
    }

    if (type == "expression" && val.vals.length > 2) {
      final op = GlueValue.fromMacro(val.vals[1]);
      final argsAST = val.vals[2];
      if (argsAST is! GlueList) return GlueNull();
      final args = argsAST.vals.map(GlueValue.fromMacro).toList();

      return GlueExpression(op, args);
    }

    if (type == "list" && val.vals.length > 1) {
      final list = val.vals[1];

      if (list is! GlueList) return GlueNull();

      return GlueList(list.vals.map(GlueValue.fromMacro).toList());
    }

    if (type == "table" && val.vals.length > 1) {
      final table = val.vals[1];

      if (table is! GlueTable) return GlueNull();

      return GlueTable(
        table.val.map(
          (key, value) => MapEntry(
            GlueValue.fromMacro(key),
            GlueValue.fromMacro(value),
          ),
        ),
      );
    }

    if (type == "internal-function" && val.vals.length > 2) {
      final argsAST = val.vals[1];
      final bodyAST = val.vals[2];

      if (argsAST is! GlueList) return GlueNull();

      final args = <String>[];

      for (var a in argsAST.vals) {
        if (a is GlueString) args.add(a.str);
      }

      return GlueFunction(args, GlueValue.fromMacro(bodyAST));
    }

    if (type == "macro" && val.vals.length > 1) {
      return GlueMacro(GlueValue.fromMacro(val.vals[0]));
    }

    return GlueNull();
  }

  static GlueValue fromString(String str) {
    str = glueFixStr(str);
    final parts = glueSeperate(str);
    if (parts.isEmpty) return GlueNull();
    if (parts.length > 1) return fromString('($str)');
    if (double.tryParse(str) != null) return GlueNumber(double.parse(str));
    if (str == "true" || str == "false") return GlueBool(str == "true");
    if (str.startsWith('"') && str.endsWith('"')) {
      return GlueString(str.substring(1, str.length - 1));
    }
    if (str.startsWith('`') && str.endsWith('`')) {
      return GlueRegex(RegExp(str.substring(1, str.length - 1)));
    }
    if (str.startsWith('(') && str.endsWith(')')) {
      final parts = glueSeperate(str.substring(1, str.length - 1));
      if (parts.isEmpty) return GlueNull();
      final op = GlueValue.fromString(parts.first);
      final args = parts.sublist(1).map(GlueValue.fromString).toList();

      return GlueExpression(op, args);
    }

    if (str.startsWith('[') && str.endsWith(']')) {
      final parts = glueSeperate(str.substring(1, str.length - 1));
      final elements = parts.map(GlueValue.fromString).toList();

      return GlueList(elements);
    }

    if (str.startsWith('{') && str.endsWith('}')) {
      final parts = glueSeperate(str.substring(1, str.length - 1));
      final elements = parts.map(GlueValue.fromString).toList();

      final table = <GlueValue, GlueValue>{};

      var i = 0;
      while ((i + 1) <= elements.length) {
        final key = elements[i];
        final val = elements[i + 1];

        table[key] = val;

        i += 2;
      }

      return GlueTable(table);
    }

    return GlueVariable(str);
  }
}

dynamic glueSendAsExpressionJSON(GlueValue val) {
  if (val is GlueNull) {
    return {"type": "null"};
  } else if (val is GlueBool) {
    return {"type": "bool", "val": val.b};
  } else if (val is GlueFunction) {
    return {
      "type": "function",
      "args": val.args.cast<dynamic>(),
      "body": glueSendAsExpressionJSON(val.body),
    };
  } else if (val is GlueExternalFunction) {
    return {
      "type": "external-function",
    };
  } else if (val is GlueList) {
    return {"type": "list", "vals": val.vals.map(glueSendAsExpressionJSON).toList()};
  } else if (val is GlueTable) {
    return {
      "type": "table",
      "vals": val.val.map<String, dynamic>((key, value) {
        return MapEntry(
          jsonEncode(glueSendAsExpressionJSON(key)),
          glueSendAsExpressionJSON(val),
        );
      })
    };
  } else if (val is GlueString) {
    return {
      "type": "string",
      "str": val.str,
    };
  } else if (val is GlueRegex) {
    return {
      "type": "regex",
      "str": val.str.pattern,
    };
  } else if (val is GlueMacro) {
    return {
      "type": "macro",
      "str": glueSendAsExpressionJSON(val.macro),
    };
  } else if (val is GlueNumber) {
    return {
      "type": "number",
      "str": val.n,
    };
  } else if (val is GlueExpression) {
    return {
      "type": "s-expression",
      "op": glueSendAsExpressionJSON(val.operation),
      "args": val.args.map(glueSendAsExpressionJSON).toList(),
    };
  }
}
