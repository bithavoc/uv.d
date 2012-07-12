import std.stdio;
import std.array;

private {
  string scopes[];
  string scopeTabs() {
    return replicate(" ", scopes.length * 2);
  }
}

void scopeTest(string name, void delegate() cb) {
  scopeWritefln("[%s]", name);
  scopes ~= name;
  cb();
  scopes.length -= 1;
}

void scopeWritefln(S...)(S args) {
  write(scopeTabs());
  writefln!S(args);
}

void runTest(string title, void delegate() cb, string file = __FILE__, size_t line = __LINE__) {
  scopeWritefln("-> %s (%s#%s)", title, file, line);
  cb();
  scopeWritefln("   OK");
}
