#ifndef __OS_INCLUDES__H
#define __OS_INCLUDES__H

#include <unistd.h>
#include <time.h>
#include <sys/times.h>
#include <poll.h>
#include <fcntl.h>

#ifdef __cplusplus
extern "C" {
#endif  /* _cplusplus */

#define STAILQ_ENTRY(a) struct llist_node

#define OS_PATH_SEPERATOR   "\\"

#ifndef NULL
        #define NULL  ((void*)0)
#endif

#undef SLIST_ENTRY

#define UNREFERENCED_PARAMETER(a)  (void)(a)

int OS_KbHit(void);
int OS_WaitForUserInput(void);

#ifdef __cplusplus
}
#endif  /* _cplusplus */

#endif /*  __OS_INCLUDES__H */
