import duv.core;
import std.stdio;

void main() {
  runMainDuv((loop) {
    writeln("Running Duv Program");
    auto client = new DuvTcpStream(loop);
    client.connect4("0.0.0.0", 3000);
    ubyte[] data = client.read();
    string text = cast(string)data;
    writefln("Server Sent %s", text);
    //client.write(cast(ubyte[])"Hi!!!\n");
  });
}
