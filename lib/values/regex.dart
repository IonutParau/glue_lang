part of glue_values;

class GlueRegex extends GlueValue {
  RegExp str;

  GlueRegex(this.str);

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    return (stack.read(str.pattern) ?? vm.globals[str] ?? GlueNull()).invoke(vm, stack, args);
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("regex"), this]);
  }

  @override
  String asString(GlueVM vm, GlueStack stack) => str.pattern;
}
