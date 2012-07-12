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
      client.write(cast(ubyte[])" /hello HTTP/1.1\r\n");
      //client.write(cast(ubyte[])"Content-Length: 2\r\n");
      client.write(cast(ubyte[])"\r\n");
      client.write(cast(ubyte[])"Hi");
      client.write(cast(ubyte[])"GET");
      client.write(cast(ubyte[])" /CONTENIDO2 HTTP/1.1\r\n");
      client.write(cast(ubyte[])"Content-Length: 0\r\n");
      client.write(cast(ubyte[])"\r\n");
  });
}
