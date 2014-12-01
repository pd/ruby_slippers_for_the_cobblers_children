// Compile with:
//   $ haxe -main LocalVsInlineFunctions.hx -js LocalVsInlineFunctions.js

class LocalVsInlineFunctions {

  // Looks like it does generate actual local functions.
  // IDK if this is actually problematic or not,
  // maybe interpreters like v8 have figured out that they can optimize these away.
  // But generally speaking, not sure it can be relied on,
  // probably better to use inline functions.
  public function localFib(n:Int) {
    function isBase()  return n == 0 || n == 1;
    function recurse() return localFib(n-1) + localFib(n-2);
    if(isBase())
      return n;
    else
      return recurse();
  }


  // For some reason, though, even inline functions seem iffy,
  // e.g. why didn't it inline the call to `recurse`?
  //
  // Also interesting is that it leaaves the inline function as a normal
  // function, unless you compile with `-dce full`
  private inline function isBase(n)  return n == 0 || n == 1;
  private inline function recurse(n) return inlineFib(n-1) + inlineFib(n-2);
  public function inlineFib(n:Int)
    if(isBase(n))
      return n;
    else
      return recurse(n);

  // Using empty brackets for body:
  // haxe: public function new() {};
  // js:   var LocalVsInlineFunctions = function() {};
  //
  // Using null for body:
  // haxe:   public function new() null;
  // js:     var LocalVsInlineFunctions = function() { null; };
  //
  // Again, doubt it really matters, but still a little "interesting"
  // Maybe they rely on the runtimes or compilers of the target languages?
  public function new() {};

  public static function main() {
    var instance = new LocalVsInlineFunctions();
    trace(instance.inlineFib(10));
    trace(instance.localFib(10));
  }
}