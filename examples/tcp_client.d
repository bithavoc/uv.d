import duv.core;
import std.stdio;

void main() {
  runMainDuv((loop) {
    writeln("Running Duv Program");
    auto client = new DuvTcpStream(loop);
    client.onClosed = (connection) {
      writeln("Connection to the server was terminated");
    };
    client.connect4("0.0.0.0", 3000);
    ubyte[] data = client.read();
    string text = cast(string)data;
    writefln("Server Sent %s", text);
    client.write(cast(ubyte[])"Hi!!!\n");
    writeln("Checking to see if the server says anothing else");
    try {
      client.read();
    } catch(Throwable ex) {
      writeln("Error Reading from connection:", ex);
    }
  });
}
