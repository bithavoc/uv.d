import duv.core, std.stdio;

void main() {
  runMainDuv((loop) {
    auto prepare = new DuvPrepare(defaultLoop);
    prepare.callback = (p) {
      writeln("Prepare");
    };
    prepare.start();
    auto socket = new DuvTcpStream(defaultLoop);
    writeln("Binding");
    socket.bind4("0.0.0.0", 3000);
    writeln("Listen");
    socket.listen(128);
    writeln("Waiting for Client");
    for(auto i = 0; i < 1; i++) {
      auto client = socket.accept();
      writeln("Cliente Accepted, will accept another one");
      runSubDuv((loop) {
        writeln("Readong from The cleint");
        try {
          client.read();
        } catch(Exception ex) {
          writeln("Error reading from client ", ex);
        }
      });
    }
    writeln("Will Stop Prepare");
    prepare.stop();
  });
}
