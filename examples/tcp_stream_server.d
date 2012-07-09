import duv.core;
import std.stdio;
import std.conv;

void main() {
  runMainDuv((loop) {
    writeln("Running Stream Server");
    auto server = new DuvTcpStream(loop);
    server.bind4("0.0.0.0", 3000);
    server.listen(128);
    writeln("Waiting for Client");
    while(true) {
      writeln("Waiting for next client");
      auto newClient = server.accept();
      runSubDuv((loop) {
        auto client = newClient;
        writeln("Client Connected");
        client.onClosed = (timer) {
          writeln("Connection was Interrupted");
        };
        auto timer = new DuvTimer(defaultLoop);
        timer.setRepeat(10);
        int count = 0;
        timer.callback = (timer) {
          count++;
          client.write(cast(ubyte[])("Hello " ~ text(count)));
          /*if(count == -1) {
            writeln("Stopping timer");
            client.write(cast(ubyte[])("Bye Bye"));
            timer.stop();
          }*/
        };
        timer.start();
        writeln("Timer Started");
      });
      writeln("Next Duv");
    }
  });
}
