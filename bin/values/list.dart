part of glue_values;

class GlueList extends GlueValue {
  List<GlueValue> vals;

  GlueList(this.vals);

  @override
  GlueValue toValue(GlueVM vm, GlueStack stack) {
    return GlueList(vals.map((e) => e.toValue(vm, stack)).toList());
  }

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    throw "Attempt to invoke a list";
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("list"), GlueList(vals.map((e) => e.forMacros()).toList())]);
  }

  @override
  String asString(GlueVM vm, GlueStack stack) {
    return vals.map((e) => e.asString(vm, stack)).toString();
  }
}
