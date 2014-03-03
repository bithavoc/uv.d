import std.stdio;
import util;

__gshared const string domainName = "www.google.com";
void main() {
  uv_loop_t * loop = uv_default_loop();
  int status = duv_getaddrinfo(loop, null, domainName, null, (ctx, st, addresses) {
    st.check;
    writefln("Found %d addresses for %s", addresses.length, domainName);
    foreach(add; addresses) {
        writefln("Address %s", add.address.toAddrString()); 
    }
  });

  uv_run(loop, uv_run_mode.UV_RUN_DEFAULT).check();
}

