part of glue_values;

class GlueFunction extends GlueValue {
  List<String> args;
  GlueValue body;
  GlueStack stack;

  GlueFunction(this.args, this.body, this.stack);

  @override
  String asString(GlueVM vm, GlueStack stack) {
    return "<function>";
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("internal-function"), GlueList(args.map((a) => GlueString(a)).toList()), body.forMacros()]);
  }

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    args = processedArgs(vm, stack, args);

    // Local stack
    final lstack = stack.linked;

    lstack.push("\$self", this);

    // Push args
    for (var i = 0; i < this.args.length; i++) {
      final name = this.args[i];
      final val = (args.length > i) ? args[i] : GlueNull();

      lstack.push(name, val);
    }

    // Return value of body
    return body.toValue(vm, lstack);
  }

  List<GlueValue> processedArgs(GlueVM vm, GlueStack stack, List<GlueValue> args) => args.map((e) => e.toValue(vm, stack)).toList();
}

class GlueExternalFunction extends GlueValue {
  GlueValue Function(GlueVM vm, GlueStack stack, List<GlueValue> args) fn;

  GlueExternalFunction(this.fn);

  @override
  String asString(GlueVM vm, GlueStack stack) {
    return "<function>";
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("external-function"), this]);
  }

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    return fn(vm, stack, args);
  }
}
