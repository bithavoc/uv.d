public import duv.types;
public import duv.c;

public: void check(status st, uv_loop_t* loop = uv_default_loop) {
	if(st < 0) {
        duv_error error = duv_last_error(st, loop);
		throw new Exception(std.string.format("%s: %s", error.name, error.message));
	}
}
