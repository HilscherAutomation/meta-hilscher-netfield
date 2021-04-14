#include <netana_user.h>
#include <netana_errors.h>

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#include <semaphore.h>
#include <sys/queue.h>

#include <wolfmqtt/mqtt_client.h>

#define MQTT_HOST "127.0.0.1"
#define MQTT_PORT 1883

static struct {
    const char* app_name;
    MqttClient client;
    MqttConnect connect;
    MqttNet net;
    MqttPublish publish;
    void* tx_buf;
    void* rx_buf;
} s_mqtt_context;

static bool s_fCaptureStopPending = false;

#define min(a, b) (((a) < (b)) ? (a) : (b))
#define max(a, b) (((a) > (b)) ? (a) : (b))

void timespec_substract(struct timespec *result, struct timespec *stop, struct timespec *start)
{
    if ((stop->tv_nsec - start->tv_nsec) < 0) {
        result->tv_sec = stop->tv_sec - start->tv_sec - 1;
        result->tv_nsec = stop->tv_nsec - start->tv_nsec + 1000000000;
    } else {
        result->tv_sec = stop->tv_sec - start->tv_sec;
        result->tv_nsec = stop->tv_nsec - start->tv_nsec;
    }

    return;
}

static int mqtt_message_cb(MqttClient *client, MqttMessage *msg,
    byte msg_new, byte msg_done)
{
    printf("message_cb, new=%d, done=%d\n", msg_new, msg_done);
    return MQTT_CODE_SUCCESS;
}

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/param.h>
#include <sys/time.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>

/* Setup defaults */
#ifndef SOCKET_T
    #define SOCKET_T        int
#endif
#ifndef SOERROR_T
    #define SOERROR_T       int
#endif
#ifndef SELECT_FD
    #define SELECT_FD(fd)   ((fd) + 1)
#endif
#ifndef SOCKET_INVALID
    #define SOCKET_INVALID  ((SOCKET_T)0)
#endif
#ifndef SOCK_CONNECT
    #define SOCK_CONNECT    connect
#endif
#ifndef SOCK_SEND
    #define SOCK_SEND(s,b,l,f) send((s), (b), (size_t)(l), (f))
#endif
#ifndef SOCK_RECV
    #define SOCK_RECV(s,b,l,f) recv((s), (b), (size_t)(l), (f))
#endif
#ifndef SOCK_CLOSE
    #define SOCK_CLOSE      close
#endif
#ifndef SOCK_ADDR_IN
    #define SOCK_ADDR_IN    struct sockaddr_in
#endif
#ifdef SOCK_ADDRINFO
    #define SOCK_ADDRINFO   struct addrinfo
#endif

/* Local context for Net callbacks */
typedef enum {
    SOCK_BEGIN = 0,
    SOCK_CONN,
} NB_Stat;

typedef struct _SocketContext {
    SOCKET_T fd;
    NB_Stat stat;
    SOCK_ADDR_IN addr;
} SocketContext;

/* -------------------------------------------------------------------------- */
/* GENERIC BSD SOCKET TCP NETWORK CALLBACK EXAMPLE */
/* -------------------------------------------------------------------------- */

static void setup_timeout(struct timeval* tv, int timeout_ms)
{
    tv->tv_sec = timeout_ms / 1000;
    tv->tv_usec = (timeout_ms % 1000) * 1000;

    /* Make sure there is a minimum value specified */
    if (tv->tv_sec < 0 || (tv->tv_sec == 0 && tv->tv_usec <= 0)) {
        tv->tv_sec = 0;
        tv->tv_usec = 100;
    }
}

