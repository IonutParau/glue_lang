part of glue_values;

class GlueNull extends GlueValue {
  @override
  GlueValue forMacros() {
    return GlueList([GlueString("null")]);
  }

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    throw "Attempt to invoke null";
  }

  @override
  String asString(GlueVM vm, GlueStack stack) {
    return "null";
  }
}
