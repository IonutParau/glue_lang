part of glue_values;

class GlueIndex extends GlueValue {
  GlueValue owner;
  String field;

  GlueIndex(this.owner, this.field);

  @override
  String asString(GlueVM vm, GlueStack stack) {
    return '<field "$field" of <${owner.asString(vm, stack)}>>';
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("field_of"), owner, GlueString(field)]);
  }

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    return toValue(vm, stack).invoke(vm, stack, args);
  }

  @override
  GlueValue toValue(GlueVM vm, GlueStack stack) {
    final val = owner.toValue(vm, stack);

    if (val is GlueTable) {
      return val.read(vm, stack, GlueString(field));
    }

    return GlueNull();
  }
}