static int NetConnect(void *context, const char* host, word16 port,
    int timeout_ms)
{
    SocketContext *sock = (SocketContext*)context;
    int type = SOCK_STREAM;
    int rc = -1;
    SOERROR_T so_error = 0;
    struct addrinfo *result = NULL;
    struct addrinfo hints;

    /* Get address information for host and locate IPv4 */
    switch(sock->stat) {
        case SOCK_BEGIN:
        {
            XMEMSET(&hints, 0, sizeof(hints));
            hints.ai_family = AF_INET;
            hints.ai_socktype = SOCK_STREAM;
            hints.ai_protocol = IPPROTO_TCP;

            XMEMSET(&sock->addr, 0, sizeof(sock->addr));
            sock->addr.sin_family = AF_INET;

            rc = getaddrinfo(host, NULL, &hints, &result);
            if (rc >= 0 && result != NULL) {
                struct addrinfo* res = result;

                /* prefer ip4 addresses */
                while (res) {
                    if (res->ai_family == AF_INET) {
                        result = res;
                        break;
                    }
                    res = res->ai_next;
                }

                if (result->ai_family == AF_INET) {
                    sock->addr.sin_port = htons(port);
                    sock->addr.sin_family = AF_INET;
                    sock->addr.sin_addr =
                        ((SOCK_ADDR_IN*)(result->ai_addr))->sin_addr;
                }
                else {
                    rc = -1;
                }

                freeaddrinfo(result);
            }
            if (rc != 0)
                goto exit;

            /* Default to error */
            rc = -1;

            /* Create socket */
            sock->fd = socket(sock->addr.sin_family, type, 0);
            if (sock->fd == SOCKET_INVALID)
                goto exit;

            sock->stat = SOCK_CONN;

            FALL_THROUGH;
        }

        case SOCK_CONN:
        {
            fd_set fdset;
            struct timeval tv;

            /* Setup timeout and FD's */
            setup_timeout(&tv, timeout_ms);
            FD_ZERO(&fdset);
            FD_SET(sock->fd, &fdset);

            /* Start connect */
            rc = SOCK_CONNECT(sock->fd, (struct sockaddr*)&sock->addr, sizeof(sock->addr));
            /* Wait for connect */
            if (rc < 0 || select((int)SELECT_FD(sock->fd), NULL, &fdset, NULL, &tv) > 0)
            {
                /* Check for error */
                socklen_t len = sizeof(so_error);
                getsockopt(sock->fd, SOL_SOCKET, SO_ERROR, &so_error, &len);
                if (so_error == 0) {
                    rc = 0; /* Success */
                }
            }
            break;
        }

        default:
            rc = -1;
    } /* switch */

    (void)timeout_ms;

exit:
    /* Show error */
    if (rc != 0) {
        PRINTF("NetConnect: Rc=%d, SoErr=%d", rc, so_error);
    }

    return rc;
}

static int NetWrite(void *context, const byte* buf, int buf_len,
    int timeout_ms)
{
    SocketContext *sock = (SocketContext*)context;
    int rc;
    SOERROR_T so_error = 0;
    struct timeval tv;

    if (context == NULL || buf == NULL || buf_len <= 0) {
        return MQTT_CODE_ERROR_BAD_ARG;
    }

    /* Setup timeout */
    setup_timeout(&tv, timeout_ms);
    setsockopt(sock->fd, SOL_SOCKET, SO_SNDTIMEO, (char *)&tv, sizeof(tv));

    rc = (int)SOCK_SEND(sock->fd, buf, buf_len, 0);
    if (rc == -1) {
        /* Get error */
        socklen_t len = sizeof(so_error);
        getsockopt(sock->fd, SOL_SOCKET, SO_ERROR, &so_error, &len);
        if (so_error == 0) {
            rc = 0; /* Handle signal */
        }
        else {
            rc = MQTT_CODE_ERROR_NETWORK;
            PRINTF("NetWrite: Error %d", so_error);
        }
    }

    (void)timeout_ms;

    return rc;
}

