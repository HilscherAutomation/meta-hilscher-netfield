///////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2000-2003 Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// * Neither name of Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL INTEL OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
// OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
///////////////////////////////////////////////////////////////////////////


#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>

#include <sys/types.h>
#include <ifaddrs.h>

#include "ithread.h"

#include "upnp.h"

#define DEFAULT_WEB_DIR "./web"

#define DESC_URL_SIZE 200

/*
 * Device handle supplied by UPnP SDK
 */
UpnpDevice_Handle device_handle = -1;

/*
 * Mutex for protecting the global state table data
 * in a multi-threaded, asynchronous environment.
 * All functions should lock this mutex before reading
 * or writing the state table data.
 */
ithread_mutex_t DevMutex;

/*! The amount of time (in seconds) before advertisements will expire. */
int default_advr_expire = 100;

/******************************************************************************
 * linux_print
 *
 * Description:
 *       Prints a string to standard out.
 *
 * Parameters:
 *    None
 *
 *****************************************************************************/
void
linux_print( char *fmt,
             ... )
{
  va_list ap;
  char buf[200];
  int rc;

  va_start( ap, fmt );
  rc = vsnprintf( buf, 200, fmt, ap );
  va_end( ap );

  fprintf(stderr, "%s", buf );
}

/******************************************************************************
 * DeviceCallbackEventHandler
 *
 * Description:
 *       The callback handler registered with the SDK while registering
 *       root device.  Dispatches the request to the appropriate procedure
 *       based on the value of EventType. The four requests handled by the
 *       device are:
 *                   1) Event Subscription requests.
 *                   2) Get Variable requests.
 *                   3) Action requests.
 *
 * Parameters:
 *
 *   EventType -- The type of callback event
 *   Event -- Data structure containing event data
 *   Cookie -- Optional data specified during callback registration
 *
 *****************************************************************************/
int
DeviceCallbackEventHandler( Upnp_EventType EventType,
                            const void *Event,
                              void *Cookie )
{

  switch ( EventType ) {
    case UPNP_EVENT_SUBSCRIPTION_REQUEST:
    case UPNP_CONTROL_GET_VAR_REQUEST:
    case UPNP_CONTROL_ACTION_REQUEST:
    case UPNP_DISCOVERY_ADVERTISEMENT_ALIVE:
    case UPNP_DISCOVERY_SEARCH_RESULT:
    case UPNP_DISCOVERY_SEARCH_TIMEOUT:
    case UPNP_DISCOVERY_ADVERTISEMENT_BYEBYE:
    case UPNP_CONTROL_ACTION_COMPLETE:
    case UPNP_CONTROL_GET_VAR_COMPLETE:
    case UPNP_EVENT_RECEIVED:
    case UPNP_EVENT_RENEWAL_COMPLETE:
    case UPNP_EVENT_SUBSCRIBE_COMPLETE:
    case UPNP_EVENT_UNSUBSCRIBE_COMPLETE:
      break;

    default:
      linux_print
      ( "Error in DeviceCallbackEventHandler: unknown event type %d\n",
        EventType );
  }

  /*
   *       Print a summary of the event received
   */
  //SampleUtil_PrintEvent( EventType, Event );
  return ( 0 );
}

/******************************************************************************
 * DeviceStop
 *
 * Description:
 *       Stops the device. Uninitializes the sdk.
 *
 * Parameters:
 *
 *****************************************************************************/
int
DeviceStop()
{
  UpnpUnRegisterRootDevice( device_handle );
  UpnpFinish();
  ithread_mutex_destroy( &DevMutex );
  return UPNP_E_SUCCESS;
}

/******************************************************************************
 * DeviceStart
 *
 * Description:
 *      Initializes the UPnP Sdk, registers the device, and sends out
 *      advertisements.
 *
 * Parameters:
 *
 *   interface  - interface to initialize the sdk (must not be NULL)
 *   port       - port number to initialize the sdk (may be 0)
 *                if zero, then a random number is used.
 *   desc_doc_name - name of description document.
 *                   may be NULL. Default is tvdevicedesc.xml
 *   web_dir_path  - path of web directory.
 *                   may be NULL. Default is ./web (for Linux) or ../tvdevice/web
 *                   for windows.
 *
 *****************************************************************************/
