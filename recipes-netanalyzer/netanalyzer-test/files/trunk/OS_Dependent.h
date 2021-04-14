#ifndef __OS_DEPENDENT__H
#define __OS_DEPENDENT__H

#include "OS_Includes.h"

#ifdef __cplusplus
extern "C" {
#endif  /* _cplusplus */

#define NETANA_EVENT_TIMEOUT    0
#define NETANA_EVENT_SIGNALLED  1

int  OS_Init(void);
void OS_Deinit(void);

uint32_t OS_GetMilliSecCounter(void);

void* OS_Memalloc(uint32_t ulSize);
void  OS_Memfree(void* pvMem);
void  OS_Memcpy(void* pvDest, const void* pvSrc, uint32_t ulSize);
int   OS_Memcmp(const void* pvBuf1, const void* pvBuf2, uint32_t ulSize);
void  OS_Memset(void* pvMem, uint8_t bFill, uint32_t ulLen);

void* OS_CreateLock(void);
void  OS_DeleteLock(void* hLock);
void  OS_EnterLock(void* hLock);
void  OS_LeaveLock(void* hLock);

void* OS_ReadPCIConfig(void* pvOSDependent);
void  OS_WritePCIConfig(void* pvOSDependent, void* pvPCIConfig);
void  OS_EnableDeviceInterrupts(void* pvOSDependent);
void  OS_DisableDeviceInterrupts(void* pvOSDependent);

void  OS_Sleep(uint32_t ulSleepTimeMs);

int   OS_Strnicmp(const char* pszBuf1, const char* pszBuf2, uint32_t ulLen);
char* OS_Strncpy(char* szDest, const char* szSource, uint32_t ulLength);
int   OS_Strlen(const char* szText);

#define OS_FILE_FLAG_OPENEXISTING   0x00000001
#define OS_FILE_FLAG_CREATEIFNEEDED 0x00000002

void*         OS_FileOpen(char* szFilename, uint64_t* pullFileSize, uint32_t ulFlags);
uint32_t OS_FileSeek(void* pvFile,  uint32_t ulOffset);
uint32_t OS_FileRead(void* pvFile,  uint32_t ulOffset, uint32_t ulSize, void* pvBuffer);
uint32_t OS_FileWrite(void* pvFile, uint32_t ulSize, void* pvBuffer);
void          OS_FileClose(void* pvFile);

void*         OS_CreateEvent(void);
void          OS_SetEvent(void* pvEvent);
void          OS_ResetEvent(void* pvEvent);
void          OS_DeleteEvent(void* pvEvent);
uint32_t      OS_WaitEvent(void* pvEvent, uint32_t ulTimeout);

int           OS_Snprintf(char* szBuffer, uint32_t ulSize, const char* szFormat, ...);

#ifdef __cplusplus
}
#endif  /* _cplusplus */

#endif /*  __OS_DEPENDENT__H */