static int NetRead_ex(void *context, byte* buf, int buf_len,
    int timeout_ms, byte peek)
{
    SocketContext *sock = (SocketContext*)context;
    int rc = -1, timeout = 0;
    SOERROR_T so_error = 0;
    int bytes = 0;
    int flags = 0;
    fd_set recvfds;
    fd_set errfds;
    struct timeval tv;

    if (context == NULL || buf == NULL || buf_len <= 0) {
        return MQTT_CODE_ERROR_BAD_ARG;
    }

    if (peek == 1) {
        flags |= MSG_PEEK;
    }

    /* Setup timeout and FD's */
    setup_timeout(&tv, timeout_ms);
    FD_ZERO(&recvfds);
    FD_SET(sock->fd, &recvfds);
    FD_ZERO(&errfds);
    FD_SET(sock->fd, &errfds);

    #ifdef WOLFMQTT_ENABLE_STDIN_CAP
        FD_SET(STDIN, &recvfds);
    #endif

    /* Loop until buf_len has been read, error or timeout */
    while (bytes < buf_len) {

        /* Wait for rx data to be available */
        rc = select((int)SELECT_FD(sock->fd), &recvfds, NULL, &errfds, &tv);
        if (rc > 0)
        {
            /* Check if rx or error */
            if (FD_ISSET(sock->fd, &recvfds)) {

                /* Try and read number of buf_len provided,
                    minus what's already been read */
                rc = (int)SOCK_RECV(sock->fd,
                               &buf[bytes],
                               buf_len - bytes,
                               flags);
                if (rc <= 0) {
                    rc = -1;
                    goto exit; /* Error */
                }
                else {
                    bytes += rc; /* Data */
                }
            }
            if (FD_ISSET(sock->fd, &errfds)) {
                rc = -1;
                break;
            }
        }
        else {
            timeout = 1;
            break; /* timeout or signal */
        }
    } /* while */

exit:

    if (rc == 0 && timeout) {
        rc = MQTT_CODE_ERROR_TIMEOUT;
    }
    else if (rc < 0) {
        /* Get error */
        socklen_t len = sizeof(so_error);
        getsockopt(sock->fd, SOL_SOCKET, SO_ERROR, &so_error, &len);

        if (so_error == 0) {
            rc = 0; /* Handle signal */
        }
        else {
            rc = MQTT_CODE_ERROR_NETWORK;
            PRINTF("NetRead: Error %d", so_error);
        }
    }
    else {
        rc = bytes;
    }

    return rc;
}

static int NetRead(void *context, byte* buf, int buf_len, int timeout_ms)
{
    return NetRead_ex(context, buf, buf_len, timeout_ms, 0);
}

static int NetDisconnect(void *context)
{
    SocketContext *sock = (SocketContext*)context;
    if (sock) {
        if (sock->fd != SOCKET_INVALID) {
            SOCK_CLOSE(sock->fd);
            sock->fd = -1;
        }

        sock->stat = SOCK_BEGIN;
    }
    return 0;
}

#define MQTT_CHUNK_SIZE   4
#define MAX_DATA_POINTS   200
#define MAX_QUEUED_VALUES 500


struct data_entry {
    uint64_t timestamp;
    uint32_t len;
    uint8_t  bytes[MQTT_CHUNK_SIZE];
};

struct data_set_single {
    uint32_t idx;
    struct data_entry entry[MAX_QUEUED_VALUES];
};

struct data_set {
    STAILQ_ENTRY(data_set) list;

    uint32_t queued_values;
    struct data_set_single entries[MAX_DATA_POINTS];
};


static int s_fRunning = 1;
static STAILQ_HEAD(mqtt_list, data_set) s_tToMqttList = STAILQ_HEAD_INITIALIZER(s_tToMqttList);
static sem_t s_tMqttSemaphore;

static char mqttbuffer[8*1024*1024];

