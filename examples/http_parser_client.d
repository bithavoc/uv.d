import duv.core;
import std.stdio;

void main() {
  runMainDuv((loop) {
      writeln("Connecting...");
      auto client = new DuvTcpStream(loop);
      client.connect4("0.0.0.0", 3000);
      writeln("... Connected");
      writeln("Sending Data");
      client.write(cast(ubyte[])"GET");
      client.write(cast(ubyte[])" /");
      client.write(cast(ubyte[])" /hello HTTP/1.1\r\n");
  });
}
