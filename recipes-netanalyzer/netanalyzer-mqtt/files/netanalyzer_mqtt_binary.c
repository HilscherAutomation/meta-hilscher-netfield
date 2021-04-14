#include <netana_user.h>
#include <netana_errors.h>

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#include <MQTTClient.h>

#define MQTT_ADDRESS "tcp://localhost:1883"
static MQTTClient s_mqtt_client;
static MQTTClient_message s_mqtt_message = MQTTClient_message_initializer;

static bool s_fCaptureStopPending = false;

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
static uint32_t s_ulCallbackCount;

#define MQTT_CHUNK_SIZE 4

/*============================================================================
* New data indication callback. Called by the driver when new capture data has
* arrived.
*=============================================================================*/
static void APIENTRY DataCallback(void* pvBuffer, uint32_t ulDataSize, void* pvUser)
{
  uint8_t*  pbBuffer   = (uint8_t*)pvBuffer;
  uint32_t  ulOffset   = 0;
  int rc;

  MQTTClient_deliveryToken token;

  while(ulOffset < ulDataSize)
  {
    NETANA_FRAME_HEADER_T* ptFrame  = (NETANA_FRAME_HEADER_T*)(pbBuffer + ulOffset);
    uint32_t ulFrameLen = (ptFrame->ulHeader & NETANA_FRAME_HEADER_LENGTH_MSK) >> NETANA_FRAME_HEADER_LENGTH_SRT;
    uint8_t* frame_data = (uint8_t*)(ptFrame+1);
    uint32_t idx;

    s_mqtt_message.qos = 0;
    s_mqtt_message.retained = 0;

    s_mqtt_message.payload = frame_data;
    s_mqtt_message.payloadlen = ulFrameLen;

    MQTTClient_publishMessage(s_mqtt_client, "netanalyzer/frame", &s_mqtt_message, &token);
    rc = MQTTClient_waitForCompletion(s_mqtt_client, token, 100);
    if(rc != MQTTCLIENT_SUCCESS) {
      printf("Error delivering message with token %d (rc=%d)\n", token, rc);
    }

    s_ullFramesReceived++;
    s_ullBytesReceived += ulFrameLen;

    /* Adjust Offset to next DWORD aligned address */
    ulOffset += sizeof(*ptFrame) + ulFrameLen;
    while(ulOffset % 4)
      ++ulOffset;
  }

  if(++s_ulCallbackCount > 16) {
    printf("Total Frames:%llu Total Bytes:=%llu\r\n", s_ullFramesReceived, s_ullBytesReceived);
    s_ulCallbackCount = 0;
  }
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
        /* start capturing */
        DoCapture(hDevice);

        printf("\nTest ended!\r\n");
        printf("----------------------------------------\r\n");
        netana_close_device(hDevice);

        MQTTClient_disconnect(s_mqtt_client, 10000);
        MQTTClient_destroy(&s_mqtt_client);
      }
    }
  }

  return 0;
}
