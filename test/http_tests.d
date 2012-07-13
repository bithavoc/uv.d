import duv.http;
import std.stdio;
import testutil;

unittest {
  {
    scopeTest("HttpParser", {
      scopeTest("Exceptions", {
        string customErrorMessage = "Custom Error";
        runTest("onMessageBegin", {
          Exception lastException;
          auto parser = new HttpParser();
          parser.onMessageBegin = (parser) {
            throw new Exception(customErrorMessage);
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\n\r\n");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException !is null, "Custom exception was not cached and throwed by the execute method");
          assert(lastException.msg == customErrorMessage, "Exception raised doesn't have the given exception");
        });
        runTest("onMessageComplete", {
          Exception lastException;
          auto parser = new HttpParser();
          parser.onMessageComplete = (parser) {
            throw new Exception(customErrorMessage);
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\n\r\n");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException !is null, "Custom exception was not cached and throwed by the execute method");
          assert(lastException.msg == customErrorMessage, "Exception raised doesn't have the given exception");
        });
        runTest("onHeadersComplete", {
          Exception lastException;
          auto parser = new HttpParser();
          parser.onHeadersComplete = (parser) {
            throw new Exception(customErrorMessage);
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\nHeaderA: Valor del Header 1\r\n\r\n");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException !is null, "Custom exception was not cached and throwed by the execute method");
          assert(lastException.msg == customErrorMessage, "Exception raised doesn't have the given exception");
        });
        runTest("onBody", {
          Exception lastException;
          auto parser = new HttpParser();
          parser.onBody = (parser, ubyte[] data) {
            throw new Exception(customErrorMessage);
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\nContent-Length: 3\r\n\r\naaa");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException !is null, "Custom exception was not cached and throwed by the execute method");
          assert(lastException.msg == customErrorMessage, "Exception raised doesn't have the given exception");
        });
        runTest("onUrl", {
          Exception lastException;
          auto parser = new HttpParser();
          parser.onUrl = (parser, string data) {
            throw new Exception(customErrorMessage);
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\n\r\n");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException !is null, "Custom exception was not cached and throwed by the execute method");
          assert(lastException.msg == customErrorMessage, "Exception raised doesn't have the given exception");
        });
      }); //Exceptions
      scopeTest("Headers", {
        runTest("chunked", {
          HttpHeader headers[];
          Exception lastException;
          auto parser = new HttpParser();
          parser.onHeader = (parser, HttpHeader header) {
            headers ~= header;
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\nHea");
            parser.execute(cast(ubyte[])"de");
            parser.execute(cast(ubyte[])"r1: Val");
            parser.execute(cast(ubyte[])"ue1\r\n");
            parser.execute(cast(ubyte[])"Header");
            parser.execute(cast(ubyte[])"2: Val");
            parser.execute(cast(ubyte[])"ue2\r\n\r\n");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException is null, "No exception should be throwed");
          assert(headers.length == 2, "The parsed headers do not match");
          assert(headers[0].name == "Header1", "Header 0 name did not match");
          assert(headers[0].value == "Value1", "Header 0 value did not match");
          assert(headers[1].name == "Header2", "Header 1 name did not match");
          assert(headers[1].value == "Value2", "Header 1 value did not match");
        });
        runTest("batch", {
          HttpHeader headers[];
          Exception lastException;
          auto parser = new HttpParser();
          parser.onHeader = (parser, HttpHeader header) {
            headers ~= header;
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\nHeader1: Value1\r\nHeader2: Value2\r\n\r\n");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException is null, "No exception should be throwed");
          assert(headers.length == 2, "The parsed headers do not match");
          assert(headers[0].name == "Header1", "Header 0 name did not match");
          assert(headers[0].value == "Value1", "Header 0 value did not match");
          assert(headers[1].name == "Header2", "Header 1 name did not match");
          assert(headers[1].value == "Value2", "Header 1 value did not match");
        });
      });
    }); //HttpParser
  }
}

void main() {
  writeln("All Tests OK");
}
