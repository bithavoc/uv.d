module duv.http;
import duv.core;
import duv.c;
import std.stdio;

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
    const char[] http_parser_cb = "static int duv_http_parser_" ~ Name ~ "(http_parser * parser) { HttpParser self = cast(HttpParser)parser.data; return self._" ~ Name ~ "(); }";
  }

  template http_parser_data_cb(string Name) {
    const char[] http_parser_data_cb = "static int duv_http_parser_" ~ Name ~ "(http_parser * parser, ubyte * at, size_t len) { HttpParser self = cast(HttpParser)parser.data; return self._" ~ Name ~ "(at[0 .. len]); }";
  }
}
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

    http_parser _parser;
    http_parser_settings _settings;
  }

  private HttpHeader currentHeader;
  public this() {
    http_parser_init(&_parser, http_parser_type.HTTP_REQUEST);
    _parser.data = &this;
    _settings.on_message_begin = &duv_http_parser_on_message_begin;
    _settings.on_header_field = &duv_http_parser_on_header_field;
    _settings.on_header_value = &duv_http_parser_on_header_value;
    _settings.on_headers_complete = &duv_http_parser_on_headers_complete;
    _settings.on_body = &duv_http_parser_on_body;
    _settings.on_url = &duv_http_parser_on_url;
  }

  public void execute(ubyte[] data) {
    http_parser_execute(&_parser, &_settings, cast(ubyte*)data, data.length);
  }

  package int _on_message_begin() {
    writeln("HTTP MESSAGE BEGIN");
    return 0;
  }
  
  package int _on_headers_complete() {
    writeln("HTTP HEADERS COMPLETE");
    return 0;
  }

  package int _on_url(ubyte[] data) {
    writeln("HTTP URL FOUND");
    writefln("URL '%s'", cast(string)data);
    return 0;
  }

  package int _on_header_value(ubyte[] data) {
    writefln("Header Value '%s'", cast(string)data);
    return 0;
  }

  package int _on_header_field(ubyte[] data) {
    writefln("Header Field '%s'", cast(string)data);
    return 0;
  }

  package int _on_body(ubyte[] data) {
    writefln("Body '%s'", cast(string)data);
    return 0;
  }

  package int _on_message_complete() {
    writeln("Message Complete");
    return 0;
  }

/*  ~this() {
    if(_parser) {
      duv_free_http_parser(_parser);
      _parser = null;
    }
  }*/
}