int
DeviceStart( char *interface,
               unsigned short port,
               char *desc_doc_name,
               char *web_dir_path,
               unsigned short ext_web_server_port,
               char *ext_web_server)
{
  int ret = UPNP_E_SUCCESS;
  char desc_doc_url[DESC_URL_SIZE];
  char* ip_address = NULL;

  ithread_mutex_init( &DevMutex, NULL );

  if( ( ret = UpnpInit2( interface, port ) ) != UPNP_E_SUCCESS ) {
    linux_print( "Error with UpnpInit -- %d\n", ret );
    UpnpFinish();
    return ret;
  }

  ip_address = UpnpGetServerIpAddress();
  port = UpnpGetServerPort();

  linux_print(
    "Initializing UPnP Sdk with\n"
    "\tipaddress = %s port = %u\n",
    ip_address, port );

  if (ext_web_server == NULL) {
    linux_print("External Webserver is required!!!!\n");
    UpnpFinish();
    return -1;
  } else {
    if(ext_web_server_port == 0)
        snprintf( desc_doc_url, DESC_URL_SIZE, "http://%s/%s", ip_address,
              ext_web_server );
    else
        snprintf( desc_doc_url, DESC_URL_SIZE, "http://%s:%d/%s", ip_address,
              ext_web_server_port, ext_web_server );
  }
  linux_print(
    "Registering the RootDevice\n"
    "\t with desc_doc_url: %s\n",
    desc_doc_url );

  if( ( ret = UpnpRegisterRootDevice(desc_doc_url,
    DeviceCallbackEventHandler,
    &device_handle, &device_handle ) )
    != UPNP_E_SUCCESS ) {
    linux_print( "Error registering the rootdevice : %d\n", ret );
    UpnpFinish();
    return ret;
  } else {
    if( ( ret =
          UpnpSendAdvertisement( device_handle, default_advr_expire ) )
        != UPNP_E_SUCCESS ) {
        linux_print( "Error sending advertisements : %d\n", ret );
        UpnpFinish();
        return ret;
    }
    linux_print("Advertisements Sent\n");
  }
  return UPNP_E_SUCCESS;
}

/******************************************************************************
 * TvDeviceCommandLoop
 *
 * Description:
 *       Function that receives commands from the user at the command prompt
 *       during the lifetime of the device, and calls the appropriate
 *       functions for those commands. Only one command, exit, is currently
 *       defined.
 *
 * Parameters:
 *    None
 *
 *****************************************************************************/
void *
TvDeviceCommandLoop( void *args )
{
  int stoploop = 0;
  char cmdline[100];
  char cmd[100];
  char *s;

  while( !stoploop ) {
    sprintf( cmdline, " " );
    sprintf( cmd, " " );

    linux_print( "\n>> " );

    // Get a command line
    s = fgets( cmdline, 100, stdin );
    if (!s)
      break;

    sscanf( cmdline, "%s", cmd );

    if( strcasecmp( cmd, "exit" ) == 0 ) {
      linux_print( "Shutting down...\n" );
      DeviceStop();
      exit( 0 );
    } else {
      linux_print( "\n   Unknown command: %s\n\n", cmd );
      linux_print( "   Valid Commands:\n" );
      linux_print( "     Exit\n\n" );
    }
  }
  return NULL;
}

void get_ip_of_if(char* ifname, char *ip)
{
  struct ifaddrs *ifap, *ifa;
  char *default_dev = "eth0";
  const char *p = NULL;
  char tempstr[INET_ADDRSTRLEN];

  if (getifaddrs(&ifap) != 0) {
    linux_print("DiscoverInterfaces: getifaddrs() returned error\n");
  }
  if (ifname == NULL)
    ifname = default_dev;

  /* cycle through available interfaces */
  for (ifa = ifap; ifa != NULL; ifa = ifa->ifa_next) {
    if (strcmp(ifa->ifa_name, ifname) == 0) {
      if (ifa->ifa_addr == NULL)
        continue;

      if (ifa->ifa_addr->sa_family == AF_INET) {
        int i=0;
        p = inet_ntoa(((struct sockaddr_in *)(ifa->ifa_addr))->sin_addr);
        if (p) {
          strncpy(ip, p, INET_ADDRSTRLEN);
        } else {
          linux_print("getlocalhostname: inet_ntop returned error\n");
        }
        linux_print("ssdp runs on %s: %s\n", ifname, ip);
        break;
      }
    }
  }
  freeifaddrs(ifap);
}

