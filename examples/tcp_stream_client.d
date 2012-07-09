import duv.core;
import std.stdio;

void main() {
  runMainDuv((loop) {
    writeln("Stream Client");
    auto client = new DuvTcpStream(loop);
    client.onClosed = (connection) {
      writeln("Connection to the server was terminated");
    };
    client.connect4("0.0.0.0", 3000);
    writeln("Receiving Data");
    int count = 0;
    while(true) {
      ubyte[] data = client.read();
      writefln("Received! length %d bytes as: %s ", data.length, cast(string)data);
    }
  });
}
