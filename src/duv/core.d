/**
Authors: thepumpkin1979, johan@firebase.co
 */
module duv.core;
import duv.c.calls;

debug {
  import std.stdio;
}

private {
  static DuvLoop _defaultLoop;

  Throwable lastUVThrowable(DuvLoop loop) {
      auto lastError = uv_last_error(loop.ptr);
      if(lastError.code != 0) {
        string errorMessage = duv_strerror(lastError);
        return new DuvException(errorMessage, lastError.code);
      }
      return null;
  }

  /// Throws an exception if the call is not successfull.
  void ensureSuccessCall(duv_status status, DuvLoop loop) {
    if(status != 0) {
      auto lastException = lastUVThrowable(loop);
      if(lastException) throw lastException;
    }
  }

  void printUVError(DuvLoop loop) {
    auto lastError = uv_last_error(loop.ptr);
    string errorMessage = duv_strerror(lastError);
    writeln("UV error: ", errorMessage, " with code ", lastError.code);
  }

  extern (C) {
    /**
      unv_connection_cb callback for the uv_tcp_stream_t(DuvTcpStream).
     */
    void duv_on_tcp_stream_connect(void*handle, int status) {
      writeln("Invocking allocate");
      uv_buf_t st = duv_alloc_callback(cast(void*)20, 3000);
      writefln("MY OWN len for the dummy buf %d",st.len);

      writeln("New Connection for Handle", handle, " with status ", status);
      void* selfPtr = duv_get_handle_data(handle);
      writeln("SelfPtr is", selfPtr);
      DuvTcpStream self = cast(DuvTcpStream)selfPtr;

      DuvTcpStream clientStream = new DuvTcpStream(self.loop);
      duv_status acceptStatus = uv_accept(handle, clientStream.ptr);
      printUVError(self.loop);
      clientStream.listener = self;

      if(self.onConnection != null) {
        self.onConnection(clientStream);
      }
    }

    void duv_stream_read_callback(void* stream, ssize_t nread, uv_buf_t buf) {
      debug {
        writeln("TCP Read Something");
        writefln("Size of uv_buf_t in D is %d", uv_buf_t.sizeof);
       // writefln("Base pointer %d", cast(ssize_t)buf.base);
      }
      void* selfPtr = duv_get_handle_data(stream);
      DuvStream self = cast(DuvStream)selfPtr;
      self._onReadCallback(nread, buf);
    }

    void duv_stream_close_callback(void* stream) {
      debug {
        writeln("Stream closed callback");
      }
      void* selfPtr = duv_get_handle_data(stream);
      DuvStream self = cast(DuvStream)selfPtr;
      self._onCloseCallback();
    }

    void duv_stream_write_callback(uv_write_t_ptr req, duv_status status) {
      debug {
        writeln("Write Finished");
      }
      auto request = cast(DuvStreamWriteRequest)duv_get_request_data(req);
      debug {
        writeln("Write Request Finished ", request.ptr);
      }
      request._stream._onWriteCallback(request, status);
    }
    
    void duv_tcp_connect_callback(uv_connect_t_ptr req, duv_status status) {
      debug {
        writeln("Connect Finished");
      }
      auto request = cast(DuvTcpStreamConnectRequest)duv_get_request_data(req);
      debug {
        writeln("Connect Request Finished ", request.ptr);
      }
      request._stream._onConnectCallback(request, status);
    }
  }
}

