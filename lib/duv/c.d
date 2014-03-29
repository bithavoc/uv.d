module duv.c;

import std.c.stdlib;
import std.string;
import std.stdio;
import duv.types;
import core.memory : GC;
import core.stdc.string : strlen;

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
	return cast(uv_handle_type_enum_to_struct!(handleType)) duv__handle_alloc(handleType);
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
    delete ctx;
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

private {
  alias extern (C) void function (uv_stream_t* stream, void * context, ptrdiff_t nread, ubyte * buff_data, size_t buff_len) duv__read_cb;
  extern (C) status duv__read_start(uv_stream_t * stream, void * context, duv__read_cb read_cb);

  class duv_read_context {
    public duv_read_cb callback;
    public Object context;
  }
  extern (C) void duv__read_callback(uv_stream_t* stream, void * context, ptrdiff_t nread, ubyte * buff_data, size_t buff_len) {
    duv_read_context read_context = cast(duv_read_context)context;
    ubyte[] data = null;
    if(nread > -1) {
        data = buff_data[0..nread].dup; // duplicate the data since duv bridge function will destroy the buffer automatically
    }
    read_context.callback(stream, read_context.context, nread, data);
  }
}

alias void function(uv_stream_t* stream, Object context, ptrdiff_t nread, ubyte[] data) duv_read_cb;

status duv_read_start(uv_stream_t * stream, Object context, duv_read_cb cb) {
  duv_read_context read_context = new duv_read_context();
  read_context.callback = cb;
  read_context.context = context;
  read_context.DUV_FREEZE();
  return duv__read_start(stream, cast(void*)read_context, &duv__read_callback);
}

status duv_read_stop(uv_stream_t* stream) {
    void * readContext = null;
    status st = duv__read_stop(stream, &readContext);

    duv_read_context read_context = cast(duv_read_context)readContext;
    read_context.DUV_UNFREEZE();

    return st;
}

private {
    extern (C) status duv__read_stop(uv_stream_t* stream, void ** readContext);
    alias extern (C) void function (uv_handle_t * handle, void * context) duv__handle_close_cb;
    extern (C) void duv__handle_close(uv_handle_t * handle, void * context, duv__handle_close_cb close_cb);
    class duv_close_context {
        public duv_handle_close_cb callback;
        public Object context;
    }
    extern (C) void duv__handle_close_callback(uv_handle_t * handle, void * context) {
       duv_close_context close_context = cast(duv_close_context)context; 
       if(close_context.callback !is null) {
            close_context.callback(handle, close_context.context);
       }
       close_context.DUV_UNFREEZE();
       delete close_context;
    }
    extern (C) int uv_is_closing(uv_handle_t* handle);
    extern (C) void duv__handle_close_async(uv_handle_t * handle);
}

alias void function (uv_handle_t * handle, Object context) duv_handle_close_cb;

void duv_handle_close(uv_handle_t* handle, Object context, duv_handle_close_cb cb) {
    duv_close_context close_context  = new duv_close_context();
    close_context.context = context;
    close_context.callback = cb;
    close_context.DUV_FREEZE();
    duv__handle_close(handle, cast(void*)close_context, &duv__handle_close_callback);
}
// closes the handle without making any allocations (ideal for destructors)
void duv_handle_close_async(uv_handle_t * handle) {
    duv__handle_close_async(handle);
}

bool duv_is_closing(uv_handle_t* handle) {
    return uv_is_closing(handle) != 0;
}

private {
    extern (C) immutable (char)* uv_err_name(_uv_err_t err);
    extern (C) immutable (char)* uv_strerror(_uv_err_t err);
    extern (C) _uv_err_t uv_last_error(uv_loop_t* loop);
}

duv_error duv_last_error(status code, uv_loop_t* loop) {
    duv_error error;
    if(code < 0) {
        error.code = code;
        _uv_err_t err = uv_last_error(loop);
        error.name = std.conv.to!string(uv_err_name(err));
        error.message = std.conv.to!string(uv_strerror(err));
    }
    return error;
}

@property bool hasError(duv_error err) {
    return err.code < 0;
}

extern(C) uv_handle_t* duv__handle_alloc(uv_handle_type type);

alias void function(uv_check_t* handle, Object context, int status) duv_check_cb;
private {
    class duv_check_context {
        public duv_check_cb callback;
        public Object context;
    }
    alias extern (C) void function(uv_check_t* handle, void * context, int status) duv__check_cb;

    extern (C) status duv__check_start(uv_check_t* handle, void * context, duv__check_cb cb);

    extern (C) status duv__check_stop(uv_check_t* check);
    extern (C) void* duv__check_get_context(uv_check_t* handle);

    extern (C) void duv__check_callback(uv_check_t* handle, void * context, int status) {
        duv_check_context ctx = cast(duv_check_context)context;
        ctx.callback(handle, ctx.context, status);
    }
}

extern (C) status uv_check_init(uv_loop_t* loop, uv_check_t* handle);

status duv_check_start(uv_check_t * handle, Object context, duv_check_cb cb) {
    duv_check_context ctx = new duv_check_context;
    ctx.context = context;
    ctx.callback = cb;
    ctx.DUV_FREEZE();
    return duv__check_start(handle, cast(void*)ctx, &duv__check_callback);
}

status duv_check_stop(uv_check_t * handle) {
    void * context = duv__check_get_context(handle);
    duv_check_context ctx = cast(duv_check_context)context;
    ctx.context = null;
    ctx.callback = null;
    ctx.DUV_UNFREEZE();
    int st = duv__check_stop(handle);
    delete ctx;
    return st;
}

