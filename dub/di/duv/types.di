// D import file generated from 'duv/types.d'
module duv.types;
enum uv_run_mode 
{
	UV_RUN_DEFAULT = 0,
	UV_RUN_ONCE,
	UV_RUN_NOWAIT,
}
struct uv_loop_t;
alias int status;
struct uv_tcp_t;
struct uv_stream_t;
struct uv_handle_t;
struct uv_check_t;
enum uv_handle_type 
{
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
	SIGNAL,
}
template uv_handle_type_enum_to_struct(uv_handle_type handleType)
{
	static if (handleType == uv_handle_type.TCP)
	{
		alias uv_tcp_t* uv_handle_type_enum_to_struct;
	}
	else
	{
		static if (handleType == uv_handle_type.CHECK)
		{
			alias uv_check_t* uv_handle_type_enum_to_struct;
		}
		else
		{
			static assert(0, "handle type is not recognized");
		}
	}
}
alias void function(uv_stream_t* stream, Object context, status st) duv_listen_callback;
class duv_listen_request
{
	public duv_listen_callback callback;

	public Object context;

}
struct duv_error
{
	int code;
	string message;
	string name;
}
struct _uv_err_t
{
	int code;
	int sys_errno_;
}
