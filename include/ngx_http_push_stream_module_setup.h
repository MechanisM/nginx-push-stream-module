/*
 * ngx_http_push_stream_module_setup.h
 *
 *  Created on: Oct 26, 2010
 *      Authors: Wandenberg Peixoto <wandenberg@gmail.com> & Rogério Schneider <stockrt@gmail.com>
 */

#ifndef NGX_HTTP_PUSH_STREAM_MODULE_SETUP_H_
#define NGX_HTTP_PUSH_STREAM_MODULE_SETUP_H_

#include <ngx_http_push_stream_module.h>
#include <ngx_http_push_stream_module_publisher.h>
#include <ngx_http_push_stream_module_subscriber.h>

#define NGX_HTTP_PUSH_STREAM_DEFAULT_SHM_SIZE       33554432 // 32 megs
static time_t NGX_HTTP_PUSH_STREAM_DEFAULT_MEMORY_CLEANUP_TIMEOUT = 30; // 30 seconds

#define NGX_HTTP_PUSH_STREAM_DEFAULT_HEADER_TEMPLATE  ""
#define NGX_HTTP_PUSH_STREAM_DEFAULT_MESSAGE_TEMPLATE ""

#define NGX_HTTP_PUSH_STREAM_DEFAULT_CONTENT_TYPE "text/plain"

#define NGX_HTTP_PUSH_STREAM_DEFAULT_BROADCAST_CHANNEL_PREFIX ""

// variables
static ngx_str_t    ngx_http_push_stream_channel_id = ngx_string("push_stream_channel_id");
static ngx_str_t    ngx_http_push_stream_channels_path = ngx_string("push_stream_channels_path");

static char *       push_stream_channels_statistics(ngx_conf_t *cf, ngx_command_t *cmd, void *conf);

// publisher
static char *       ngx_http_push_stream_publisher(ngx_conf_t *cf, ngx_command_t *cmd, void *conf);

// subscriber
static char *       ngx_http_push_stream_subscriber(ngx_conf_t *cf, ngx_command_t *cmd, void *conf);

// setup
static char *       ngx_http_push_stream_setup_handler(ngx_conf_t *cf, void *conf, ngx_int_t (*handler) (ngx_http_request_t *));
static ngx_int_t    ngx_http_push_stream_init_module(ngx_cycle_t *cycle);
static ngx_int_t    ngx_http_push_stream_init_worker(ngx_cycle_t *cycle);
static void         ngx_http_push_stream_exit_worker(ngx_cycle_t *cycle);
static void         ngx_http_push_stream_exit_master(ngx_cycle_t *cycle);
static ngx_int_t    ngx_http_push_stream_postconfig(ngx_conf_t *cf);
static void *       ngx_http_push_stream_create_main_conf(ngx_conf_t *cf);
static void *       ngx_http_push_stream_create_loc_conf(ngx_conf_t *cf);
static char *       ngx_http_push_stream_merge_loc_conf(ngx_conf_t *cf, void *parent, void *child);

// shared memory
static ngx_int_t    ngx_http_push_stream_set_up_shm(ngx_conf_t *cf, size_t shm_size);
static ngx_int_t    ngx_http_push_stream_init_shm_zone(ngx_shm_zone_t *shm_zone, void *data);

#endif /* NGX_HTTP_PUSH_STREAM_MODULE_SETUP_H_ */
