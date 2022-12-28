part of glue_values;

class GlueVariable extends GlueValue {
  String varname;

  GlueVariable(this.varname);

  @override
  GlueValue toValue(GlueVM vm, GlueStack stack) {
    return (stack.read(varname) ?? vm.globals[varname] ?? GlueNull()).toValue(vm, stack);
  }

  @override
  String asString(GlueVM vm, GlueStack stack) {
    return toValue(vm, stack).asString(vm, stack);
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString('var'), GlueString(varname)]);
  }

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    return toValue(vm, stack).invoke(vm, stack, args);
  }
}
