import std.stdio;
import duv.types;
import duv.c;
import core.memory;


void check(status st, uv_loop_t* loop = uv_default_loop) {
	if(st < 0) {
        duv_error error = duv_last_error(st, loop);
		throw new Exception(std.string.format("%s: %s", error.name, error.message));
	}
}

class clientContext {

}

void main() {
  writeln("Duv TCP Listener");

  uv_loop_t * loop = uv_default_loop();

  "creating client".writeln;
  uv_tcp_t * client = uv_handle_alloc!(uv_handle_type.TCP);
  uv_tcp_init(loop, client).check();
  clientContext context = new clientContext;
  duv_tcp_connect4(client, context, "0.0.0.0", 3000, function(uv_tcp_t* client, Object context, int st)   {
          st.check;
          "connected to server".writeln;
          duv_write(cast(uv_stream_t*)client, null, cast(ubyte[])"hello world\r\n", function (uv_stream_t * client_connection, contextObj, status writeStatus) {
              writeStatus.check();
              "stuff written".writeln;
          });
  });


  uv_run(loop, uv_run_mode.UV_RUN_DEFAULT).check();
}