static void* mqtt_send_thread(void* param) {
    int rc;
    uint32_t idx;
    static uint16_t packetid = 1;

    while(s_fRunning) {
        struct timespec ts;
        clock_gettime(CLOCK_REALTIME, &ts);
        ts.tv_sec += 1;

        if(sem_timedwait(&s_tMqttSemaphore, &ts) == 0) {
            struct data_set *element;
            struct timespec tp_start, tp_end, tp_result;

            element = STAILQ_FIRST(&s_tToMqttList);
            if(NULL == element) continue;
            STAILQ_REMOVE_HEAD(&s_tToMqttList, list);
            clock_gettime(CLOCK_MONOTONIC, &tp_start);

            /* JSON conversion */
            clock_gettime(CLOCK_MONOTONIC, &tp_start);

            char* act_buffer = mqttbuffer;
            int written = 0;
            written = sprintf(act_buffer, "{\"c\":[");
            act_buffer += written;

            /* Iterate over slaves */
            for(idx = 0; idx < MAX_DATA_POINTS; idx++) {
                uint32_t data_idx;
                struct data_set_single *slave = &element->entries[idx];


                if(slave->idx > 0) {
                    written = sprintf(act_buffer, "{\"s\":%u,\"d\":[", idx);
                    act_buffer += written;

                    for(data_idx = 0; data_idx < slave->idx; data_idx++) {
                        struct data_entry *entry = &slave->entry[data_idx];

                        written = sprintf(act_buffer, "{\"t\":%lu,\"b\":\"%02X%02X%02X%02X\"},", entry->timestamp,
                                          entry->bytes[0], entry->bytes[1], entry->bytes[2], entry->bytes[3]);
                        act_buffer += written;
                    }

                    act_buffer--;
                    written = sprintf(act_buffer, "]},");
                    act_buffer += written;
                }
            }
            act_buffer--;
            written = sprintf(act_buffer, "]}");
            act_buffer += written;

            clock_gettime(CLOCK_MONOTONIC, &tp_end);
            timespec_substract(&tp_result, &tp_end, &tp_start);
            printf("JSON duration: %lu,%09lu\n", tp_result.tv_sec, tp_result.tv_nsec);

            /* MQTT Publishing */
            clock_gettime(CLOCK_MONOTONIC, &tp_start);

            s_mqtt_context.publish.topic_name = "netanalyzer/data";
            s_mqtt_context.publish.packet_id  = packetid++;
            s_mqtt_context.publish.qos        = 0;
            s_mqtt_context.publish.retain     = 0;
            s_mqtt_context.publish.buffer     = mqttbuffer;
            s_mqtt_context.publish.total_len  = (uint32_t)(act_buffer - mqttbuffer + 1);

            if(packetid == 0)
                packetid = 1;

            rc = MqttClient_Publish(&s_mqtt_context.client, &s_mqtt_context.publish);
            if(rc != MQTT_CODE_SUCCESS) {
                printf("Error delivering message (rc=%d)\n", rc);
            }

            clock_gettime(CLOCK_MONOTONIC, &tp_end);
            timespec_substract(&tp_result, &tp_end, &tp_start);
            printf("MQTT duration: %lu,%09lu\n", tp_result.tv_sec, tp_result.tv_nsec);

            free(element);
        }
    }
    return NULL;
}


/*===========================================================================
* Status change callback. Called by the driver if a function pointer was
* passed in netana_start_capture and the state of the card has changed
*============================================================================*/
static void APIENTRY StatusCallback(uint32_t ulCaptureState, uint32_t ulCaptureError, void* pvUser)
{
  switch(ulCaptureState)
  {
  case NETANA_CAPTURE_STATE_OFF:
    printf("\n-> Capture Stopped. ErrorCode=0x%08X (Status-Callback)\r\n", ulCaptureError);
    break;

  case NETANA_CAPTURE_STATE_START_PENDING:
    printf("\n-> Preparing Capture Start (Status-Callback).\r\n");
    break;

  case NETANA_CAPTURE_STATE_RUNNING:
    printf("\n-> Capture Running (Status-Callback).\r\n");
    break;

  case NETANA_CAPTURE_STATE_STOP_PENDING:
    printf("\n-> Capture Stop Pending. ErrorCode=0x%08X (Status-Callback)\r\n", ulCaptureError);
    s_fCaptureStopPending = true;
    break;

  default:
    printf("\n-> Unknown Capture State (%u). ErrorCode=0x%08X (Status-Callback)\r\n", ulCaptureState, ulCaptureError);
    break;
  }
}

