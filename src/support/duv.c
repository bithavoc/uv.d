#include <stdio.h>
#include <stdlib.h>
#include "uv.h"

#define CORE_DEFINE_ALLOC(NAME, UV_TYPE) \
  void* duv_alloc_##NAME() { return malloc(sizeof(UV_TYPE)); }

#define DEFINE_SIMPLE_ALLOC(UV_TYPE) \
  CORE_DEFINE_ALLOC(UV_TYPE, UV_TYPE)

#define DEFINE_STRUCT_ALLOC(UV_TYPE) \
  CORE_DEFINE_ALLOC(UV_TYPE, struct UV_TYPE)

DEFINE_STRUCT_ALLOC(sockaddr_in);

struct sockaddr_in* duv_ip4_addr(const char * ip, int port) {
  struct sockaddr_in a = uv_ip4_addr(ip, port);
  struct sockaddr_in *addr = (struct sockaddr_in*)malloc(sizeof(struct sockaddr_in));
  *addr = a;
  return addr;
}

int duv_tcp_bind(uv_tcp_t* handle, struct sockaddr_in* addr) {
  return uv_tcp_bind(handle, *addr);
}

void duv_set_handle_data(uv_handle_t* handle, void* data) {
  handle->data = data;
}

void* duv_get_handle_data(uv_handle_t* handle) {
  return handle->data;
}

void duv_set_request_data(uv_req_t* handle, void* data) {
  handle->data = data;
}

void* duv_get_request_data(uv_req_t* handle) {
  return handle->data;
}

/*
uv_buf_t duv_alloc_callback(uv_handle_t* handle, size_t suggested_size) {
  printf("Allocating buffer with size %i\n", suggested_size);
  uv_buf_t buf = uv_buf_init((char*)malloc(suggested_size), suggested_size);
  return buf;
}*/

uv_write_t* duv_alloc_write() {
  return (uv_write_t*)malloc(sizeof(uv_write_t));
}

uv_timer_t* duv_alloc_timer() {
  return (uv_timer_t*)malloc(sizeof(uv_timer_t));
}

uv_connect_t* duv_alloc_connect() {
  return (uv_connect_t*)malloc(sizeof(uv_connect_t));
}

int duv_tcp_connect(uv_connect_t* req, uv_tcp_t* handle, struct sockaddr_in* addr, uv_connect_cb cb) {
  return uv_tcp_connect(req, handle, *addr, cb);
}
