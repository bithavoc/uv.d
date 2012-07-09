import duv.c;
import duv.core;
import std.stdio;
import std.conv;
import std.c.stdlib;
import core.thread;

int main() { 
  writeln("getting default loop");
  DuvLoop loop = defaultLoop;
  /* 
     writeln("Creating custom loop in scope");
     {
     scope customLoop = new DuvLoop();
     scope customTcpStream = new DuvTcpStream(loop);
     scope nullLoopTcpStream = new DuvTcpStream();
     }*/
  runMainDuv((loop) {
    auto stream = new DuvTcpStream(loop);
    stream.bind4("0.0.0.0", 3000);
    writeln("Will listen for new connections using Fiber");
    stream.listen(128);
    DuvTimer timer = new DuvTimer(loop);
    DuvStream lastClient = null;
    timer.setTimeout(2000);
    timer.setRepeat(2000);
    int lastCount = 0;
    timer.callback = (timer) {
      writefln("It's time to check out something!, %s", lastClient);
      if(lastClient) {
        lastCount++;
        if(lastCount == 2) {
          lastClient.close();
          lastClient = null;
        }
        if(lastCount == 5) {
          writefln("Stopping Timer");
          timer.stop();
        }
      }
    };
    timer.start();
    while(true) {
      writeln("== Will Accept Client ==");
      auto acceptedClient = stream.accept();
      lastClient = acceptedClient;
      runSubDuv((loop) {
        auto client = acceptedClient;
        writefln("Client %s Accepted in a new Fiber", client.id);
        while(true) {
          ubyte[] receivedData = null;
          try {
            writefln("Reading from Socket %s ", client.id);
            receivedData = client.read();
            writefln("Readed %s from Socket %s ", receivedData, client.id);
          } catch(Throwable err) {
            writefln("Read error %s was catched in socket %s", err, client.id);
          }
          if(receivedData) {
            try {
              writefln("Writing on Socket %s ", client.id);
              client.write(receivedData);
              writefln("Writen %s from Socket %s ", receivedData, client.id);
            } catch(Throwable err) {
              writefln("Write error %s was catched in socket %s", err, client.id);
            }
          }
        }
      });
    }
  });
  writeln("Reading Line for Exit");
  string s = readln();
  return 0;
}