static uint64_t s_ullBytesReceived;
static uint64_t s_ullFramesReceived;

static struct data_set *s_ptCurrentSet;

#define MQTT_CHUNK_SIZE 4
/*============================================================================
* New data indication callback. Called by the driver when new capture data has
* arrived.
*=============================================================================*/
static void APIENTRY DataCallback(void* pvBuffer, uint32_t ulDataSize, void* pvUser)
{
  uint8_t*  pbBuffer   = (uint8_t*)pvBuffer;
  uint32_t  ulOffset   = 0;

  while(ulOffset < ulDataSize)
  {
    NETANA_FRAME_HEADER_T* ptFrame  = (NETANA_FRAME_HEADER_T*)(pbBuffer + ulOffset);
    uint32_t ulFrameLen = (ptFrame->ulHeader & NETANA_FRAME_HEADER_LENGTH_MSK) >> NETANA_FRAME_HEADER_LENGTH_SRT;
    uint8_t* frame_data = (uint8_t*)(ptFrame+1);
    uint32_t idx;
    uint32_t max_idx = min(MAX_DATA_POINTS, ulFrameLen / MQTT_CHUNK_SIZE);

    if(NULL == s_ptCurrentSet) {
        s_ptCurrentSet = malloc(sizeof(*s_ptCurrentSet));
        memset(s_ptCurrentSet, 0, sizeof(*s_ptCurrentSet));
    }

    /* Split up frame into 4 byte chunks */
    for(idx = 0; idx < max_idx; idx++) {
        /* Save data to array */
        struct data_set_single *set = &s_ptCurrentSet->entries[idx];
        struct data_entry *entry    = &set->entry[set->idx];

        set->idx++;
        entry->timestamp = ptFrame->ullTimestamp;
        entry->len = MQTT_CHUNK_SIZE;
        memcpy(entry->bytes, frame_data + idx * MQTT_CHUNK_SIZE, MQTT_CHUNK_SIZE);
    }

    s_ullFramesReceived++;
    s_ullBytesReceived += ulFrameLen;

    /* Adjust Offset to next DWORD aligned address */
    ulOffset += sizeof(*ptFrame) + ulFrameLen;
    while(ulOffset % 4)
      ++ulOffset;

    s_ptCurrentSet->queued_values++;
    if(s_ptCurrentSet->queued_values >= MAX_QUEUED_VALUES) {
        STAILQ_INSERT_TAIL(&s_tToMqttList, s_ptCurrentSet, list);
        sem_post(&s_tMqttSemaphore);
        s_ptCurrentSet = NULL;
    }
  }

  if((s_ullFramesReceived % 1000) == 0)
    printf("Total Frames:%lu Total Bytes:=%lu\r\n", s_ullFramesReceived, s_ullBytesReceived);
}

/*============================================================================
* Start a capture
*=============================================================================*/
void DoCapture(NETANA_HANDLE hDevice)
{
  int32_t  lResult;
  /* Reference time for wireshark needs to be UNIX Timestamp (seconds sind 1.1.1970)
     and as we are using a nanosecond timestamp, we need to multiply it with 1000000000 */
  uint64_t ullReferenceTime = time(NULL) * 1000 * 1000 * 1000;

  if(NETANA_NO_ERROR != (lResult = netana_start_capture( hDevice,
                                                         0,
                                                         0xF,
                                                         NETANA_MACMODE_ETHERNET,
                                                         ullReferenceTime,
                                                         StatusCallback,
                                                         DataCallback,
                                                         NULL)))
  {
    printf("Error starting capture. ErrorCode=0x%08X\r\n", (uint32_t)lResult);

  } else
  {
    printf("\n!!!Press any key to stop capturing!!!\r\n");
    getchar();

    /* NOTE: We need to call netana_stop_capture even if the firmware stopped automatically,
             to tell the firmware we've understood that capturing was automatically stopped */
    netana_stop_capture(hDevice);
    printf("\nStopped Capturing...\r\n");
  }
}

