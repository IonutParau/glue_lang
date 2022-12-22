part of glue_values;

class GlueNumber extends GlueValue {
  double n;

  GlueNumber(this.n);

  @override
  GlueValue invoke(GlueVM vm, GlueStack stack, List<GlueValue> args) {
    throw "Attempt to invoke a number";
  }

  @override
  GlueValue forMacros() {
    return GlueList([GlueString("number"), this]);
  }

  @override
  String asString(GlueVM vm, GlueStack stack) {
    var str = '$n';

    while (str.endsWith('.0')) {
      str = str.substring(0, str.length - 2);
    }

    return str;
  }
}
