part of glue_values;

class GlueString extends GlueValue {
  String str;

  GlueString(this.str);

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    return (stack.read(str) ?? vm.globals[str] ?? GlueNull()).invoke(vm, stack, args);
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("string"), this]);
  }

  @override
  String asString(GlueVM vm, GlueStack stack) => str;
}
