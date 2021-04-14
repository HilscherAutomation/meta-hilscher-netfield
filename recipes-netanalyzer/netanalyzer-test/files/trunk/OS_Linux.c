/**************************************************************************************

Copyright (c) Hilscher GmbH. All Rights Reserved.

**************************************************************************************

Filename:
$Workfile: OS_Linux.c $
Last Modification:
$Author: sebastiand $
$Modtime: 30.09.09 14:58 $
$Revision: 3111 $

Targets:
Linux        : yes

Description:
Linux O/S abstraction

Changes:

Version   Date        Author       Description
----------------------------------------------------------------------------------

**************************************************************************************/

/*****************************************************************************/
/*! \file OS_Linux.c
*   Linux O/S abstraction                                                    */
/*****************************************************************************/
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include "OS_Includes.h"
#include "netana_errors.h"

/*****************************************************************************/
/*! Memory allocation wrapper (standard malloc)
*     \param ulSize Size of block to allocate
*     \return NULL on failure                                                */
/*****************************************************************************/
void* OS_Memalloc(uint32_t ulSize)
{
        return malloc( ulSize);
}

/*****************************************************************************/
/*! Memory de-allocation wrapper (standard free)
*     \param pvMem  Block to free                                            */
/*****************************************************************************/
void  OS_Memfree(void* pvMem)
{
        free( pvMem);
}

/*****************************************************************************/
/*! Memset wrapper
*     \param pvMem   Memory to set
*     \param bFill   Fill byte
*     \param ulSize  Size of the fill block                                  */
/*****************************************************************************/
void OS_Memset(void* pvMem, unsigned char bFill, uint32_t ulSize)
{
        memset(pvMem, bFill, ulSize);
}

/*****************************************************************************/
/*! Memcopy wrapper
*     \param pvDest  Destination pointer
*     \param pvSrc   Source pointer
*     \param ulSize  Size to copy                                            */
/*****************************************************************************/
void OS_Memcpy(void* pvDest, const void* pvSrc, uint32_t ulSize)
{
        memcpy(pvDest, pvSrc, ulSize);
}

/*****************************************************************************/
/*! Memcompare wrapper
*     \param pvBuf1  First compare buffer
*     \param pvBuf2  Second compare buffer
*     \param ulSize  Size to compare
*     \return 0 if blocks are equal                                          */
/*****************************************************************************/
int OS_Memcmp(const void* pvBuf1, const void* pvBuf2, uint32_t ulSize)
{
        return memcmp(pvBuf1, pvBuf2, ulSize);
}

/*****************************************************************************/
/*! Compare strings
*     \param pszBuf1  String buffer 1
*     \param pszBuf2  String buffer 2
*     \return 0 if strings are equal                                         */
/*****************************************************************************/
int OS_Strcmp(const char* pszBuf1, const char* pszBuf2)
{
        return strcmp( pszBuf1, pszBuf2);
}

/*****************************************************************************/
/*! Compare strings case insensitive
*     \param pszBuf1  String buffer 1
*     \param pszBuf2  String buffer 2
*     \param ulLen    Maximum length to compare
*     \return 0 if strings are equal                                         */
/*****************************************************************************/
int OS_Strnicmp(const char* pszBuf1, const char* pszBuf2, uint32_t ulLen)
{
        return strncasecmp(pszBuf1, pszBuf2, ulLen);
}

/*****************************************************************************/
/*! Get length of string
*     \param szText  Text buffer
*     \return Length of given string                                         */
/*****************************************************************************/
int OS_Strlen(const char* szText)
{
        return strlen(szText);
}

/*****************************************************************************/
/*! Copy string to destination buffer
*     \param szText   Destination string
*     \param szSource Source string
*     \param ulLen    Maximum length to copy
*     \return Pointer to szDest                                              */
/*****************************************************************************/
char* OS_Strncpy(char* szDest, const char* szSource, uint32_t ulLen)
{
        memcpy(szDest, szSource,ulLen);
        return szDest;
}

int ReadLine(void)
{
        char bLine[100];
        fgets( bLine, 100, stdin);
        return bLine[0];
}

/*****************************************************************************/
/*! Sleep for the given time
*     \param ulSleepTimeMs Time in ms to sleep (0 will sleep for 50us)       */
/*****************************************************************************/
void OS_Sleep(uint32_t ulSleepTimeMs) {
        struct timespec sleeptime;
        struct timespec RemainingTime;
        struct timespec *pRemainingTime = &RemainingTime;
        int    iRet;
        int    iTmpErrno;

        if(ulSleepTimeMs == 0) {
                sleeptime.tv_sec = 0;
                sleeptime.tv_nsec = 50000; // 50 usecs
        } else {
                sleeptime.tv_sec = ulSleepTimeMs / 1000;
                ulSleepTimeMs -= sleeptime.tv_sec * 1000;
                sleeptime.tv_nsec = ulSleepTimeMs * 1000 * 1000;
        }

        iTmpErrno = errno;
        errno = 0;
        while((iRet = nanosleep(&sleeptime, pRemainingTime))) {
                if ((errno == EINTR) && (pRemainingTime != NULL) ) {
                        sleeptime.tv_sec  = RemainingTime.tv_sec;
                        sleeptime.tv_nsec = RemainingTime.tv_nsec;
                } else {
                        perror("OS_Sleep failed");
                }
        }
        errno = iTmpErrno;
}

/*****************************************************************************/
/*! Reads user input from stdin
*     \return parameter read                                                 */
/*****************************************************************************/
int OS_KbHit(void)
{
        struct pollfd fds;
        fds.fd      = 0;//stdin
        fds.events  = POLLIN;
        fds.revents = 0;

        if (0>=poll( &fds, 1, 1)) {
                return 0;
        } else {
                return ReadLine();
        }
}

/*****************************************************************************/
/*! Returns when user presses a key
*     \return parameter read                                                 */
/*****************************************************************************/
int OS_WaitForUserInput(void)
{
        int num;
        while(!(num = OS_KbHit()))
        {
                OS_Sleep(10);
        }
        return num;
}
