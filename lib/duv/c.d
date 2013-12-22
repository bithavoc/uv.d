module duv.c;

import std.c.stdlib;
import std.string;
import duv.types;
import core.memory;

void DUV_FREEZE(Object obj) {
	DUV_FREEZE_PTR(cast(void*)obj);
}
void DUV_FREEZE_PTR(void * obj) {
	GC.addRoot(obj);
	GC.setAttr(obj, GC.BlkAttr.NO_MOVE);
}
void DUV_UNFREEZE(Object obj) {
	DUV_UNFREEZE_PTR(cast(void*)obj);
}
void DUV_UNFREEZE_PTR(void * obj) {
	GC.removeRoot(obj);
	GC.clrAttr(obj, GC.BlkAttr.NO_MOVE);
}

//
// loops
//
extern(C) uv_loop_t * uv_default_loop();

extern(C) status uv_run(uv_loop_t* loop, uv_run_mode mode);

//
//  handles
//
extern(C) size_t uv_handle_size(uv_handle_type type);

extern(C) status uv_tcp_init(uv_loop_t* loop, uv_tcp_t* handle);

uv_handle_type_enum_to_struct!(handleType) uv_handle_alloc(uv_handle_type handleType)() {
	return cast(uv_handle_type_enum_to_struct!(handleType)) malloc(uv_handle_size(handleType));
}

extern (C) void duv_set_handle_data(void* handle, void* data);
extern (C) void* duv_get_handle_data(void* handle);

extern (C) status duv_tcp_bind4(uv_tcp_t *handle,  immutable(char)* ipv4, int port);

// streams
private {

  alias extern (C) void function(uv_stream_t* stream, int status) _uv_connection_cb;
  extern (C) status uv_listen(uv_stream_t* stream, int backlog, _uv_connection_cb cb);

  extern (C) void _duv_on_stream_connect_callback(uv_stream_t* stream, status status) {
      void* request_ptr  = duv_get_handle_data(stream);

      // cast back the request object
      duv_listen_request request = cast(duv_listen_request)request_ptr;

      // allow the GC do other stuff
      request.callback(stream, request.context,  status);
  }

}

status duv_listen(uv_stream_t* stream, int backlog, Object context, duv_listen_callback callback) {
  duv_listen_request request = new duv_listen_request();
  request.callback = callback;
  request.context = context;
  request.DUV_FREEZE(); //TODO: call DUV_UNFREEZE in some kind of duv_listen_stop ?
  duv_set_handle_data(stream, cast(void*)request); //TODO: Make sure no other operation in the stream overrides the listen_request
  return uv_listen(stream, backlog, &_duv_on_stream_connect_callback);
}

extern(C) status uv_accept(uv_stream_t* server, uv_stream_t* client);

alias void function (uv_stream_t * connection, Object context, status st) duv_write_callback;

private {
  alias extern(C)  void function (uv_stream_t * connection, void * context, status st) duv__write_cb;
  extern(C) status duv__write(uv_stream_t* handle,  void * context, ubyte * data, int data_len,  duv__write_cb cb);

  class duv_write_context {
    public Object context;
    public duv_write_callback callback;
    public ubyte[] data;
  }
  extern (C) void _duv_write_callback (uv_stream_t * connection,  void * context, status st) {
    duv_write_context ctx = cast(duv_write_context)context;
    ctx.DUV_UNFREEZE();
    ctx.callback(connection, ctx.context, st);
  }
}

status duv_write(uv_stream_t* handle, Object context, ubyte[] data, duv_write_callback callback) {
  duv_write_context ctx = new duv_write_context();
  ctx.context = context;
  ctx.callback = callback;
  ctx.data = data;
  ctx.DUV_FREEZE();
  return duv__write(handle, cast(void*)ctx, data.ptr, cast(int)data.length, &_duv_write_callback);
}