/******************************************************************************
 * main
 *
 * Description:
 *       Main entry point for tv device application.
 *       Initializes and registers with the sdk.
 *       Initializes the state stables of the service.
 *       Starts the command loop.
 *
 * Parameters:
 *    int argc  - count of arguments
 *    char ** argv -arguments. The application
 *                  accepts the following optional arguments:
 *
 *                  -ip ipaddress
 *                  -port port
 *                  -desc desc_doc_name
 *                  -webdir web_dir_path"
 *                  -help
 *
 *
 *****************************************************************************/
int main( int argc, char **argv )
{

  unsigned int portTemp = 0, extportTemp = 0;
  char *desc_doc_name = NULL,
    *web_dir_path = NULL,
    *external_web_server = NULL,
    *iface = NULL;
  char ip[INET_ADDRSTRLEN];
  int rc;
  ithread_t cmdloop_thread;
  int sig;
  sigset_t sigs_to_catch;
  int code;
  unsigned int port = 0, extport = 0;
  int i = 0;

  // Parse options
  for( i = 1; i < argc; i++ ) {
    if( strcmp( argv[i], "-port" ) == 0 ) {
      sscanf( argv[++i], "%u", &portTemp );
    } else if( strcmp( argv[i], "-desc" ) == 0 ) {
      desc_doc_name = argv[++i];
    } else if( strcmp( argv[i], "-webdir" ) == 0 ) {
      web_dir_path = argv[++i];
    } else if( strcmp( argv[i], "-extweb" ) == 0 ) {
      external_web_server = argv[++i];
    } else if( strcmp( argv[i], "-extport" ) == 0 ) {
      sscanf( argv[++i], "%u", &extportTemp );
    } else if( strcmp( argv[i], "-if" ) == 0 ) {
      iface = argv[++i];
    } else if( strcmp( argv[i], "-help" ) == 0 ) {
      linux_print( "Usage: %s -if interface -port port"
                        " -desc desc_doc_name -webdir web_dir_path"
                        " -help (this message)\n", argv[0] );
      linux_print( "\tinterface:     interface to use\n" );
      linux_print( "\t\te.g.: eth0\n" );
      linux_print( "\tport:          Port number to use for "
                        "receiving UPnP messages (must match desc. doc)\n" );
      linux_print( "\t\te.g.: 5431\n" );
      linux_print
          ( "\tdesc_doc_name: name of device description document\n" );
      linux_print( "\t\te.g.: netiotdevicedesc.xml\n" );
      linux_print
          ( "\tweb_dir_path: Filesystem path where web files "
            "related to the device are stored\n" );
      linux_print( "\t\te.g.: /upnp/sample/tvdevice/web\n" );
      return 1;
    }
  }

  if (!iface) {
    linux_print( "!! No interface specificed !!\n" );
    exit(1);
  }

  port = ( unsigned short )portTemp;
  extport = ( unsigned short )extportTemp;

  rc = DeviceStart( iface, port, desc_doc_name, web_dir_path, extport, external_web_server);
  if (rc == 0) {
    /*
      Catch Ctrl-C and properly shutdown
    */
    sigemptyset( &sigs_to_catch );
    sigaddset( &sigs_to_catch, SIGINT );
    sigwait( &sigs_to_catch, &sig );

    linux_print( "Shutting down on signal %d...\n", sig );
    if ((rc = DeviceStop()) != 0) {
      rc = 0;
      linux_print( "Device stopping failed with %d...\n", rc );
    }
  } else {
    linux_print( "Failed to start service on if=%s (error=%d)...\n", iface,  rc);
  }
  return rc;
}
