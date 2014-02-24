// D import file generated from 'duv/c.d'
module duv.c;
import std.c.stdlib;
import std.string;
import std.stdio;
import duv.types;
import core.memory : GC;
void DUV_FREEZE(Object obj)
{
	DUV_FREEZE_PTR(cast(void*)obj);
}

void DUV_FREEZE_PTR(void* obj)
{
	GC.addRoot(obj);
	GC.setAttr(obj, GC.BlkAttr.NO_MOVE);
}

void DUV_UNFREEZE(Object obj)
{
	DUV_UNFREEZE_PTR(cast(void*)obj);
}

void DUV_UNFREEZE_PTR(void* obj)
{
	GC.removeRoot(obj);
	GC.clrAttr(obj, GC.BlkAttr.NO_MOVE);
}

extern (C) uv_loop_t* uv_default_loop();


extern (C) status uv_run(uv_loop_t* loop, uv_run_mode mode);


extern (C) size_t uv_handle_size(uv_handle_type type);


extern (C) status uv_tcp_init(uv_loop_t* loop, uv_tcp_t* handle);


template uv_handle_alloc(uv_handle_type handleType)
{
	uv_handle_type_enum_to_struct!handleType uv_handle_alloc()
	{
		return cast(uv_handle_type_enum_to_struct!handleType)duv__handle_alloc(handleType);
	}

}
extern (C) void duv_set_handle_data(void* handle, void* data);


extern (C) void* duv_get_handle_data(void* handle);


extern (C) status duv_tcp_bind4(uv_tcp_t* handle, immutable(char)* ipv4, int port);


private 
{
	extern (C) alias void function(uv_stream_t* stream, int status) _uv_connection_cb;

	extern (C) status uv_listen(uv_stream_t* stream, int backlog, _uv_connection_cb cb);


	extern (C) void _duv_on_stream_connect_callback(uv_stream_t* stream, status status)
	{
		void* request_ptr = duv_get_handle_data(stream);
		duv_listen_request request = cast(duv_listen_request)request_ptr;
		request.callback(stream, request.context, status);
	}


}
status duv_listen(uv_stream_t* stream, int backlog, Object context, duv_listen_callback callback)
{
	duv_listen_request request = new duv_listen_request;
	request.callback = callback;
	request.context = context;
	request.DUV_FREEZE();
	duv_set_handle_data(stream, cast(void*)request);
	return uv_listen(stream, backlog, &_duv_on_stream_connect_callback);
}

extern (C) status uv_accept(uv_stream_t* server, uv_stream_t* client);


alias void function(uv_stream_t* connection, Object context, status st) duv_write_callback;
private 
{
	extern (C) alias void function(uv_stream_t* connection, void* context, status st) duv__write_cb;

	extern (C) status duv__write(uv_stream_t* handle, void* context, ubyte* data, int data_len, duv__write_cb cb);


	class duv_write_context
	{
		public Object context;

		public duv_write_callback callback;

		public ubyte[] data;

	}
	extern (C) void _duv_write_callback(uv_stream_t* connection, void* context, status st)
	{
		duv_write_context ctx = cast(duv_write_context)context;
		ctx.DUV_UNFREEZE();
		ctx.callback(connection, ctx.context, st);
		delete ctx;
	}


}
status duv_write(uv_stream_t* handle, Object context, ubyte[] data, duv_write_callback callback)
{
	duv_write_context ctx = new duv_write_context;
	ctx.context = context;
	ctx.callback = callback;
	ctx.data = data;
	ctx.DUV_FREEZE();
	return duv__write(handle, cast(void*)ctx, data.ptr, cast(int)data.length, &_duv_write_callback);
}

private 
{
	extern (C) alias void function(uv_stream_t* stream, void* context, ptrdiff_t nread, ubyte* buff_data, size_t buff_len) duv__read_cb;

	extern (C) status duv__read_start(uv_stream_t* stream, void* context, duv__read_cb read_cb);


	class duv_read_context
	{
		public duv_read_cb callback;

		public Object context;

	}
	extern (C) void duv__read_callback(uv_stream_t* stream, void* context, ptrdiff_t nread, ubyte* buff_data, size_t buff_len)
	{
		duv_read_context read_context = cast(duv_read_context)context;
		ubyte[] data = null;
		if (nread > -1)
		{
			data = buff_data[0..nread].dup;
		}
		read_context.callback(stream, read_context.context, nread, data);
	}


}
alias void function(uv_stream_t* stream, Object context, ptrdiff_t nread, ubyte[] data) duv_read_cb;
status duv_read_start(uv_stream_t* stream, Object context, duv_read_cb cb)
{
	duv_read_context read_context = new duv_read_context;
	read_context.callback = cb;
	read_context.context = context;
	read_context.DUV_FREEZE();
	return duv__read_start(stream, cast(void*)read_context, &duv__read_callback);
}

status duv_read_stop(uv_stream_t* stream)
{
	void* readContext = null;
	status st = duv__read_stop(stream, &readContext);
	duv_read_context read_context = cast(duv_read_context)readContext;
	read_context.DUV_UNFREEZE();
	return st;
}

