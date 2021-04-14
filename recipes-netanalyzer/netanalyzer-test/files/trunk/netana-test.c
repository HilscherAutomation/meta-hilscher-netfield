// netANALYZER_Demo.cpp : Defines the entry point for the console application.
//

#include <netana_user.h>
#include <netana_errors.h>
#include "OS_Dependent.h"

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <inttypes.h>

#define DRIVER_VERSION_V1402 /* can be enabled, for driver versions later than V1.4.0.2 */
#define NETANA_GBE_VARIANT 0x00476245

/* list of available devices */
char **aszDeviceNames = NULL;

/*** filters ***/
#define MAX_FILTER_SIZE 512

NETANA_FILTER_T tFilterA = {0};
uint8_t abFilterMaskA[MAX_FILTER_SIZE] = {0};
uint8_t abFilterValueA[MAX_FILTER_SIZE] = {0};
NETANA_FILTER_T tFilterB = {0};
uint8_t abFilterMaskB[MAX_FILTER_SIZE] = {0};
uint8_t abFilterValueB[MAX_FILTER_SIZE] = {0};
uint32_t ulRelation;

uint32_t ulTotalErrorFrames = 0;

void ConfigureFilters(NETANA_HANDLE hDevice)
{
  int32_t lResult;
  uint32_t ulIdx;

  for (ulIdx = 0; ulIdx < MAX_FILTER_SIZE; ulIdx++)
  {
    abFilterMaskA[ulIdx] ^= 0xFF;
    abFilterMaskA[ulIdx] ^= 0xFF;
    abFilterValueA[ulIdx] ^= 0xFF;
    abFilterValueA[ulIdx] ^= 0xFF;
    abFilterMaskB[ulIdx] ^= 0xFF;
    abFilterMaskB[ulIdx] ^= 0xFF;
    abFilterValueB[ulIdx] ^= 0xFF;
    abFilterValueB[ulIdx] ^= 0xFF;
  }

  tFilterA.ulFilterSize = sizeof(abFilterMaskA);
  tFilterA.pbMask = abFilterMaskA;
  tFilterA.pbValue = abFilterValueA;

  tFilterB.ulFilterSize = sizeof(abFilterMaskB);
  tFilterB.pbMask = abFilterMaskB;
  tFilterB.pbValue = abFilterValueB;

  ulRelation = NETANA_FILTER_RELATION_FILTER_A_ENABLE |
               NETANA_FILTER_RELATION_FILTER_B_ENABLE |
               NETANA_FILTER_RELATION_A_OR_B |
               NETANA_FILTER_RELATION_ACCEPT_FILTER;

  if (NETANA_NO_ERROR != (lResult = netana_set_filter(hDevice,
                                                      0,
                                                      &tFilterA,
                                                      &tFilterB,
                                                      ulRelation)))
  {
    printf("\nError setting filters on port 0. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
  }
  else
  {
    printf("\nSuccessfully set filters on Port 0\r\n");
  }
}

AccessPhyReg(NETANA_HANDLE hDevice)
{
  int32_t lResult;
  uint32_t ulIdx;

  uint8_t  ubPort  = 0;
  uint16_t usValueADd = 0;
  uint16_t usValueADh = (1 << 12); //#| (1 << 9) reset autoneg (Self Clearing)
  uint16_t usValueADhReA = (1 << 12) | (1 << 9); //# (1 << 13) | (1 << 8) | (1 << 9)
  uint8_t  ubRegisterNr = 0;
  uint32_t ulTimeout = 10;

  // set phy to 10 mbit/s h fixed aneg off
  if (NETANA_NO_ERROR != (lResult = netana_access_phy_reg( hDevice,
                                                           NETANA_PHY_DIRECTION_WRITE,
                                                           ubPort,
                                                           ubRegisterNr,
                                                           usValueADd,
                                                           ulTimeout)))
  {
    printf("\nError setting phy on port 0. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
  }
  else
  {
    printf("\nSuccessfully set phy on Port 0\r\n");
  }
}

/*** capture  ***/
static void APIENTRY StatusCallback(uint32_t ulCaptureState, uint32_t ulCaptureError, void *pvUser)
{
  switch (ulCaptureState)
  {
  case NETANA_CAPTURE_STATE_OFF:
    printf("\n-> Capture Stopped. ErrorCode=0x%08X (Status-Callback)\r\n",
           ulCaptureError);
    break;

  case NETANA_CAPTURE_STATE_START_PENDING:
    printf("\n-> Preparing Capture Start (Status-Callback).\r\n");
    break;

  case NETANA_CAPTURE_STATE_RUNNING:
    printf("\n-> Capture Running (Status-Callback).\r\n");
    break;

  case NETANA_CAPTURE_STATE_STOP_PENDING:
    printf("\n-> Capture Stop Pending. ErrorCode=0x%08X (Status-Callback)\r\n",
           ulCaptureError);
    break;

  default:
    printf("\n-> Unknown Capture State (%u). ErrorCode=0x%08X (Status-Callback)\r\n",
           ulCaptureState, ulCaptureError);
    break;
  }
}

static void APIENTRY IgnoreDataCallback(void *pvBuffer, uint32_t ulDataSize, void *pvUser)
{
}


static void APIENTRY DataCallback(void *pvBuffer, uint32_t ulDataSize, void *pvUser)
{
  uint8_t *pbBuffer = (uint8_t *)pvBuffer;
  uint32_t ulOffset = 0;
  uint32_t ulFrameCnt = 0;

  while (ulOffset < ulDataSize)
  {
    NETANA_FRAME_HEADER_T *ptFrame = (NETANA_FRAME_HEADER_T *)(pbBuffer + ulOffset);
    uint32_t ulFrameLen = (ptFrame->ulHeader & NETANA_FRAME_HEADER_LENGTH_MSK) >> NETANA_FRAME_HEADER_LENGTH_SRT;
    uint32_t ulError = (ptFrame->ulHeader & NETANA_FRAME_HEADER_ERROR_CODE_MSK) >> NETANA_FRAME_HEADER_ERROR_CODE_SRT;
    if (ulError != 0) 
    {
      ulTotalErrorFrames++;
    }

    ulFrameCnt++;

    /* Adjust Offset to next DWORD aligned address */
    ulOffset += sizeof(*ptFrame) + ulFrameLen;
    while (ulOffset % 4)
      ++ulOffset;
  }
  printf("Received %u frames (%u Error Frames): DataLen=%u\r\n", ulFrameCnt, ulTotalErrorFrames, ulDataSize);
}
void StartCaptureSilent(NETANA_HANDLE hDevice)
{
  int32_t lResult;
  /* Reference time for wireshark needs to be UNIX Timestamp (seconds sind 1.1.1970)
        and as we are using a nanosecond timestamp, we need to multiply it with 1000000000 */
  uint64_t ullReferenceTime = (/*get time*/ 0) * 1000 * 1000 * 1000;

  if (NETANA_NO_ERROR != (lResult = netana_start_capture(hDevice,
                                                         0,
                                                         0xF,
                                                         NETANA_MACMODE_ETHERNET,
                                                         ullReferenceTime,
                                                         StatusCallback,
                                                         IgnoreDataCallback,
                                                         NULL)))
  {
    printf("Error starting capture. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
  }
  else
  {
    printf("ok\n");
  }
}


void StartCapture(NETANA_HANDLE hDevice)
{
  int32_t lResult;
  /* Reference time for wireshark needs to be UNIX Timestamp (seconds sind 1.1.1970)
        and as we are using a nanosecond timestamp, we need to multiply it with 1000000000 */
  uint64_t ullReferenceTime = (/*get time*/ 0) * 1000 * 1000 * 1000;

  if (NETANA_NO_ERROR != (lResult = netana_start_capture(hDevice,
                                                         0,
                                                         0xF,
                                                         NETANA_MACMODE_ETHERNET,
                                                         ullReferenceTime,
                                                         StatusCallback,
                                                         DataCallback,
                                                         NULL)))
  {
    printf("Error starting capture. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
  }
  else
  {
    printf("ok\n");
  }
}

void StopCapture(NETANA_HANDLE hDevice)
{
  int32_t lResult;
  if (NETANA_NO_ERROR != (lResult = netana_stop_capture(hDevice)))
  {
    printf("Error stopping capture. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
  }
  else
  {
    printf("ok\n");
  }
}

/*** state ***/
void GetState(NETANA_HANDLE hDevice)
{
  int32_t lResult;
  uint32_t ulCaptureState;
  uint32_t ulCaptureError;

  if (NETANA_NO_ERROR != (lResult = netana_get_state(hDevice, &ulCaptureState, &ulCaptureError)))
  {
    printf("Error stopping capture. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
  }
  else
  {
    printf("ulCaptureState %08x\n", ulCaptureState);
    printf("ulCaptureError %08x\n", ulCaptureError);
    printf("ok\n");
  }
}

void Measure(NETANA_HANDLE hDevice)
{
  int32_t lResult;
  NETANA_PORT_STATE_T  tPortStat;
  uint32_t  ulPort = 0;

  printf("getting counters of port %d\n", ulPort);
  if (NETANA_NO_ERROR != (lResult = netana_get_portstat(hDevice, ulPort, sizeof(tPortStat), &tPortStat)))
  {
    printf("Error in netana_get_portstat. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
  }
    printf("DEBUGINFO      minbaud:   %lf\n", ((double)tPortStat.ullFrameTooLongErrors)/1000000);
    printf("               maxbaud:   %lf\n", ((double)tPortStat.ullSFDErrors)/1000000);
    printf("    MB/sec: %lf on transfered bytes: %llu\n", ((double)tPortStat.ullShortFrames)/1000000, tPortStat.ullFramesRejected);
    printf("\n");
}

/*** port statistics ***/
void GetPortCounterStat(NETANA_HANDLE hDevice)
{
  int32_t lResult;
  NETANA_PORT_STATE_T  tPortStat;
  static uint32_t  ulPort = 0;

  printf("getting counters of port %d\n", ulPort);
  if (NETANA_NO_ERROR != (lResult = netana_get_portstat(hDevice, ulPort, sizeof(tPortStat), &tPortStat)))
  {
    printf("Error in netana_get_portstat. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
  }
  else
  {
    printf("ulLinkState                   0x%08x\n",  tPortStat.ulLinkState);
    printf("ullFramesReceivedOk           0x%" PRIx64 "\n", tPortStat.ullFramesReceivedOk);
    printf("ullRXErrors                   0x%" PRIx64 "\n", tPortStat.ullRXErrors);
    printf("ullAlignmentErrors            0x%" PRIx64 "\n", tPortStat.ullAlignmentErrors);
    printf("ullFrameCheckSequenceErrors   0x%" PRIx64 "\n", tPortStat.ullFrameCheckSequenceErrors);
    printf("ullFrameTooLongErrors         0x%" PRIx64 "\n", tPortStat.ullFrameTooLongErrors);
    printf("ullSFDErrors                  0x%" PRIx64 "\n", tPortStat.ullSFDErrors);
    printf("ullShortFrames                0x%" PRIx64 "\n", tPortStat.ullShortFrames);
    printf("ullFramesRejected             0x%" PRIx64 "\n", tPortStat.ullFramesRejected);
    printf("ullLongPreambleCnt            0x%" PRIx64 "\n", tPortStat.ullLongPreambleCnt);
    printf("ullShortPreambleCnt           0x%" PRIx64 "\n", tPortStat.ullShortPreambleCnt);
    printf("ullBytesLineBusy              0x%" PRIx64 "\n", tPortStat.ullBytesLineBusy);
    printf("ulMinIFG                      0x%08x\n",  tPortStat.ulMinIFG);
    printf("ullTime                       0x%" PRIx64 "\n", tPortStat.ullTime);
    printf("\n");
  }
  ulPort++;
  ulPort %= 4;
}


/*** scanning ***/
unsigned long g_ulFoundNumber = 0;
typedef struct SCAN_PARAM_INPUT_Ttag
{
  PFN_SCAN_CALLBACK pfn_scan_callback;
  void *pvUser;
} SCAN_PARAM_INPUT_T;

void APIENTRY ScanCallback(uint8_t bProgress, uint32_t ulFoundNumber, char *szLastFound, void *pvUser)
{
  UNREFERENCED_PARAMETER(bProgress);
  UNREFERENCED_PARAMETER(ulFoundNumber);
  UNREFERENCED_PARAMETER(pvUser);

  /* only report new devices */
  if (g_ulFoundNumber < ulFoundNumber)
  {
    g_ulFoundNumber = ulFoundNumber;
    printf("Found device! Board: %s\n", szLastFound);
  }
}

int SelectAnalyzer(NETANA_HANDLE *phDevice)
{
  uint32_t ulRes = 0;
  int32_t lResult = NETANA_NO_ERROR;
  NETANA_DRIVER_INFORMATION_T tDriverInfo = {0};
  char *szDeviceToUse = NULL;
  uint32_t ulAvailableCards = 0;

  printf("Gathering driver information...\n");
  printf("----------------------------------------\r\n");

  /* Try to open the driver */
  if (NETANA_NO_ERROR != (lResult = netana_driver_information(sizeof(tDriverInfo), &tDriverInfo)))
  {
    printf("Error opening driver. ErrorCode=0x%08X\r\n", (uint32_t)lResult);
    return 0;
  }

  printf("Driver Version\t: %u.%u.%u.%u\r\n\n",
         tDriverInfo.ulVersionMajor,
         tDriverInfo.ulVersionMinor,
         tDriverInfo.ulVersionBuild,
         tDriverInfo.ulVersionRevision);

  printf("Toolkit Version\t: %u.%u.%u.%u\r\n\n",
         tDriverInfo.ulToolkitVersionMajor,
         tDriverInfo.ulToolkitVersionMinor,
         tDriverInfo.ulToolkitVersionBuild,
         tDriverInfo.ulToolkitVersionRevision);

  /* check marshaller status */
  if (NETANA_NO_ERROR == tDriverInfo.lMarshallerStatus)
  {
    printf("Marshaller Version\t: %u.%u.%u.%u\r\n\n",
           tDriverInfo.ulMarshallerVersionMajor,
           tDriverInfo.ulMarshallerVersionMinor,
           tDriverInfo.ulMarshallerVersionBuild,
           tDriverInfo.ulMarshallerVersionRevision);
  }
  else
  {
    printf("Error while trying to load netAnalyzer-Marshaller (Error: 0x%X)!\n",
           (uint32_t)tDriverInfo.lMarshallerStatus);
    printf("This error can be ignored if no Marshaller should be used.\n\n");
  }
  NETANA_MNGMT_DEV_SCAN_IN_T tInputParam;
  NETANA_MNGMT_DEV_SCAN_OUT_T tReturnVal;

  tInputParam.pfnCallBack = ScanCallback;
  tInputParam.pvUser = NULL;

  printf("Starting Device-Scan...\n");
  printf("----------------------------------------\r\n");

  /* scan for remote devices */
  lResult = netana_mngmt_exec_cmd(NETANA_MNGMT_CMD_DEV_SCAN,
                                  (void *)&tInputParam,
                                  sizeof(tInputParam),
                                  &tReturnVal,
                                  sizeof(tReturnVal));
  printf("\n");
  lResult = netana_driver_information(sizeof(tDriverInfo), &tDriverInfo);

  if (tDriverInfo.ulCardCnt == 0)
  {
    printf("\nNo device found for further testing\r\n");
    return 0;
  }

  printf("Gathering device information...\n");
  printf("----------------------------------------\r\n");

  printf(" Cards       : %u\r\n", tDriverInfo.ulCardCnt);
  printf(" DMA Buffers : %u x %u Bytes\r\n", tDriverInfo.ulDMABufferCount,
         tDriverInfo.ulDMABufferSize);
  printf(" Max Files   : %u\r\n", tDriverInfo.ulMaxFileCount);

  printf(" Found cards : %d\r\n", tDriverInfo.ulCardCnt);

  aszDeviceNames = (char **)OS_Memalloc(tDriverInfo.ulCardCnt * sizeof(char *));
  OS_Memset(aszDeviceNames, 0, tDriverInfo.ulCardCnt * sizeof(char *));

  /* Enumerate all available boards and use the first found one, to do our tests */
  for (uint32_t ulCard = 0; ulCard < tDriverInfo.ulCardCnt; ulCard++)
  {
    NETANA_DEVICE_INFORMATION_T tDevInfo = {{0}};

    if (NETANA_NO_ERROR != (lResult = netana_enum_device(ulCard,
                                                         sizeof(tDevInfo),
                                                         &tDevInfo)))
    {
      printf("\n[%u]: Error enumerating card #%u. ErrorCode=0x%08X\r\n",
             ulCard,
             ulCard,
             (uint32_t)lResult);
      continue;
    }
    ulAvailableCards++;

    aszDeviceNames = (char **)realloc(aszDeviceNames, ulAvailableCards * sizeof(char *));
    aszDeviceNames[ulAvailableCards - 1] = strdup((char *)tDevInfo.szDeviceName);

    printf("\n[%u]:\tDeviceName = '%s'\r\n",
           ulCard,
           (char *)tDevInfo.szDeviceName);
    printf("\tDeviceNr   = %u\n\tSerialNr   = %u\r\n",
           tDevInfo.ulDeviceNr,
           tDevInfo.ulSerialNr);
    printf("\tFirmware   = %s V%u.%u.%u.%u\r\n",
           (char *)tDevInfo.szFirmwareName,
           tDevInfo.ulVersionMajor,
           tDevInfo.ulVersionMinor,
           tDevInfo.ulVersionBuild,
           tDevInfo.ulVersionRevision);
    printf("\tPorts      = %u\n\tGPIOs      = %u\n\tFilterSize = %u\r\n",
           tDevInfo.ulPortCnt,
           tDevInfo.ulGpioCnt,
           tDevInfo.ulFilterSize);

    if (sizeof(NETANA_EXTENDED_DEV_INFO_T) == tDevInfo.ulExtendedInfoSize)
    {
      /* check which device type is found */
      switch (tDevInfo.ulExtendedInfoType)
      {
      case NETANA_GBE_VARIANT:
      {
        unsigned char abIPAddr[4];
        unsigned char abSubnetMask[4];
        unsigned char abMACAddr[6];

        printf("\n\tIt is a GBE-Device!\n");

        OS_Memcpy(abIPAddr, tDevInfo.tExtendedInfo.tGBEExtendedInfo.abIpAddr, 4);
        OS_Memcpy(abSubnetMask, tDevInfo.tExtendedInfo.tGBEExtendedInfo.abSubnetMask, 4);
        OS_Memcpy(abMACAddr, tDevInfo.tExtendedInfo.tGBEExtendedInfo.abMacAddr, 6);

        printf("\n\t---   Server-Information   ---\n");

        printf("\tIP-Address \t= %u.%u.%u.%u\n", abIPAddr[0], abIPAddr[1], abIPAddr[2], abIPAddr[3]);
        printf("\tSubNetMask \t= %u.%u.%u.%u\n", abSubnetMask[0], abSubnetMask[1], abSubnetMask[2], abSubnetMask[3]);
        printf("\tMAC-Address \t= %X-%X-%X-%X-%X-%X\r\n", abMACAddr[0], abMACAddr[1], abMACAddr[2], abMACAddr[3], abMACAddr[4], abMACAddr[5]);
        printf("\tOS-Version \t= V%u.%u\r\n", tDevInfo.tExtendedInfo.tGBEExtendedInfo.ulOSMajorVersion, tDevInfo.tExtendedInfo.tGBEExtendedInfo.ulOSMinorVersion);

        printf("\tDriver-Version \t= V%u.%u.%u.%u\r\n", tDevInfo.tExtendedInfo.tGBEExtendedInfo.ulDrvVersionMajor,
               tDevInfo.tExtendedInfo.tGBEExtendedInfo.ulDrvVersionMinor,
               tDevInfo.tExtendedInfo.tGBEExtendedInfo.ulDrvVersionRevision,
               tDevInfo.tExtendedInfo.tGBEExtendedInfo.ulDrvVersionBuild);

        printf("\tServer-Version \t= V%u.%u\r\n", tDevInfo.tExtendedInfo.tGBEExtendedInfo.ulServerVersionMajor, tDevInfo.tExtendedInfo.tGBEExtendedInfo.ulServerVersionBuild);
        printf("\n");
      }
      break;
      default:
        //unknown type
        printf("\tDevice type not known!\n");
        break;
      }
    }
  }

  if (0 == ulAvailableCards)
  {
    printf("No card available!\n");
  }
  else if (1 == ulAvailableCards)
  {
    szDeviceToUse = aszDeviceNames[0];
  }
  else
  {
    for (uint32_t ulCard = 0; ulCard < ulAvailableCards; ulCard++)
      printf("\nDevice[%d] : %s", ulCard, aszDeviceNames[ulCard]);

    printf("\nChoose the device, on which the tests should run on:\r\n");
    printf("Enter 'q' to abort!\r\n");
    while (1)
    {
      int num = OS_WaitForUserInput();
      char of = '0';
      if (num == 'q')
        goto exit;

      num = num - (int)of;
      if (tDriverInfo.ulCardCnt > (unsigned long)num)
      {
        szDeviceToUse = aszDeviceNames[num];
        break;
      }
      else
      {
        printf("\nillegal input!\n");
      }
    }
  }
  printf("\nStarting tests on Device '%s'\r\n", szDeviceToUse);
  printf("----------------------------------------\r\n");

  /* Get a handle to the device */
  if (NETANA_NO_ERROR != (lResult = netana_open_device(szDeviceToUse, phDevice)))
  {
    printf("Error opening device '%s'. ErrorCode=0x%08X\r\n", szDeviceToUse, (uint32_t)lResult);
  }
  else
  {
    ulRes = 1;
  }
exit:
  if (aszDeviceNames)
    for (uint32_t ulCard = 0; ulCard < ulAvailableCards; ulCard++)
      if (aszDeviceNames[ulCard])
        OS_Memfree(aszDeviceNames[ulCard]);

  return ulRes;
}

void usage()
{
      printf("\n");
      printf("\n");
      printf("Commands:\n");
      printf("        s:      start capture\n");
      printf("        t:      stop capture\n");
      printf("        i:      start capture ignoring data\n");
      printf("        m:      measure\n");
      printf("        f:      configure filters\n");
      printf("        g:      get state\n");
      printf("        c:      get port counter statistics\n");
      printf("        a:      access phy reg\n");
      printf("        h:      this help text\n");
      printf("        q:      quit\n");
      printf("\n");
      printf("\n");
}

/*** main ***/
int main(int argc, char *argv[])
{
  NETANA_HANDLE hDevice = NULL;

  printf("******************** netAnalyzer Demo Application ********************\n\n");
  usage();
  if (SelectAnalyzer(&hDevice) != 0)
  {
    char bKbInput = 0;
    
    do
    {
      scanf("%c", &bKbInput);

      switch (bKbInput)
      {
      case 'f':
        printf("configuring filters\n");
        ConfigureFilters(hDevice);
        break;
      case 'a':
        printf("access phy reg\n");
        AccessPhyReg(hDevice);
        break;
      case 'h':
        usage();
        break;
      case 's':
        printf("starting capture\n");
        StartCapture(hDevice);
        break;
      case 'i':
        printf("starting capture silent\n");
        StartCaptureSilent(hDevice);
        break;
      case 'm':
        printf("starting capture\n");
        Measure(hDevice);
        break;
      case 't':
        printf("stopping capture\n");
        StopCapture(hDevice);
        break;
      case 'g':
        printf("getting state\n");
        GetState(hDevice);
        break;
      case 'c':
        printf("getting port counter statistics\n");
        GetPortCounterStat(hDevice);
        break;
      case 'q':
        printf("goodbye...");
        break;
      case '\n':
        break; /* EOL symbol is ignored */
      default:
        printf("unknown input >%c<\n", bKbInput);
        usage();
        break;
      }
    } while (bKbInput != 'q');

    netana_close_device(hDevice);
  }

  return 0;
}
