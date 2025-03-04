#include "cifxlinux.h"

#include <stddef.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <time.h>

static volatile int running = 1;

void intHandler(int dummy) {
    running = 0;
}

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
    .trace_level         = 255,
    .user_card_cnt       = 0,
    .user_cards          = NULL,
    .logfd               = stderr,
  };

  /* First of all initialize toolkit */
  int32_t lRet;
  int ret = 0;

  if(CIFX_NO_ERROR != (lRet = cifXDriverInit(&init)))
  {
    printf("Error initializing driver %d\n", lRet);
    ret = -1;
  } else {
    CIFXHANDLE hDriver = NULL;
    CIFXHANDLE hChannel = NULL;

    if(CIFX_NO_ERROR != (lRet = xDriverOpen(&hDriver)))
    {
      printf("Error opening driver 0x%08x\n", lRet);
      ret = -1;
    } else if(CIFX_NO_ERROR != (lRet = xChannelOpen(hDriver, "cifX0", 0, &hChannel)))
    {
      printf("Error opening channel0 on cifX0 0x%08x\n", lRet);
      ret = -1;
    } else {
      int32_t lastReadErr = 0;
      int32_t lastWriteErr = 0;
      uint8_t iodata[128];
      uint32_t ulState = CIFX_BUS_STATE_ON;

      signal(SIGINT, intHandler);

      /* Check for running flag */
      lRet = xChannelBusState(hChannel, CIFX_BUS_STATE_ON, &ulState, 10000);
      if( (lRet != CIFX_NO_ERROR) &&
          (lRet != CIFX_DEV_NO_COM_FLAG) )
      {
          printf("Unable to set correct bus state (lRet=0x%08x)\n", lRet);
          ret = -1;
          goto out;
      }

      /* Mirror I/O and output return value changes (e.g. NO_COM_FLAG) */
      while(running) {

        lRet = xChannelIORead(hChannel, 0, 0, sizeof(iodata), iodata, 10);
        if(lRet != lastReadErr) {
            printf("Error reading I/O data lRet=0x%08x\n", lRet);
            lastReadErr = lRet;
        }

        lRet = xChannelIOWrite(hChannel, 0, 0, sizeof(iodata), iodata, 10);
        if(lRet != lastWriteErr) {
            printf("Error writing I/O data lRet=0x%08x\n", lRet);
            lastWriteErr = lRet;
        }

        struct timespec tim;
        tim.tv_sec  = 0;
        tim.tv_nsec = 10L * 1000 * 1000;
        nanosleep(&tim, NULL);
      }

      printf("Exiting\n");
    }


out:
    if(hChannel != NULL) {
        xChannelClose(hChannel);
        hChannel = NULL;
    }

    if(hDriver != NULL) {
        xDriverClose(hDriver);
        hDriver = NULL;
    }

    cifXDriverDeinit();
  }

  return ret;
}
