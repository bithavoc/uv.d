module duv.c;
import std.conv;
import std.c.stdlib;
import std.stdint;

alias void* uv_tcp_t_ptr;
alias void* uv_stream_t_ptr;
alias void* uv_loop_t_ptr;
alias intptr_t ssize_t;
alias int duv_status;
struct uv_connect_t;
alias uv_connect_t* uv_connect_t_ptr;
struct sockaddr_in; // IPv4
alias sockaddr_in* sockaddr_in_ptr;

//alias void* uv_connection_cb;
enum uv_handle_type {
  UNKNOWN,
  ARES_TAKS,
  ASYNC, 
  CHECK,
  FSEVENT,
  IDLE,
  NAMED_PIPE,
  PREPARE,
  PROCESS,
  TCP,
  TIMER,
  TTY,
  UDP
}

struct uv_err_t {
  int code;
  int sys_errno_;
};

string duv_strerror(uv_err_t err) {
  return std.conv.to!string(uv_strerror(err));
}

void* duv_alloc_handle(uv_handle_type type) {
  return malloc(uv_handle_size(type));
}

void duv_free_handle(void* handle) {
  free(handle);
}

alias void function(int handle, int status) listen_cb;

extern(C):
  version(Posix) {
    struct uv_buf_t  {
      ubyte* base;
      size_t len;

      public void init(size_t s) {
        base = cast(ubyte*)std.c.stdlib.malloc(s);
      }

      public void free() {
        std.c.stdlib.free(this.base);
        this.base = null;
      }
    }
  }

version(Windows) {
  static assert(false, "Oops, Duv is not supported on this platform");
  /*
     import std.stdint;
     struct uv_buf_t {
     c_ulong len;
     byte* base;
     }*/
}

alias void function(void* handle, int status) uv_connection_cb;
alias uv_buf_t function(void *handle, size_t suggested_size) uv_alloc_cb;
alias void function(void *stream, ssize_t nread, uv_buf_t buf) uv_read_cb;
alias void function(void *handle) uv_close_cb;
alias void function(uv_write_t_ptr handle, duv_status status) uv_write_cb;
alias void function(uv_connect_t_ptr handle, duv_status status) uv_connect_cb;

//struct uv_write_t;
alias void* uv_write_t_ptr;

duv_status uv_tcp_init(uv_loop_t_ptr, uv_tcp_t_ptr);
uv_loop_t_ptr uv_default_loop();
sockaddr_in_ptr duv_ip4_addr(immutable(char)* ip, int port);
duv_status duv_tcp_bind(uv_tcp_t_ptr server, sockaddr_in_ptr addr);
duv_status uv_listen(uv_stream_t_ptr stream, int backlog, uv_connection_cb on_connection);

duv_status uv_run(uv_loop_t_ptr);
duv_status uv_run_once(uv_loop_t_ptr);
void uv_ref(uv_loop_t_ptr);
uv_err_t uv_last_error(uv_loop_t_ptr);
immutable (char)* uv_strerror(uv_err_t err);
size_t uv_handle_size(uv_handle_type type);
uv_loop_t_ptr uv_loop_new();
void uv_loop_delete(uv_loop_t_ptr loop);
void duv_set_handle_data(void* handle, void* data);
void* duv_get_handle_data(void* handle);
void duv_set_request_data(void* request, void* data);
void* duv_get_request_data(void* request);
duv_status uv_accept(void* server, void*client);

duv_status uv_read_start(void* handle, uv_alloc_cb alloc_cb,
    uv_read_cb read_cb);
duv_status uv_read_stop(void* handle);
void uv_close(void* handle, uv_close_cb close_cb);

uv_buf_t duv_alloc_callback(void* handle, size_t suggested_size) {
  uv_buf_t buf;
  buf.init(suggested_size);
  buf.len = suggested_size;
  return buf;
}

uv_write_t_ptr duv_alloc_write();
duv_status uv_write(uv_write_t_ptr req, uv_stream_t_ptr handle, uv_buf_t* bufs, int bufcnt, uv_write_cb cb);

uv_connect_t_ptr duv_alloc_connect();
duv_status duv_tcp_connect(uv_connect_t_ptr req, uv_tcp_t_ptr handle, sockaddr_in_ptr address, uv_connect_cb cb);
