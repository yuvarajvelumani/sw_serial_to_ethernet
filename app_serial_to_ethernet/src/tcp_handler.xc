#include "xtcp_client.h"
#include "uart_config.h"
#include "telnet_to_uart.h"
#include "telnet_config.h"
#include "s2e_webserver.h"
#include "web_server.h"
#include "mutual_thread_comm.h"
#include "tcp_handler.h"
#include "udp_discovery.h"
#include <xs1.h>

void tcp_handler(chanend c_xtcp,
                 chanend c_uart_data,
                 chanend c_uart_config,
                 chanend ?c_flash_web,
                 chanend ?c_flash_data)
{
  timer tmr;
  int t;

  tmr :> t;
  uart_config_init(c_uart_config);
  telnet_to_uart_init(c_xtcp, c_uart_data);
  telnet_config_init(c_xtcp);
  udp_discovery_init(c_xtcp);
  s2e_webserver_init(c_xtcp, c_flash_web, c_uart_config, c_flash_data);

  while (1) {
    xtcp_connection_t conn;
    int is_data_request;

    select
      {
      case xtcp_event(c_xtcp, conn):
        telnet_to_uart_event_handler(c_xtcp, c_uart_data, conn);
        telnet_config_event_handler(c_xtcp, c_uart_config, c_flash_data, conn);
        udp_discovery_event_handler(c_xtcp, c_uart_config, conn);
        s2e_webserver_event_handler(c_xtcp, c_flash_web, c_uart_config, conn);
        break;
      case telnet_to_uart_notification_handler(c_xtcp, c_uart_data);
#ifdef WEB_SERVER_USE_FLASH
      case web_server_cache_request(c_flash_web):
        web_server_cache_handler(c_flash_web, c_xtcp);
        break;
#endif
      }
  }
}
