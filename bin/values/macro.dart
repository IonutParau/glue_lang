part of glue_values;

class GlueMacro extends GlueValue {
  GlueValue macro;

  GlueMacro(this.macro);

  // Basically: Create new variable stack, give it AST, turn it into value (so from s-expressions to final AST)
  // then return value from AST.
  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    // Push Abstract Syntax Tree
    stack.push("@args", GlueList(args.map((e) => e.forMacros()).toList()));

    // Get the new Abstract Syntax Tree
    final newAST = macro.toValue(vm, GlueStack());

    return GlueValue.fromMacro(newAST).toValue(vm, stack);
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("macro"), macro.forMacros()]);
  }

  @override
  String asString(GlueVM vm, GlueStack stack) {
    return "<macro>";
  }
}
