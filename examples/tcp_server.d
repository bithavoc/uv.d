import duv.core;
import std.stdio;

void main() {
  runMainDuv((loop) {
    writeln("Running Duv Program");
    auto server = new DuvTcpStream(loop);
    server.bind4("0.0.0.0", 3000);
    server.listen(128);
    writeln("Accepting Clients on port 3000");
    while(true) {
      writeln("Waiting for next client");
      auto client = server.accept();
      client.write(cast(ubyte[])"Hello\n... and Goodbye\n");
      client.close();
    }
  });
}
