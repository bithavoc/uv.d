module duv.http;
import duv.core;
import duv.c;
import std.stdio;
import std.conv;

enum HttpParserType {
  REQUEST,
  RESPONSE,
  BOTH
};

public struct HttpHeader {
  package string _name, _value;

  public:
    @property string name() {
      return _name;
    }
    @property void name(string name) {
      _name = name;
    }
    @property string value() {
      return _value;
    }
    @property void value(string value) {
      _value = value;
    }

    @property bool hasValue() {
      return _value !is null;
    }

    @property bool hasName() {
      return _name !is null;
    }

    @property bool isEmpty() {
      return !hasName() && !hasValue();
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
public alias void delegate(HttpParser, HttpHeader header) HttpParserHeaderDelegate;

public class HttpParser {
  private {

    extern(C) {
      mixin(http_parser_cb!("on_message_begin"));
      mixin(http_parser_data_cb!("on_url"));
      mixin(http_parser_cb!("on_status_complete"));
      mixin(http_parser_data_cb!("on_header_value"));
      mixin(http_parser_data_cb!("on_header_field"));
      mixin(http_parser_cb!("on_headers_complete"));
      mixin(http_parser_data_cb!("on_body"));
      mixin(http_parser_cb!("on_message_complete"));
    }

    http_parser* _parser;
    http_parser_settings _settings;
    HttpParserType _type;

    // delegates
    HttpParserDelegate _messageBegin, _messageComplete, _headersComplete, _statusComplete;
    HttpParserDataDelegate _onBody;
    HttpParserStringDelegate _onUrl;
    HttpParserHeaderDelegate _onHeader;
    Throwable _lastException;

    const int CB_OK = 0;
    const int CB_ERR = 1;

    /** Begin Counters
      Countes are reset every time a new message is received. Check _resetCounters.
      */
    int _headerFields;
    int _headerValues;
    HttpHeader _currentHeader;

    void _resetCounters() {
      _headerFields = 0;
      _headerValues = 0;
      _resetCurrentHeader();
    }

    void _resetCurrentHeader() {
      clear(_currentHeader);
    }
    /** End Counters **/
  }


  public {

    this() {
      this(HttpParserType.REQUEST);
    }

    this(HttpParserType type) {
      _type = type;
      _parser = duv_alloc_http_parser();
      duv_set_http_parser_data(_parser, cast(void*)this);
      http_parser_init(_parser, cast(http_parser_type)type);
      _settings.on_message_begin = &duv_http_parser_on_message_begin;
      _settings.on_message_complete = &duv_http_parser_on_message_complete;
      _settings.on_status_complete = &duv_http_parser_on_status_complete;
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

    @property HttpParserType type() {
      return _type;
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

    @property HttpParserDelegate onStatusComplete() {
      return _statusComplete;
    }
    @property void onStatusComplete(HttpParserDelegate callback) {
      _statusComplete = callback;
    }

    @property HttpParserDelegate onHeadersComplete() {
      return _headersComplete;
    }
    @property void onHeadersComplete(HttpParserDelegate callback) {
      _headersComplete = callback;
    }

    @property HttpParserDataDelegate onBody() {
      return _onBody;
    }
    @property void onBody(HttpParserDataDelegate callback) {
      _onBody = callback;
    }

    @property HttpParserStringDelegate onUrl() {
      return _onUrl;
    }
    @property void onUrl(HttpParserStringDelegate callback) {
      _onUrl = callback;
    }

    @property HttpParserHeaderDelegate onHeader() {
      return _onHeader;
    }
    @property void onHeader(HttpParserHeaderDelegate callback) {
      _onHeader = callback;
    }
  }

  package {
    int _on_message_begin() {
      _resetCounters();
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

    int _on_status_complete() {
      if(this._statusComplete) {
        try {
          _statusComplete(this);
        } catch(Throwable ex) {
          _lastException = ex;
          return CB_ERR;
        }
      }
      return CB_OK;
    }
    
    int _on_url(ubyte[] data) {
      if(this._onUrl) {
        try {
          _onUrl(this, cast(string)data);
        } catch(Throwable ex) {
          _lastException = ex;
          return CB_ERR;
        }
      }
      return CB_OK;
    }
    
    int _on_header_field(ubyte[] data) {
      if(_currentHeader.hasValue) {
        int res = _safePublishHeader();
        _resetCurrentHeader();
        if(res != CB_OK) {
          return res;
        }
      }
      string text = cast(string)data;
      _currentHeader._name ~= text;
      return CB_OK;
    }

    int _on_header_value(ubyte[] data) {
      string text = cast(string)data;
      _currentHeader._value ~= text;
      return CB_OK;
    }

    int _safePublishHeader() {
      try {
        _publishHeader();
      } catch(Throwable ex) {
        _lastException = ex;
        return CB_ERR;
      }
      return CB_OK;
    }
    void _publishHeader() {
      if(_currentHeader.isEmpty) return;

      if(this._onHeader) {
        this._onHeader(this, _currentHeader);
      }
    }

    int _on_headers_complete() {
      try {
        _publishHeader();
        if(this._headersComplete) {
          _headersComplete(this);
        }
      } catch(Throwable ex) {
        _lastException = ex;
        return CB_ERR;
      }
      return CB_OK;
    }

    int _on_body(ubyte[] data) {
      if(this._onBody) {
        try {
          _onBody(this, data);
        } catch(Throwable ex) {
          _lastException = ex;
          return CB_ERR;
        }
      }
      return CB_OK;
    }
  }

  ~this() {
    if(_parser) {
      duv_free_http_parser(_parser);
      _parser = null;
    }
  }
}
