#include "cifxlinux.h"

#include <stddef.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/stat.h>
#include <signal.h>

int g_fRunning = 1;

int32_t cifxeth_search_eth_channel   ( char* szDeviceName, uint32_t ulSearchIdx, uint32_t* pulChannelNumber);

int32_t cardinfo(void)
{
  CIFXHANDLE hDriver = NULL;
  long   lRet    = xDriverOpen(&hDriver);

  printf("---------- Available Cards ----------\r\n");

  if(CIFX_NO_ERROR == lRet)
  {
    /* Driver/Toolkit successfully opened */
    unsigned long     ulBoard    = 0;
    BOARD_INFORMATION tBoardInfo = {0};

    /* Iterate over all boards */
    while(CIFX_NO_ERROR == xDriverEnumBoards(hDriver, ulBoard, sizeof(tBoardInfo), &tBoardInfo))
    {
      printf("%d.: %s\r\n", tBoardInfo.ulBoardID +1, tBoardInfo.abBoardName);
      if(strlen( (char*)tBoardInfo.abBoardAlias) != 0)
        printf("    Alias        : %s\r\n", tBoardInfo.abBoardAlias);

      printf("    DeviceNumber : %lu\r\n",(long unsigned int)tBoardInfo.tSystemInfo.ulDeviceNumber);
      printf("    SerialNumber : %lu\r\n",(long unsigned int)tBoardInfo.tSystemInfo.ulSerialNumber);

      unsigned long       ulChannel    = 0;
      CHANNEL_INFORMATION tChannelInfo = {{0}};

      /* iterate over all channels on the current board */
      while(CIFX_NO_ERROR == xDriverEnumChannels(hDriver, ulBoard, ulChannel, sizeof(tChannelInfo), &tChannelInfo))
      {
        printf("    - Channel %lu:\r\n", ulChannel);
        printf("      Firmware : %s\r\n", tChannelInfo.abFWName);
        printf("      Version  : %u.%u.%u build %u\r\n",
               tChannelInfo.usFWMajor,
               tChannelInfo.usFWMinor,
               tChannelInfo.usFWRevision,
               tChannelInfo.usFWBuild);

        ++ulChannel;
      }

      ++ulBoard;
      printf("----------------------------------------------------\r\n");
    }

    /* close previously opened driver */
    xDriverClose(hDriver);
  }
  return lRet;
}

void DeInitServer(int iSignal)
{
  g_fRunning = 0;
}

/*****************************************************************************/
/*! Main entry function
*   \return 0                                                                */
/*****************************************************************************/
int main(int argc, char* argv[])
{
  struct sigaction       tSigTerm;
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
  uint32_t netx_tap_debug = 0;
  int32_t  eth_channel    = -1;
  int      opt_card_info  = 0;
  int      opt_reset      = 0;

  sigemptyset(&tSigTerm.sa_mask);
  tSigTerm.sa_handler = DeInitServer;
  tSigTerm.sa_flags   = 0;

  /* catch "ctrl + c" signal */
  sigaction(SIGINT, &tSigTerm,NULL);
  /* catch termination request e.g. when running as systemd service */
  sigaction(SIGTERM, &tSigTerm,NULL);

  while (argc > 1) {
    char* arg = argv[--argc];

    if ( !strcmp(arg,"-l")) {
      opt_card_info = 1;
    } else if ( !strcmp(arg,"-r")) {
      opt_reset = 1;
    } else if ( !strcmp(arg,"-dd")) {
      if (netx_tap_debug < 0xFF)
        /* log all */
        netx_tap_debug = 0xFF;
    } else if ( !strcmp(arg,"-d")) {
      if (netx_tap_debug < 1)
        /* log only erorrs */
        netx_tap_debug = 0x8;
    }
  }
  init.trace_level = netx_tap_debug;

  /* First of all initialize toolkit */
  int32_t lRet = cifXDriverInit(&init);

  /* NOTE: just use the channel of the first found card */
  if (CIFX_NO_ERROR != cifxeth_search_eth_channel( "cifX0", 0, &eth_channel))
    eth_channel = -1;

  if(CIFX_NO_ERROR != lRet)
  {
    printf("Error initializing driver %d\n", lRet);
  } else {
    if (opt_card_info != 0) {
      cardinfo();
    }
    if (opt_reset != 0) {
      CIFXHANDLE hDrv;
      CIFXHANDLE hChan;

      printf("Try to reset ethernet channel...\n");
      if (eth_channel != -1) {
        if (CIFX_NO_ERROR == (lRet = xDriverOpen( &hDrv))) {
          if (CIFX_NO_ERROR == (lRet = xChannelOpen( hDrv, "cifX0", eth_channel, &hChan))) {
            if (CIFX_NO_ERROR != (lRet = xChannelReset( hChan, /*CIFX_CHANNELINIT*/CIFX_SYSTEMSTART, 10000)))
              printf("Error reseting channel %d (%d)\n", eth_channel, lRet);

            xChannelClose( hChan);
          } else {
            printf("Error opening channel %d\n", lRet);
          }
          xDriverClose( hDrv);
        } else {
          printf("Error opening driver %d\n", lRet);
        }
      } else {
        printf("The card does not provide an ethernet channel!\n");
      }
    }
    printf("Server is running, serving tun/tap interfaces\n");
    while(g_fRunning) {
      sleep(10);
    }
  }
  cifXDriverDeinit();
  printf("Server stopped...\n");

  return 0;
}
