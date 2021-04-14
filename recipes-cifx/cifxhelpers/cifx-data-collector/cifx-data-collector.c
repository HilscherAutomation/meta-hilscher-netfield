#include "cifxlinux.h"
#include "cifXEndianess.h"

#include "Hil_Types.h"
#include "Hil_SystemCmd.h"

#include <stdio.h>
#include <string.h>

CIFX_PACKET packet;

/*****************************************************************************/
/*! Main entry function
*   \return 0                                                                */
/*****************************************************************************/
int main(int argc, char* argv[])
{

  struct CIFX_LINUX_INIT init =
  {
    .init_options        = CIFX_DRIVER_INIT_AUTOSCAN,
    .iCardNumber         = 0,
    .fEnableCardLocking  = 0,
    .base_dir            = NULL,
    .poll_interval       = 0,
    .poll_StackSize      = 0,   /* set to 0 to use default */
    .trace_level         = 0,
    .user_card_cnt       = 0,
    .user_cards          = NULL,
  };

  /* First of all initialize toolkit */
  int32_t lRet = cifXDriverInit(&init);
  CIFXHANDLE hDriver = NULL;

  if(CIFX_NO_ERROR == lRet)
  {
    uint32_t board;
    DRIVER_INFORMATION driver_info;

    memset(&driver_info, 0, sizeof(driver_info));

    lRet = xDriverOpen(&hDriver);
    if(lRet != CIFX_NO_ERROR)
       goto error_out;

    xDriverGetInformation(hDriver, sizeof(driver_info), &driver_info);

    for(board=0; board<driver_info.ulBoardCnt; board++) {
      BOARD_INFORMATION board_info;
      uint8_t mac[6];
      uint16_t usHWOpts[4];
      CIFXHANDLE hSysdevice;
      HIL_SECURITY_EEPROM_READ_REQ_T* read_eeprom_req = (HIL_SECURITY_EEPROM_READ_REQ_T*)&packet;
      SYSTEM_CHANNEL_SYSTEM_INFO_BLOCK tSystemInfoBlock;
      HIL_HW_HARDWARE_INFO_CNF_DATA_T* ptHardwareInfo;

      memset(&board_info, 0, sizeof(board_info));
      lRet = xDriverEnumBoards(hDriver, board, sizeof(board_info), &board_info);
      if(lRet != CIFX_NO_ERROR)
        goto error_out;

      lRet = xSysdeviceOpen(hDriver, board_info.abBoardName, &hSysdevice);
      if(lRet != CIFX_NO_ERROR)
        goto error_out;

      lRet = xSysdeviceInfo(hSysdevice, CIFX_INFO_CMD_SYSTEM_INFO_BLOCK, sizeof(tSystemInfoBlock), &tSystemInfoBlock);
      if(lRet != CIFX_NO_ERROR)
        goto error_out;

      // Get MAC Address
      memset(&packet, 0, sizeof(packet));

      read_eeprom_req->tHead.ulCmd = HIL_SECURITY_EEPROM_READ_REQ;
      read_eeprom_req->tHead.ulLen = sizeof(read_eeprom_req->tData);
      read_eeprom_req->tData.ulZoneId = HIL_SECURITY_EEPROM_ZONE_1;

      lRet = xSysdevicePutPacket(hSysdevice, &packet, CIFX_TO_SEND_PACKET);
      if(lRet != CIFX_NO_ERROR)
        goto error_out;

      lRet = xSysdeviceGetPacket(hSysdevice, sizeof(packet), &packet, CIFX_TO_SEND_PACKET);
      if(lRet != CIFX_NO_ERROR)
        goto error_out;

      if(packet.tHeader.ulState != CIFX_NO_ERROR) {
        lRet = packet.tHeader.ulState;
        goto error_out;
      }
      memcpy(mac, packet.abData, sizeof(mac));

      memset(&packet, 0, sizeof(packet));
      packet.tHeader.ulCmd = HIL_HW_HARDWARE_INFO_REQ;
      packet.tHeader.ulLen = 0x0;

      lRet = xSysdevicePutPacket(hSysdevice, &packet, CIFX_TO_SEND_PACKET);
      if(lRet != CIFX_NO_ERROR)
        goto error_out;

      lRet = xSysdeviceGetPacket(hSysdevice, sizeof(packet), &packet, CIFX_TO_SEND_PACKET);
      if(lRet != CIFX_NO_ERROR)
        goto error_out;

      if(packet.tHeader.ulState != CIFX_NO_ERROR) {
        lRet = packet.tHeader.ulState;
        goto error_out;
      }
      ptHardwareInfo = (HIL_HW_HARDWARE_INFO_CNF_DATA_T*)&packet.abData;
      memcpy( usHWOpts, ptHardwareInfo->ausHwOptions, 8);

      xSysdeviceClose(hSysdevice);

      //Print out device information
      printf("%s %u %u %u %u %02X%02X%02X%02X%02X%02X %u %u %u %u\n",
        board_info.abBoardName, board_info.tSystemInfo.ulDeviceNumber,
        board_info.tSystemInfo.ulSerialNumber, board_info.tSystemInfo.bHwRevision,
        tSystemInfoBlock.usProductionDate,
        mac[0], mac[1], mac[2], mac[3], mac[4], mac[5],
        usHWOpts[0], usHWOpts[1], usHWOpts[2], usHWOpts[3]);
    }
  }

error_out:
  if(NULL != hDriver)
    xDriverClose(hDriver);

  cifXDriverDeinit();

  return lRet;
}
