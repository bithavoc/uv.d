module duv.types;

//
// Loops
//

enum uv_run_mode {
  UV_RUN_DEFAULT = 0,
  UV_RUN_ONCE,
  UV_RUN_NOWAIT
};

struct uv_loop_t;


//
// General
//

alias int status;

//
// Handles
//

struct uv_tcp_t;

struct uv_stream_t;

struct uv_handle_t;

enum uv_handle_type {
  UNKNOWN,
  ASYNC, 
  CHECK,
  FS_EVENT,
  FS_POLL,
  HANDLE,
  IDLE,
  NAMED_PIPE,
  POLL,
  PREPARE,
  PROCESS,
  STREAM,
  TCP,
  TIMER,
  TTY,
  UDP,
  SIGNAL
};

template uv_handle_type_enum_to_struct(uv_handle_type handleType)
{
    static if( handleType == uv_handle_type.TCP)
        alias uv_tcp_t * uv_handle_type_enum_to_struct;
    else
		// ?
        alias uv_loop_t * uv_handle_type_enum_to_struct;
}

void check(status st) {
	if(st < 0) {
		throw new Exception("Something failed");
	}
}



alias void function(uv_stream_t* stream, Object context,  status st) duv_listen_callback;

class duv_listen_request {
  public duv_listen_callback callback;
  public Object context;
}
