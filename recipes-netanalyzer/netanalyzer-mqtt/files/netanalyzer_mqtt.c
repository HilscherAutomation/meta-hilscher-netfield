#include <netana_user.h>
#include <netana_errors.h>

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#include <semaphore.h>
#include <sys/queue.h>

#include <MQTTClient.h>
#include <jansson.h>

#define MQTT_ADDRESS "tcp://localhost:1883"
static MQTTClient s_mqtt_client;
static MQTTClient_message s_mqtt_message = MQTTClient_message_initializer;

#define min(a, b) (((a) < (b)) ? (a) : (b))
#define max(a, b) (((a) > (b)) ? (a) : (b))

static bool s_fCaptureStopPending = false;

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

#define USE_JSON 1

static void* mqtt_send_thread(void* param) {
    MQTTClient_deliveryToken token;
    char* s = NULL;
    int rc;
    uint32_t idx;

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

            s_mqtt_message.payload = element;
            s_mqtt_message.payloadlen = sizeof(*element);

#ifdef USE_JSON
            clock_gettime(CLOCK_MONOTONIC, &tp_start);
            json_t *root = json_object();

            /* JSON format: 
              {
               [ {slave:"offset_x" data:[{timestamp:x, bytes:"AABBCCDD"}, ...]}, 
               ]
              }
            */
            json_t *json_arr = json_array();

            /* Iterate over slaves */
            for(idx = 0; idx < MAX_DATA_POINTS; idx++) {
                uint32_t data_idx;
                struct data_set_single *slave = &element->entries[idx];

                if(slave->idx > 0) {
                    json_t *slave_obj = json_object();
                    json_t *data_arr  = json_array();

                    json_object_set_new(slave_obj, "s", json_integer(idx));

                    for(data_idx = 0; data_idx < slave->idx; data_idx++) {
                        char data_str[MQTT_CHUNK_SIZE * 2 + 1];
                        struct data_entry *entry = &slave->entry[data_idx];

                        json_t *data_obj = json_object();
                        json_object_set_new(data_obj, "t", json_integer(entry->timestamp));
                        sprintf(data_str, "%02X%02X%02X%02X", entry->bytes[0], entry->bytes[1], entry->bytes[2], entry->bytes[3]);
                        json_object_set_new(data_obj, "b", json_string(data_str));

                        json_array_append(data_arr, data_obj);
                    }
                    json_object_set_new( slave_obj, "d", data_arr);
                    json_array_append(json_arr, slave_obj);
                }
            }

            json_object_set_new(root, "c", json_arr);

            s = json_dumps(root, 0);

            clock_gettime(CLOCK_MONOTONIC, &tp_end);
            timespec_substract(&tp_result, &tp_end, &tp_start);
            printf("JSON duration: %lu,%09lu\n", tp_result.tv_sec, tp_result.tv_nsec);

            s_mqtt_message.payload = s;
            s_mqtt_message.payloadlen = strlen(s);
#endif
            /* TODO: Build JSON with aggregated / timestamped data */
            s_mqtt_message.qos = 0;
            s_mqtt_message.retained = 0;

            clock_gettime(CLOCK_MONOTONIC, &tp_start);

            MQTTClient_publishMessage(s_mqtt_client, "netanalyzer/data", &s_mqtt_message, &token);
            rc = MQTTClient_waitForCompletion(s_mqtt_client, token, 100);
            if(rc != MQTTCLIENT_SUCCESS) {
                printf("Error delivering message with token %d (rc=%d)\n", token, rc);
            }

            clock_gettime(CLOCK_MONOTONIC, &tp_end);
            timespec_substract(&tp_result, &tp_end, &tp_start);
            printf("MQTT duration: %lu,%09lu\n", tp_result.tv_sec, tp_result.tv_nsec);

            free(element);
#ifdef USE_JSON
            free(s);
            json_decref(root);
#endif
        }
    }
    return NULL;
}

static struct data_set *s_ptCurrentSet;

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
int main(void)
{
  int32_t                     lResult;
  NETANA_DRIVER_INFORMATION_T tDriverInfo   = {0};
  char*                       szDeviceToUse = NULL;
  uint32_t                    ulFilter      = (NETANA_DEV_CLASS_NANL_500 | NETANA_DEV_CLASS_NSCP_100| NETANA_DEV_CLASS_CIFX);

  /* Establish mqtt broker connection */
  int rc;
  MQTTClient_connectOptions conn_opts = MQTTClient_connectOptions_initializer;
  conn_opts.keepAliveInterval = 20;
  conn_opts.cleansession = 1;

  MQTTClient_create(&s_mqtt_client, MQTT_ADDRESS, "netANALYZER", MQTTCLIENT_PERSISTENCE_NONE, NULL);


  if ((rc = MQTTClient_connect(s_mqtt_client, &conn_opts)) != MQTTCLIENT_SUCCESS) {
    printf("Failed to connect to MQTT broker %s (%d)\n", MQTT_ADDRESS, rc);
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

        /* start capturing */
        DoCapture(hDevice);

        printf("\nTest ended!\r\n");
        printf("----------------------------------------\r\n");
        netana_close_device(hDevice);

        MQTTClient_disconnect(s_mqtt_client, 10000);
        MQTTClient_destroy(&s_mqtt_client);

        s_fRunning = 0;
        sem_post(&s_tMqttSemaphore);
        pthread_join(thread, NULL);

        sem_destroy(&s_tMqttSemaphore);
      }
    }
  }

  return 0;
}