private {
    class duv_tcp_connect_context {
        public:
            duv_tcp_connect_callback callback;
            Object context;
    }
    alias extern(C) void function(uv_tcp_t* handle, void* context, int status) duv__tcp_connect_callback;
    extern (C) status duv__tcp_connect4(uv_tcp_t* handle, void* context, immutable(char) * ipv4, int port, duv__tcp_connect_callback cb);

    extern (C) void duv_tcp_connect_bridge_callback(uv_tcp_t* handle, void * context, int status) {
        duv_tcp_connect_context ctx = cast(duv_tcp_connect_context)context;
        if(ctx.callback !is null) {
            ctx.callback(handle, ctx.context, status);
        }
        ctx.DUV_UNFREEZE();
        delete ctx;
    }
}

alias void function(uv_tcp_t* handle, Object context, int status) duv_tcp_connect_callback;

status duv_tcp_connect4(uv_tcp_t* handle, Object context, string ipv4, int port, duv_tcp_connect_callback cb) {
    duv_tcp_connect_context ctx = new duv_tcp_connect_context;
    ctx.context = context;
    ctx.callback = cb;
    ctx.DUV_FREEZE();
    return duv__tcp_connect4(handle, cast(void*)ctx, ipv4.toStringz, port, &duv_tcp_connect_bridge_callback);
}

private {
    import std.stdint : int32_t, int16_t;
    struct sockaddr;

    struct addrinfo {
        int32_t ai_flags;           /* input flags */
        int32_t ai_family;          /* protocol family for socket */
        int32_t ai_socktype;        /* socket type */
        int32_t ai_protocol;        /* protocol for socket */
        size_t ai_addrlen;   /* length of socket-address */
        sockaddr *ai_addr; /* socket-address for socket */
        char *ai_canonname;     /* canonical name for service location */
        addrinfo *ai_next; /* pointer to next in list */
    };
    class duv__uv_getaddrinfo_context {
        public:
            Object context; 
            duv_getaddrinfo_callback callback;
            string node;
            string service;
    }

    extern (C) {

        version(Windows) {
           enum : int {
               AF_INET = 2,
               AF_INET6 = 23,
           }
        }
        version(linux) {
           enum : int {
               AF_INET = 2,
               AF_INET6 = 10,
           }
        }
        version(OSX) {
           enum : int {
               AF_INET = 2,
               AF_INET6 = 30,
           }
        }

        alias extern (C) void function(void * context, int status, addrinfo* res) duv__uv_getaddrinfo_callback;

        extern (C) int duv__uv_getaddrinfo(uv_loop_t * loop, void* context, const char * node, const char * service, duv__uv_getaddrinfo_callback cb);

        extern (C) void duv__uv_getaddrinfo_cb(void * context, int status, addrinfo* res) {
            duv__uv_getaddrinfo_context ctx = cast(duv__uv_getaddrinfo_context)context;
            if(ctx.callback !is null) {


                duv_addr[] infos;

                addrinfo * current = res;

                __gshared static const int MAX_IP_SIZE = 512;

                while(current !is null) {
                    // transform addrinfo into duv_addr
                    char ip[MAX_IP_SIZE];
                    duv_addr addr;
                    switch(current.ai_family) {
                        case AF_INET: {
                                          addr.family = duv_addr_family.INETv4;
                                          break;
                                      }
                        case AF_INET6: {
                                          addr.family = duv_addr_family.INETv6;
                                          break;
                                      }
                        default:
                                      continue; // ignore weird Address Family
                    }
                    int ip_status = duv__getaddr_ip(current, cast(char*)ip, MAX_IP_SIZE);
                    if(ip_status) continue;
                    addr.ip = cast(string)ip[0 .. strlen(ip.ptr)].dup;
                    infos ~= addr;
                    current = current.ai_next; 
                }

                ctx.callback(ctx.context, status, infos);
            }
            ctx.DUV_UNFREEZE();
            delete ctx;
        }

        int duv__getaddr_ip(addrinfo* addr, char * ip, size_t ip_len);
    }
}

alias void function(Object context, int status, duv_addr[] addresses) duv_getaddrinfo_callback;

status duv_getaddrinfo(uv_loop_t* loop, Object context, string node, string service, duv_getaddrinfo_callback cb) {
    auto ctx = new duv__uv_getaddrinfo_context;
    ctx.context = context;
    ctx.callback = cb;
    ctx.node = node;
    ctx.service = service;
    ctx.DUV_FREEZE();
    immutable(char) * nodev = null;
    if(node !is null) {
        nodev = node.toStringz;
    }
    immutable(char) * servicev = null;
    if(service !is null) {
        servicev = service.toStringz;
    }
    return duv__uv_getaddrinfo(loop, cast(void*)ctx,  nodev, servicev, &duv__uv_getaddrinfo_cb);
}

private {
    class duv_fs_open_context {
        Object context;
        duv_fs_open_callback callback;
    }
    extern (C) {
        alias void function(void * context, int status, void * fd) duv__fs_open_callback;
        status duv__fs_open(uv_loop_t* loop, void * context, const char* path,
                    int flags, int mode, duv__fs_open_callback cb);

        void duv__fs_open_bridge_callback(void * context, int status, void * fd) {
            auto ctx = cast(duv_fs_open_context)context;
            ctx.callback(ctx.context, status, fd);
            delete ctx;
        }
    }
}
alias void function(Object context, int status, void * fd) duv_fs_open_callback;


status duv_fs_open(uv_loop_t * loop, Object context, string path, duv_file_flag flags, int mode, duv_fs_open_callback cb) {
    auto ctx = new duv_fs_open_context;
    ctx.context = context;
    ctx.callback = cb;
    ctx.DUV_FREEZE();
    return duv__fs_open(loop, cast(void*)ctx, path.toStringz, flags, mode, &duv__fs_open_bridge_callback);
}

