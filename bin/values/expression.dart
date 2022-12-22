part of glue_values;

class GlueExpression extends GlueValue {
  GlueValue operation;
  List<GlueValue> args;

  GlueExpression(this.operation, this.args);

  @override
  GlueValue toValue(GlueVM vm, GlueStack stack) {
    if (operation is! GlueVariable) {
      final opr = operation.toValue(vm, stack);
      if (args.isEmpty) return opr;
      final vals = [];
      for (var arg in args) {
        vals.add(arg.toValue(vm, stack));
      }
      return vals.last;
    }

    return operation.toValue(vm, stack).invoke(vm, stack, args);
  }

  @override
  String asString(GlueVM vm, GlueStack stack) {
    return toValue(vm, stack).asString(vm, stack);
  }

  @override
  GlueValue forMacros() {
    return GlueList([
      GlueString("expression"),
      operation.forMacros(),
      GlueList(args.map((a) => a.forMacros()).toList()),
    ]);
  }

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    return toValue(vm, stack).invoke(vm, stack, args);
  }
}
