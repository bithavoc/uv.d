import std.stdio;
import duv.types;
import util;

class appContext {

}

void main() {
  writeln("Duv TCP Listener");

  uv_loop_t * loop = uv_default_loop();

  "Opening File".writeln;

  auto context = new appContext;

  duv_fs_open(loop, context, __FILE__, duv_file_flag.O_RDONLY, std.conv.octal!666,  (c, s, fd) {

  });

  uv_run(loop, uv_run_mode.UV_RUN_DEFAULT).check();
}
