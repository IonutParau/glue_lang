part of glue_values;

class GlueBool extends GlueValue {
  bool b;

  GlueBool(this.b);

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    throw "Attempt to invoke a bool";
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("bool"), this]);
  }

  @override
  String asString(GlueVM vm, GlueStack stack) => '$b';
}
