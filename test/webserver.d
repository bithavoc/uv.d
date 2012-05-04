import duv.c.calls;
import duv.core;
import std.stdio;
import std.conv;
import std.c.stdlib;

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

  DuvTcpStream stream = new DuvTcpStream(loop);
  stream.onClosed = (stream) {
    writeln("Server Listener Closed");
  };
  stream.bind4("0.0.0.0", 3000);
  stream.listen(128, (DuvTcpStream client) {
      client.onClosed = (stream) {
        writeln("Client connection has been closed");
      };
      client.startReading((client, error, tempBuffer) {
          if(error) {
            writeln("WebServer found an error reading the client buffer ", error);
          } else {
            ubyte[] readedBytes = tempBuffer;
            writeln("Received bytes: ", readedBytes);
            client.write(readedBytes, (DuvStream writeClient, Throwable writeError) {
              writeln("Write Finished"); 
            });
          }
        });
      writeln("New Connection from Webserver");
  });

  /*DuvTcpStream client = new DuvTcpStream(loop);
  client.connect4("0.0.0.0", 9000, (DuvTcpStream connectedSocket, Throwable error) {
      if(error) {
        writeln("Connect Error ", error);
      } else {
        writeln("Connected!");
        connectedSocket.startReading((c, err, buf) {
          if(err !is null) {
            writeln("Error reading? ", err);
          } else {
            writeln("Read Done");
            ubyte[] data = buf;
            writeln("Readed Data ", data);
          }
        });
      }
  });
  */
  defaultLoop.runAndWait();

  /*
     void* server = duv_alloc_tcp(); //duv_alloc_handle(uv_handle_type.TCP);
     duv_status status = uv_tcp_init(uv_default_loop(), server);
     if(status) {
     uv_err_t error = uv_last_error(uv_default_loop());
     writefln("init error %d: %s", error.code, duv_strerror(error));
     return -1;
     }
     uv_sockaddr_in_ptr addr = duv_ip4_addr(std.string.toStringz("0.0.0.0"), 3000);
     status = duv_tcp_bind(server, addr);
     free(addr);
     if(status) {
     uv_err_t error = uv_last_error(uv_default_loop());
     writefln("bind error %d: %s", error.code, duv_strerror(error));
     return -1;
     }
  //d_TEST_uv_listen(server, 128, (stream, status) {  
  //  writeln("New Connection in D ", stream, " with status ", status);
  //});
  status = uv_listen(server, 128, (status, stream)  {
  writeln("New Connection ", stream, " with status ", status);
  if(status) {
  uv_err_t error = uv_last_error(uv_default_loop());
  writefln("on connect error %d: %s", error.code, duv_strerror(error));
  }
  });
  if(status) {
  uv_err_t error = uv_last_error(uv_default_loop());
  writefln("listen error %d: %s", error.code, duv_strerror(error));
  return -1;
  }

  writeln("Running Loop");
  uv_run(uv_default_loop());*/
  //free(server);
  return 0;
}