private 
{
	extern (C) status duv__read_stop(uv_stream_t* stream, void** readContext);


	extern (C) alias void function(uv_handle_t* handle, void* context) duv__handle_close_cb;

	extern (C) void duv__handle_close(uv_handle_t* handle, void* context, duv__handle_close_cb close_cb);


	class duv_close_context
	{
		public duv_handle_close_cb callback;

		public Object context;

	}
	extern (C) void duv__handle_close_callback(uv_handle_t* handle, void* context)
	{
		duv_close_context close_context = cast(duv_close_context)context;
		if (close_context.callback !is null)
		{
			close_context.callback(handle, close_context.context);
		}
		close_context.DUV_UNFREEZE();
		delete close_context;
	}


	extern (C) int uv_is_closing(uv_handle_t* handle);


	extern (C) void duv__handle_close_async(uv_handle_t* handle);


}
alias void function(uv_handle_t* handle, Object context) duv_handle_close_cb;
void duv_handle_close(uv_handle_t* handle, Object context, duv_handle_close_cb cb)
{
	duv_close_context close_context = new duv_close_context;
	close_context.context = context;
	close_context.callback = cb;
	close_context.DUV_FREEZE();
	duv__handle_close(handle, cast(void*)close_context, &duv__handle_close_callback);
}

void duv_handle_close_async(uv_handle_t* handle)
{
	duv__handle_close_async(handle);
}

bool duv_is_closing(uv_handle_t* handle)
{
	return uv_is_closing(handle) != 0;
}

private 
{
	extern (C) immutable(char)* uv_err_name(_uv_err_t err);


	extern (C) immutable(char)* uv_strerror(_uv_err_t err);


	extern (C) _uv_err_t uv_last_error(uv_loop_t* loop);


}
duv_error duv_last_error(status code, uv_loop_t* loop)
{
	duv_error error;
	if (code < 0)
	{
		error.code = code;
		_uv_err_t err = uv_last_error(loop);
		error.name = std.conv.to!string(uv_err_name(err));
		error.message = std.conv.to!string(uv_strerror(err));
	}
	return error;
}

@property bool hasError(duv_error err)
{
	return err.code < 0;
}


extern (C) uv_handle_t* duv__handle_alloc(uv_handle_type type);


alias void function(uv_check_t* handle, Object context, int status) duv_check_cb;
private 
{
	class duv_check_context
	{
		public duv_check_cb callback;

		public Object context;

	}
	extern (C) alias void function(uv_check_t* handle, void* context, int status) duv__check_cb;

	extern (C) status duv__check_start(uv_check_t* handle, void* context, duv__check_cb cb);


	extern (C) status duv__check_stop(uv_check_t* check);


	extern (C) void* duv__check_get_context(uv_check_t* handle);


	extern (C) void duv__check_callback(uv_check_t* handle, void* context, int status)
	{
		duv_check_context ctx = cast(duv_check_context)context;
		ctx.callback(handle, ctx.context, status);
	}


}
extern (C) status uv_check_init(uv_loop_t* loop, uv_check_t* handle);


status duv_check_start(uv_check_t* handle, Object context, duv_check_cb cb)
{
	duv_check_context ctx = new duv_check_context;
	ctx.context = context;
	ctx.callback = cb;
	ctx.DUV_FREEZE();
	return duv__check_start(handle, cast(void*)ctx, &duv__check_callback);
}

status duv_check_stop(uv_check_t* handle)
{
	void* context = duv__check_get_context(handle);
	duv_check_context ctx = cast(duv_check_context)context;
	ctx.context = null;
	ctx.callback = null;
	ctx.DUV_UNFREEZE();
	int st = duv__check_stop(handle);
	delete ctx;
	return st;
}

private 
{
	class duv_tcp_connect_context
	{
		public 
		{
			duv_tcp_connect_callback callback;
			Object context;
		}
	}
	extern (C) alias void function(uv_tcp_t* handle, void* context, int status) duv__tcp_connect_callback;

	extern (C) status duv__tcp_connect4(uv_tcp_t* handle, void* context, immutable(char)* ipv4, int port, duv__tcp_connect_callback cb);


	extern (C) void duv_tcp_connect_bridge_callback(uv_tcp_t* handle, void* context, int status)
	{
		duv_tcp_connect_context ctx = cast(duv_tcp_connect_context)context;
		if (ctx.callback !is null)
		{
			ctx.callback(handle, ctx.context, status);
		}
		ctx.DUV_UNFREEZE();
		delete ctx;
	}


}
alias void function(uv_tcp_t* handle, Object context, int status) duv_tcp_connect_callback;
status duv_tcp_connect4(uv_tcp_t* handle, Object context, string ipv4, int port, duv_tcp_connect_callback cb)
{
	duv_tcp_connect_context ctx = new duv_tcp_connect_context;
	ctx.context = context;
	ctx.callback = cb;
	ctx.DUV_FREEZE();
	return duv__tcp_connect4(handle, cast(void*)ctx, ipv4.toStringz, port, &duv_tcp_connect_bridge_callback);
}

