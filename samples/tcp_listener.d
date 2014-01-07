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

class listenerContext {
  public int acceptedCount; 
  public int written;
  public int readCount;
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

class checkContext {
    public int checkCount;
    public ~this() {
        writeln("destroying check context");
    }
}

void main() {
  writeln("Duv TCP Server");

  uv_loop_t * loop = uv_default_loop();
  uv_check_t * countCheck = uv_handle_alloc!(uv_handle_type.CHECK);
  uv_check_init(loop, countCheck).check();
  checkContext ccontext = new checkContext;
  duv_check_start(countCheck, ccontext, (uv_check_t * handle, Object context, int status) {
          auto ctx = cast(checkContext)context;
          ctx.checkCount++;
          writeln("Tick count ", ctx.checkCount);
          if(ctx.checkCount == 4) {
            writeln("Stopping tick count");
            duv_check_stop(handle).check;
            duv_handle_close(cast(uv_handle_t*)handle, null, function (uv_handle_t * handle, closeContext) {
              "check handle was closed".writeln;
            });
          }
  });


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
      st.check(uv_default_loop);
      listenerContext context = cast(listenerContext)contextObj;
      context.acceptedCount++;
      "listen ready".writeln;
      uv_tcp_t * client_connection = uv_handle_alloc!(uv_handle_type.TCP);
      uv_tcp_init(uv_default_loop, client_connection).check(uv_default_loop);
      "accepting".writeln;
      uv_accept(listener, cast(uv_stream_t*)client_connection).check();
      doWrite(cast(uv_stream_t*)client_connection, context);

      duv_read_start(cast(uv_stream_t*)client_connection, context, function (uv_stream_t * client_conn, Object readContext, ptrdiff_t nread, ubyte[] data) {
        listenerContext context = cast(listenerContext)readContext;
        context.readCount++;
        "read nread ".writeln(nread);
        if(nread < 0 || context.readCount > 5) {
            if(nread < 0 ) {
                try {
                    check(cast(status)nread);
                }
                catch(Exception ex) {
                    "something went wrong".writeln;
                    writeln(std.string.format("Error thrown: %s", ex.msg));
                }
            }
          "stop reading".writeln;
          duv_read_stop(client_conn).check();
          duv_handle_close(cast(uv_handle_t*)client_conn, null, function (uv_handle_t * handle, closeContext) {
              "client was closed".writeln;
          });
          context.readCount = 0;
          return;
        } else {
            writeln("Readed ", cast(string)data); 
        }
      }).check;
  });

  uv_run(loop, uv_run_mode.UV_RUN_DEFAULT).check();
}
