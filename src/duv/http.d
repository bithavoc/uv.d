module duv.http;
import duv.core;
import duv.c;
import std.stdio;
import std.conv;

public struct HttpHeader {
  private string _name, _value;

  public @property name() {
    return _name;
  }
  public @property name(string name) {
    _name = name;
  }
  public @property value() {
    return _value;
  }
  public @property value(string value) {
    _value = value;
  }
}
private {
  template http_parser_cb(string Name) {
    const char[] http_parser_cb = "static int duv_http_parser_" ~ Name ~ "(http_parser * parser) { void * _self = duv_get_http_parser_data(parser); HttpParser self = cast(HttpParser)_self; return self._" ~ Name ~ "(); }";
  }

  template http_parser_data_cb(string Name) {
    const char[] http_parser_data_cb = "static int duv_http_parser_" ~ Name ~ "(http_parser * parser, ubyte * at, size_t len) { HttpParser self = cast(HttpParser)duv_get_http_parser_data(parser); return self._" ~ Name ~ "(at[0 .. len]); }";
  }
}

public class HttpParserException : Exception {
  private string _name;
  public this(string message, string name, string filename = __FILE__, size_t line = __LINE__, Throwable next = null) {
    super(message, filename, line, next);
  }
  public @property string name() {
    return _name;
  }
  public @property void name(string name) {
    _name = name;
  }
}

public alias void delegate(HttpParser) HttpParserDelegate;
public alias void delegate(HttpParser, ubyte[] data) HttpParserDataDelegate;
public alias void delegate(HttpParser, string data) HttpParserStringDelegate;

public class HttpParser {
  private {

    extern(C) {
      mixin(http_parser_cb!("on_message_begin"));
      mixin(http_parser_data_cb!("on_url"));
      mixin(http_parser_data_cb!("on_header_value"));
      mixin(http_parser_data_cb!("on_header_field"));
      mixin(http_parser_cb!("on_headers_complete"));
      mixin(http_parser_data_cb!("on_body"));
      mixin(http_parser_cb!("on_message_complete"));
    }

    http_parser* _parser;
    http_parser_settings _settings;
    HttpHeader currentHeader;

    // delegates
    HttpParserDelegate _messageBegin, _messageComplete, _headersComplete;
    HttpParserDataDelegate _onData;
    HttpParserStringDelegate _onUrl;
    Throwable _lastException;

    const int CB_OK = 0;
    const int CB_ERR = 1;
  }

  public {
    this() {
      _parser = duv_alloc_http_parser();
      duv_set_http_parser_data(_parser, cast(void*)this);
      http_parser_init(_parser, http_parser_type.HTTP_REQUEST);
      _settings.on_message_begin = &duv_http_parser_on_message_begin;
      _settings.on_message_complete = &duv_http_parser_on_message_complete;
      _settings.on_header_field = &duv_http_parser_on_header_field;
      _settings.on_header_value = &duv_http_parser_on_header_value;
      _settings.on_headers_complete = &duv_http_parser_on_headers_complete;
      _settings.on_body = &duv_http_parser_on_body;
      _settings.on_url = &duv_http_parser_on_url;
    }

    size_t execute(ubyte[] data) {
      _lastException = null;
      size_t inputLength = data.length;
      size_t ret = http_parser_execute(_parser, &_settings, cast(ubyte*)data, inputLength);
      auto error = duv_http_parser_get_errno(_parser);
      //writefln("Parsed %d of %d", ret, inputLength);
      if(_lastException || error || ret != inputLength) {
        if(_lastException) {
          throw _lastException;
        }
        const(char)* errName = duv_http_errno_name(_parser);
        const(char)* errDescription = duv_http_errno_description(_parser);
        string errNameStr = to!string(errName);
        string errDescStr = to!string(errDescription);
        throw new HttpParserException(errDescStr, errNameStr);
      }
      return ret;
    }

    @property HttpParserDelegate onMessageBegin() {
      return _messageBegin;
    }
    @property void onMessageBegin(HttpParserDelegate callback) {
      _messageBegin = callback;
    }

    @property HttpParserDelegate onMessageComplete() {
      return _messageComplete;
    }
    @property void onMessageComplete(HttpParserDelegate callback) {
      _messageComplete = callback;
    }

    @property HttpParserDelegate onHeadersComplete() {
      return _headersComplete;
    }
    @property void onHeadersComplete(HttpParserDelegate callback) {
      _headersComplete = callback;
    }

    @property HttpParserDataDelegate onData() {
      return _onData;
    }
    @property void onData(HttpParserDataDelegate callback) {
      _onData = callback;
    }

    @property HttpParserStringDelegate onUrl() {
      return _onUrl;
    }
    @property void onUrl(HttpParserStringDelegate callback) {
      _onUrl = callback;
    }
  }

  package {
    int _on_message_begin() {
      if(this._messageBegin) {
        try {
          _messageBegin(this);
        } catch(Throwable ex) {
          _lastException = ex;
          return CB_ERR;
        }
      }
      return CB_OK;
    }
    
    int _on_message_complete() {
      if(this._messageComplete) {
        try {
          _messageComplete(this);
        } catch(Throwable ex) {
          _lastException = ex;
          return CB_ERR;
        }
      }
      return CB_OK;
    }
    
    int _on_headers_complete() {
      if(this._headersComplete) {
        try {
          _headersComplete(this);
        } catch(Throwable ex) {
          _lastException = ex;
          return CB_ERR;
        }
      }
      return CB_OK;
    }

    int _on_url(ubyte[] data) {
      writeln("HTTP URL FOUND");
      writefln("URL '%s'", cast(string)data);
      return 0;
    }

    int _on_header_value(ubyte[] data) {
      writefln("Header Value '%s'", cast(string)data);
      return 0;
    }

    int _on_header_field(ubyte[] data) {
      writefln("Header Field '%s'", cast(string)data);
      return 0;
    }

    int _on_body(ubyte[] data) {
      writefln("Body '%s'", cast(string)data);
      return 0;
    }
  }

  ~this() {
    if(_parser) {
      duv_free_http_parser(_parser);
      _parser = null;
    }
  }
}
