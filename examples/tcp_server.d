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
      client.onClosed = (timer) {
        writeln("Client Connection was Closed");
      };
      client.write(cast(ubyte[])"Hello\n... and Goodbye\n");
      try {
        auto response = client.read();
        writeln("Client said ", cast(string)response);
      } catch(Throwable ex) {
        writeln("Error reading from client", ex);
      }
      writeln("We will not talk to this client anymore, the timer will automatically close it in a couple of seconds");
      //client.close();
    }
  });
}
