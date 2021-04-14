#include "cifxlinux.h"

#include <stddef.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char* argv[])
{
  struct CIFX_LINUX_INIT init =
  {
    .init_options        = CIFX_DRIVER_INIT_AUTOSCAN,
    .iCardNumber         = 0,
    .fEnableCardLocking  = 0,
    .base_dir            = NULL,
    .poll_interval       = -1,
    .poll_StackSize      = 0,   /* set to 0 to use default */
    .trace_level         = 0,
    .user_card_cnt       = 0,
    .user_cards          = NULL,
    .logfd               = stderr,
  };

  /* First of all initialize toolkit */
  int32_t lRet = cifXDriverInit(&init);
  int ret = 0;

  if(CIFX_NO_ERROR != lRet)
  {
    printf("Error initializing driver %d\n", lRet);
    ret = -1;
  } else {
    CIFXHANDLE hDriver = NULL;
    long   lRet    = xDriverOpen(&hDriver);

    if(CIFX_NO_ERROR != lRet)
    {
      printf("Error opening driver %d\n", lRet);
      ret = -1;
    } else {
      uint32_t          ulBoard    = 0;
      BOARD_INFORMATION tBoardInfo = {0};

      printf("Output format: Board DeviceNumber SerialNumber HWOptions\n");

      /* Iterate over all boards */
      while(CIFX_NO_ERROR == xDriverEnumBoards(hDriver, ulBoard, sizeof(tBoardInfo), &tBoardInfo))
      {
        SYSTEM_CHANNEL_SYSTEM_INFO_BLOCK tSysInfo;
        CIFXHANDLE hSys;

        xSysdeviceOpen(hDriver, tBoardInfo.abBoardName, &hSys);
        xSysdeviceInfo(hSys, CIFX_INFO_CMD_SYSTEM_INFO_BLOCK, sizeof(tSysInfo), &tSysInfo);
        xSysdeviceClose(hSys);

        printf("%s %d %d %04X%04X%04X%04X\n", tBoardInfo.abBoardName,
               tBoardInfo.tSystemInfo.ulDeviceNumber,
               tBoardInfo.tSystemInfo.ulSerialNumber,
               tSysInfo.ausHwOptions[0], tSysInfo.ausHwOptions[1],
               tSysInfo.ausHwOptions[2], tSysInfo.ausHwOptions[3]);

        ++ulBoard;
      }
    }

    /* close previously opened driver */
    xDriverClose(hDriver);
  }

  cifXDriverDeinit();

  return ret;
}
