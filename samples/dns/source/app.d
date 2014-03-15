import std.stdio;
import util;

__gshared const string domainName = "www.google.com";
void main() {
  uv_loop_t * loop = uv_default_loop();
  int status = duv_getaddrinfo(loop, null, domainName, null, (ctx, st, addresses) {
    st.check;
    writefln("Found %d addresses for %s", addresses.length, domainName);
    foreach(add; addresses) {
        switch(add.family) {
            case duv_addr_family.INETv4:
            writefln("Address IPv4 %s", add.ip); 
            break;
            case duv_addr_family.INETv6:
            writefln("Address IPv6 %s", add.ip); 
            break;
            default:
            writefln("Unknown Address!!!"); 
            break;
        }
    }
  });

  uv_run(loop, uv_run_mode.UV_RUN_DEFAULT).check();
}

