part of glue_values;

class GlueTable extends GlueValue {
  Map<GlueValue, GlueValue> val;

  GlueTable(this.val);

  @override
  GlueValue toValue(GlueVM vm, GlueStack stack) {
    return GlueTable(
      val.map(
        (key, val) => MapEntry(
          key.toValue(vm, stack),
          val.toValue(vm, stack),
        ),
      ),
    );
  }

  GlueValue read(GlueVM vm, GlueValue field) {
    final pairs = val.entries.toList();

    for (var pair in pairs) {
      final key = pair.key;
      final value = pair.value;

      if (key.asString(vm, GlueStack()) == field.asString(vm, GlueStack())) {
        return value;
      }
    }

    return GlueNull();
  }

  GlueTable write(GlueVM vm, GlueValue field, GlueValue value) {
    final table = GlueTable({...val});
    final pairs = val.entries.toList();

    for (var pair in pairs) {
      final key = pair.key;

      if (key.asString(vm, GlueStack()) == field.asString(vm, GlueStack())) {
        table.val[key] = value;
        break;
      }
    }

    return table;
  }

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    throw "Attempt to invoke a table";
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("table"), GlueTable(val.map((key, value) => MapEntry(key.forMacros(), value.forMacros())))]);
  }

  @override
  String asString(GlueVM vm, GlueStack stack) {
    return val.map((key, value) {
      return MapEntry(key.asString(vm, stack), value.asString(vm, stack));
    }).toString();
  }
}
