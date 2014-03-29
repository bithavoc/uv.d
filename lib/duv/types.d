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

struct uv_check_t;

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
    else static if( handleType == uv_handle_type.CHECK)
        alias uv_check_t * uv_handle_type_enum_to_struct;
    else
        static assert(0, "handle type is not recognized");
}



alias void function(uv_stream_t* stream, Object context,  status st) duv_listen_callback;

class duv_listen_request {
  public duv_listen_callback callback;
  public Object context;
}

//
// Errors
//


struct duv_error {
    int code;
    string message;
    string name;
}

struct _uv_err_t {
    int code;
    int sys_errno_;
};

//
// network primitives
//

enum duv_addr_family : ubyte {
    None,
    INETv4,
    INETv6
}

struct duv_addr {
    duv_addr_family family;
    string ip;
};

version( linux )
{
    enum duv_file_flag {
        O_CREAT = 0x40,
        O_RDONLY = 0x0,
        O_SYNC = 0x101000,
        O_RDWR = 0x2,
        O_TRUNC = 0x200,
        O_WRONLY = 0x1,
        O_EXCL = 0x80,
        O_APPEND = 0x400
    }
} else version ( OSX ) {
    enum duv_file_flag {
        O_CREAT = 0x0200,
        O_RDONLY = 0x0000,
        O_SYNC = 0x0080,
        O_RDWR = 0x0002,
        O_TRUNC = 0x0400,
        O_WRONLY = 0x0001,
        O_EXCL = 0x0800,
        O_APPEND = 0x0008
    }
} else version ( FreeBSD ) {
    enum duv_file_flag {
        O_CREAT = 0x0200,
        O_RDONLY = 0x0000,
        O_SYNC = 0x0080,
        O_RDWR = 0x0002,
        O_TRUNC = 0x0400,
        O_WRONLY = 0x0001,
        O_EXCL = 0x0800,
        O_APPEND = 0x0008
    }
}
else {
    static assert(false, "Unsupported platform");
}
