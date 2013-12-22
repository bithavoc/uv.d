import std.stdio;
import duv.core;
import core.memory;

class listenerContext {
  public int acceptedCount; 
  public int written;
}

void doWrite(uv_stream_t* client_connection, listenerContext writeContext) {
  auto text = cast(ubyte[])"hello world";
  duv_write(client_connection, writeContext, text, function (uv_stream_t * client_connection, contextObj, status writeStatus) {
      "stuff written".writeln;
      writeStatus.check();
      listenerContext context = cast(listenerContext)contextObj;
      context.written++;
      if(context.written < 5) {
        doWrite(client_connection, context);
      }
  });
}

void main() {
  writeln("Duv TCP Server");

  uv_loop_t * loop = uv_default_loop();

  writeln("Duv loop:", loop);
  "preparing listener".writeln;

  uv_tcp_t * listener = uv_handle_alloc!(uv_handle_type.TCP);
  "initializing listener".writeln;
  uv_tcp_init(loop, listener).check();

  "binding to localhost:3000".writeln;
  duv_tcp_bind4(listener, "0.0.0.0", 3000).check();

  "listening".writeln;
  auto context = new listenerContext();
  duv_listen(cast(uv_stream_t*)listener, 1000, context, function (uv_stream_t * listener, Object contextObj, status st) {
      st.check();
      listenerContext context = cast(listenerContext)contextObj;
      context.acceptedCount++;
      "listen ready".writeln;
      uv_tcp_t * client_connection = uv_handle_alloc!(uv_handle_type.TCP);
      uv_tcp_init(uv_default_loop, client_connection).check();
      "accepting".writeln;
      uv_accept(listener, cast(uv_stream_t*)client_connection).check();
      doWrite(cast(uv_stream_t*)client_connection, context);

      duv_read_start(cast(uv_stream_t*)client_connection, context, function (uv_stream_t * client_conn, Object readContext, size_t nread, ubyte[] data) {
        writeln("Readed ", cast(string)data);
      });
  });

  auto valor = await ^ { return "Hello"; };
  writeln("valor: ", valor);

  uv_run(loop, uv_run_mode.UV_RUN_DEFAULT).check();
}
struct Await {
  T opBinary(string op, T)(T delegate() rhs) {
    static if (op == "^") return rhs();
    else static assert(0, "Operator "~op~" not implemented");
  }
}
static Await await;
