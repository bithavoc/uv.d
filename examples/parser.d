import std.stdio;
import duv.http;

void main() {
  writeln("Starting Parser X");
  HttpParser parser = new HttpParser();
  parser.onMessageBegin = (p) {
    writeln("MessaeBegin Parser Delegate Invoked");
    throw new Exception("Some error");
  };
  auto parsed = parser.execute(cast(ubyte[])"GET ");
  writefln("PArsed %d", parsed);
  parsed = parser.execute(cast(ubyte[])"/hello HTTP/1.1\r\n");
  writefln("PArsed %d", parsed);
  parsed = parser.execute(cast(ubyte[])"Content-Length: 0\r\n");
  writefln("PArsed %d", parsed);
  parsed = parser.execute(cast(ubyte[])"\r\n");
  writefln("PArsed %d", parsed);
}