public {

  /**
    Describes a Buffer that Will be used Temporarily on a Callback
    */
  class DuvTempBuffer {
    private uv_buf_t _buf;
    private size_t _count;

    public this(uv_buf_t buf, size_t readCount) {
      this._buf = buf;
      this._count = readCount;
    }

    /**
      Converts this Temporary Buffer to an Array of Bytes
      */
    public ubyte[] toBytes() {
      return this._buf.base[0..this._count];
    }

    /**
      Implicit Converstion to ubytes[]
      */
    alias toBytes this;

    /**
      Explicit Converstion to ubytes[]
      */
    T opCast(T)() if (is(T == ubyte[])) {
      return this.toBytes();
    }
  }

  /**
    Returns the default loop for the current thread. It uses uv_default_loop under the hood.
   */
  public @property DuvLoop defaultLoop() {
    if(!_defaultLoop) {
      debug {
        writeln("Initializing default loop");
      }
      _defaultLoop = new DuvLoop(uv_default_loop(), false);
    }
    return _defaultLoop; 
  }

  /**
    Represents a uv loop.
   */
  public final class DuvLoop {

    // uv_loop_t pointer
    package uv_loop_t_ptr ptr;

    private bool _isCustom;

    /**
      Indicates whether the instance is a custom loop created manually or was the default loop.
     */
    public @property bool isCustom() {
      return _isCustom;
    }

    /**
      Creates a new loop, It uses uv_loop_new under the hood.
See_Also: Default
     */
    public this() {
      this(uv_loop_new(), true);
    }

    private this(uv_loop_t_ptr ptr, bool isCustom) {
      this.ptr = ptr;
      this._isCustom = isCustom;
      debug {
        writeln("loop created, is custom:", isCustom);
      }
    }

    public ~this() {
      debug {
        writeln("destroying loop, was custom: ", isCustom);
      }
      // Delete the Loop only if is not the default loop.
      if(this.isCustom) {
        uv_loop_delete(this.ptr);
      }
    }

    /**
      Run the Loop and Wait until all the tasks are finished
     */
    public void runAndWait() {
      duv_status status = uv_run(this.ptr);
      ensureSuccessCall(status, this);
    }
  }
  /**
    Duv Exception. Normally raised when an error code is found in libuv.
   */
  public class DuvException : Exception {
    private int _code;

    /**
      libuv error code
     */
    public @property int code() {
      return _code;
    }

    public this(string msg) {
      this(msg, 0);
    }

    public this(string msg, int code) {
      super(msg);
      this._code = code;
    }
  }

  alias void delegate(DuvStream stream) DuvStreamClosedDelegate;
  alias void delegate(DuvStream stream, Throwable error, DuvTempBuffer buffer) DuvStreamReadDelegate;
  alias void delegate(DuvStream stream, Throwable error) DuvStreamWriteDelegate;
  alias void delegate(DuvTcpStream stream, Throwable error) DuvTcpStreamConnectDelegate;

  private class DuvStreamWriteRequest {
    private DuvStreamWriteDelegate _onFinished;
    private uv_write_t_ptr ptr;
    private ubyte[] data;
    private DuvStream _stream;
    
    public this(DuvStream stream, DuvStreamWriteDelegate onFinished, ubyte[] data) {
      this._stream = stream;
      this._onFinished = onFinished;
      this.data = data;
      this.ptr = duv_alloc_write();
      duv_set_request_data(this.ptr, cast(void*)this);
    }

    public ~this() {
      debug {
        writeln("Deallocating Write Request");
      }
      if(this.ptr != null) {
        std.c.stdlib.free(this.ptr);
        this.ptr = null;
      }
    }
  }

  private class DuvTcpStreamConnectRequest {
    private DuvTcpStreamConnectDelegate _onFinished;
    private uv_connect_t_ptr ptr;
    private ubyte[] data;
    private DuvTcpStream _stream;
    
    public this(DuvTcpStream stream, DuvTcpStreamConnectDelegate onFinished) {
      this._stream = stream;
      this._onFinished = onFinished;
      this.data = data;
      this.ptr = duv_alloc_connect();
      duv_set_request_data(this.ptr, cast(void*)this);
    }

    public ~this() {
      debug {
        writeln("Deallocating Connect Request");
      }
      if(this.ptr != null) {
        std.c.stdlib.free(this.ptr);
        this.ptr = null;
      }
    }
  }
  /**
    libuv stream.
   */
  public abstract class DuvStream {

    //uv_handle_t*
    package void* ptr;

    DuvStream _listener;

    private DuvLoop _loop;

    private DuvStreamClosedDelegate _onClosed;
    private DuvStreamReadDelegate _onRead;

    private DuvStreamWriteRequest[ssize_t] _writes;

    public @property DuvStreamClosedDelegate onClosed() {
      return this._onClosed;
    }

    public @property void onClosed(DuvStreamClosedDelegate value) {
      this._onClosed = value;
    }

    public @property DuvLoop loop() {
      return _loop;
    }

    package this(uv_handle_type handleType, DuvLoop loop) {
      this.ptr = duv_alloc_handle(handleType);
      debug {
        writefln("Creating Stream handle with type %d", handleType);
      }
      this._loop = loop;
      this.init();
      duv_set_handle_data(this.ptr, cast(void*)this);
    }

    public ~this() {
      if(this.ptr != null) {
        debug {
          writefln("Destroying handle");
        }
        duv_free_handle(this.ptr);
        this.ptr = null;
      }
    }

    /// Initialize the Stream
    protected abstract void init();

    public @property DuvStream listener() {
      return _listener;
    }
    private  @property void listener(DuvStream listener) {
      _listener = listener;
    }

    /**
      Start reading data in this stream
      */
    public void startReading(DuvStreamReadDelegate onRead) {
      this._onRead = onRead;
      duv_status status = uv_read_start(this.ptr, &duv_alloc_callback, &duv_stream_read_callback);
      ensureSuccessCall(status, this.loop);
    }

    private void _onReadCallback(ssize_t nread, uv_buf_t buf) {
      debug {
        writeln("_onReadCallback, nread=", nread);
      }
      if(nread == -1) {
        Throwable error = lastUVThrowable(this.loop);
        if(this._onRead != null) {
          this._onRead(this, error, null);
        }
        // we must always close the stream after an error
        this.close();
      } else {
        // Notify the Readed Buffer
        DuvTempBuffer tempBuffer = new DuvTempBuffer(buf, cast(size_t)nread);
        if(this._onRead != null) {
          this._onRead(this, null, tempBuffer);
        }
      }
      buf.free();
    }

    public void close() {
      uv_close(this.ptr, &duv_stream_close_callback);
    }

    private void _onCloseCallback() {
      debug {
        writeln("DuvStream was closed");
      }
      if(this._onClosed != null) {
        this._onClosed(this);
      }
    }

    public void write(ubyte[] data) {
      this.write(data, null);
    }

    public void write(ubyte[] data, DuvStreamWriteDelegate onFinished) {
      auto write = new DuvStreamWriteRequest(this, onFinished, data);
      debug {
        writeln("Write Request Created ", write.ptr);
      }
      this._writes[cast(ssize_t)write.ptr] = write; // Hold a reference to the request
      uv_buf_t buf;
      buf.base = data.ptr;
      buf.len = data.length;
      duv_status status = uv_write(write.ptr, this.ptr, &buf, 1, &duv_stream_write_callback);
      ensureSuccessCall(status, this.loop);
    }

    package void _onWriteCallback(DuvStreamWriteRequest request, duv_status status) {
      this._writes.remove(cast(ssize_t)request.ptr); //Remove the reference to the request
      Throwable error = lastUVThrowable(this.loop);
      if(request._onFinished != null) {
        request._onFinished(this, error);
      }
      clear(request);
    }

  }

  /**
    TCP Stream
   */
  class DuvTcpStream : DuvStream {

    private void delegate(DuvTcpStream) onConnection;
    private DuvTcpStreamConnectRequest _connectRequest;

    /**
      Creates a TCP Stream on the default loop.
     */
    public this() {
      this(defaultLoop);
    }

    /**
      Creates a TCP Stream in the given loop.
     */
    public this(DuvLoop loop) {
      super(uv_handle_type.TCP, loop);
    }

    protected override void init() { 
      debug {
        writeln("Initializing TCP Stream");
      }
      duv_status status = uv_tcp_init(this.loop.ptr, this.ptr);
      ensureSuccessCall(status, this.loop);
    }

    /**
      Binds the Stream to a IPv4 address and port.
     */
    public void bind4(string ipv4, int port) {
      debug {
        writeln("Binding ipv4 TCP Stream");
      }
      sockaddr_in_ptr addr = duv_ip4_addr(std.string.toStringz(ipv4), port);
      duv_status status = duv_tcp_bind(this.ptr, addr);
      std.c.stdlib.free(addr);
      ensureSuccessCall(status, this.loop);
      debug {
        writeln(" Bound");
      }
    }

    /**
      Listen for new Connections. Needs to be bound using bind4 or bind6.
See_Also: bind4, bind6
     */
    public void listen(int backlog, void delegate(DuvTcpStream) onConnection) {
      this.onConnection = onConnection;
      debug {
        writeln("listen");
      }
      writeln("Will listen with ptr ", cast(void*)this);
      duv_status status = uv_listen(this.ptr, backlog, &duv_on_tcp_stream_connect);
      ensureSuccessCall(status, this.loop);
      debug {
        writeln(" Listening");
      }
    }

    public void connect4(string ipv4, int port, DuvTcpStreamConnectDelegate onConnect) {
      auto request = new DuvTcpStreamConnectRequest(this, onConnect);
      this._connectRequest = request;
      sockaddr_in_ptr addr = duv_ip4_addr(std.string.toStringz(ipv4), port);
      duv_status status = duv_tcp_connect(request.ptr, this.ptr, addr, &duv_tcp_connect_callback);
      std.c.stdlib.free(addr);
      ensureSuccessCall(status, this.loop);
    }
    
    package void _onConnectCallback(DuvTcpStreamConnectRequest request, duv_status status) {
      this._connectRequest = null;
      Throwable error = lastUVThrowable(this.loop);
      if(request._onFinished != null) {
        request._onFinished(this, error);
      }
      clear(request);
    }
  }


} // public