/*=============================================================================
* Main
*==============================================================================*/
#define MAX_BUFFER_SIZE (8 * 1024 * 1024)
int main(void)
{
  int32_t                     lResult;
  NETANA_DRIVER_INFORMATION_T tDriverInfo   = {0};
  char*                       szDeviceToUse = NULL;
  uint32_t                    ulFilter      = (NETANA_DEV_CLASS_NANL_500 | NETANA_DEV_CLASS_NSCP_100| NETANA_DEV_CLASS_CIFX);

  /* Establish mqtt broker connection */
  int rc;
  s_mqtt_context.app_name = "netANALYZER";
  s_mqtt_context.tx_buf = (byte*)malloc(MAX_BUFFER_SIZE);
  s_mqtt_context.rx_buf = (byte*)malloc(MAX_BUFFER_SIZE);

  s_mqtt_context.net.connect = NetConnect;
  s_mqtt_context.net.read = NetRead;
  s_mqtt_context.net.write = NetWrite;
  s_mqtt_context.net.disconnect = NetDisconnect;
  s_mqtt_context.net.context = (SocketContext *)WOLFMQTT_MALLOC(sizeof(SocketContext));
  memset(s_mqtt_context.net.context, 0, sizeof(SocketContext));
  ((SocketContext*)(s_mqtt_context.net.context))->stat = SOCK_BEGIN;

  rc = MqttClient_Init(&s_mqtt_context.client, &s_mqtt_context.net,
        mqtt_message_cb,
        s_mqtt_context.tx_buf, MAX_BUFFER_SIZE,
        s_mqtt_context.rx_buf, MAX_BUFFER_SIZE,
        5000);

  if (rc != MQTT_CODE_SUCCESS) {
    printf("Failed to initialize MqttClient (%d)\n", rc);
    return -1;
  }

  rc = MqttClient_NetConnect(&s_mqtt_context.client, MQTT_HOST, MQTT_PORT,
                             1000, 0, NULL);
  if (rc != MQTT_CODE_SUCCESS) {
    printf("Failed to connect to MQTT broker (%d)\n", rc);
    return -1;
  }

  printf("******************** netAnalyzer Demo Application ********************\n\n");

  printf("Gathering driver information...\n");
  printf("----------------------------------------\r\n");

  netana_mngmt_exec_cmd(NETANA_MNGMT_CMD_SET_DEV_CLASS_FILTER,
                        &ulFilter, sizeof(ulFilter),
                        NULL, 0);

  /* Try to open the driver */                                                   
  if(NETANA_NO_ERROR != (lResult = netana_driver_information(sizeof(tDriverInfo), &tDriverInfo)))
  {
    printf("Error opening driver. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
  } else
  {
    printf("Driver Version\t: %u.%u.%u.%u\r\n\n", tDriverInfo.ulVersionMajor, 
                                                  tDriverInfo.ulVersionMinor, 
                                                  tDriverInfo.ulVersionBuild, 
                                                  tDriverInfo.ulVersionRevision);

    printf("Toolkit Version\t: %u.%u.%u.%u\r\n\n", tDriverInfo.ulToolkitVersionMajor, 
                                                   tDriverInfo.ulToolkitVersionMinor, 
                                                   tDriverInfo.ulToolkitVersionBuild, 
                                                   tDriverInfo.ulToolkitVersionRevision);

    lResult = netana_driver_information(sizeof(tDriverInfo), &tDriverInfo);

    if (tDriverInfo.ulCardCnt)
    {
      printf("Gathering device information...\n");
      printf("----------------------------------------\r\n");

      printf(" Cards       : %u\r\n", tDriverInfo.ulCardCnt);
      printf(" DMA Buffers : %u x %u Bytes\r\n", tDriverInfo.ulDMABufferCount, tDriverInfo.ulDMABufferSize);
      printf(" Max Files   : %u\r\n", tDriverInfo.ulMaxFileCount);

      printf(" Found cards : %d\r\n", tDriverInfo.ulCardCnt);

      /* Enumerate all available boards and use the first found one, to do our tests */
      for(uint32_t ulCard = 0; ulCard < tDriverInfo.ulCardCnt; ulCard++)
      {
        NETANA_DEVICE_INFORMATION_T tDevInfo = {0};

        if(NETANA_NO_ERROR != (lResult = netana_enum_device(ulCard, sizeof(tDevInfo), &tDevInfo)))
        {
          printf("\n[%u]: Error enumerating card #%u. ErrorCode=0x%08X\r\n", ulCard, ulCard, (uint32_t)lResult);

        } else
        {
          if(NULL == szDeviceToUse)
          {
            /* NOTE: We will always use the first available device for our tests */
            szDeviceToUse = strdup((char*)tDevInfo.szDeviceName);
          }

          printf("\n[%u]:\tDeviceName = '%s'\r\n", ulCard, (char*)tDevInfo.szDeviceName);
          printf("\tDeviceNr   = %u\n\tSerialNr   = %u\r\n", tDevInfo.ulDeviceNr, tDevInfo.ulSerialNr);
          printf("\tFirmware   = %s V%u.%u.%u.%u\r\n",
                 (char*)tDevInfo.szFirmwareName,
                 tDevInfo.ulVersionMajor, 
                 tDevInfo.ulVersionMinor, 
                 tDevInfo.ulVersionBuild, 
                 tDevInfo.ulVersionRevision); 
          printf("\tPorts      = %u\n\tGPIOs      = %u\n\tFilterSize = %u\r\n",
                 tDevInfo.ulPortCnt, 
                 tDevInfo.ulGpioCnt, 
                 tDevInfo.ulFilterSize);

        }
      }
    }

    if(NULL == szDeviceToUse)
    {
      printf("\nNo device found for further testing\r\n");

    } else
    {
      NETANA_HANDLE hDevice = NULL;

      printf("\nStarting tests on Device '%s'\r\n", szDeviceToUse);
      printf("----------------------------------------\r\n");

      /* Get a handle to the device */
      if(NETANA_NO_ERROR != (lResult = netana_open_device(szDeviceToUse, &hDevice)))
      {
        printf("Error opening device '%s'. ErrorCode=0x%08X\r\n", szDeviceToUse, (uint32_t)lResult);

      } else
      {
        pthread_t thread;

        sem_init(&s_tMqttSemaphore, 0, 0);
        pthread_create(&thread, NULL, mqtt_send_thread, NULL);

        s_mqtt_context.connect.keep_alive_sec = 180;
        s_mqtt_context.connect.clean_session = 0;
        s_mqtt_context.connect.client_id = s_mqtt_context.app_name;

        rc = MqttClient_Connect(&s_mqtt_context.client, &s_mqtt_context.connect);
        if(rc != MQTT_CODE_SUCCESS) {
            printf("Failed to connect to broker (%d)\n", rc);
            return -1;
        }

        /* start capturing */
        DoCapture(hDevice);

        printf("\nTest ended!\r\n");
        printf("----------------------------------------\r\n");
        netana_close_device(hDevice);

        MqttClient_Disconnect(&s_mqtt_context.client);
        MqttClient_NetDisconnect(&s_mqtt_context.client);
        free(s_mqtt_context.rx_buf);
        free(s_mqtt_context.tx_buf);

        s_fRunning = 0;
        sem_post(&s_tMqttSemaphore);
        pthread_join(thread, NULL);

        sem_destroy(&s_tMqttSemaphore);
      }
    }
  }

  return 0;
}
