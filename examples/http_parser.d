import duv.core;
import std.stdio;
import duv.http;

void main() {
  runMainDuv((loop) {
    auto server = new DuvTcpStream(loop);
    server.bind4("0.0.0.0", 3000);
    server.listen(128);
    writeln("HTTP Accepting Clients on port 3000");
    while(true) {
      writeln("Waiting for next client...");
      auto client = server.accept();
      writeln("Accepted Client");
      client.onClosed = (timer) {
        writeln("Client Connection was Closed");
      };
      HttpParser parser = new HttpParser();
      while(true) {
        writeln("Reading Data");
        ubyte[] data = client.read();
        writefln("Parsing Http Data %s", cast(string)data);
        parser.execute(data);
      }
    }
  });
}
