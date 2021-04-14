#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/sysctl.h>
#include <asm/setup.h>

#include "cert.h"

#define DRIVER_AUTHOR "Hilscher Gesellschaft fuer Systemautomation mbH"
#define DRIVER_DESC   "Dumps security key"

static struct ctl_table_header *s_Sysctl_header;

static int proc_owner_cert_handler(struct ctl_table *table, int write,
                                   void __user *buffer, size_t *lenp, loff_t *ppos);

static struct ctl_table owner_cert_table[] = {
       {
               .procname = "owner-cert",
               .data     = s_abCert,
               .maxlen = sizeof(s_abCert),
               .mode  = 0444,
               .proc_handler = proc_owner_cert_handler,
               .child = NULL,
       },
       {
       },
};

static struct ctl_table srm_table[] = {
       {
               .procname = "srm",
               .mode = 0444,
               .child = owner_cert_table,
       },
       {
       },
};

static int proc_owner_cert_handler(struct ctl_table *table, int write,
                                   void __user *buffer, size_t *lenp, loff_t *ppos)
{
  return proc_dostring(table, write, buffer, lenp, ppos);
}

static __init int init_key_module(void)
{
  if (NULL == (s_Sysctl_header = register_sysctl_table(srm_table)))
    return -ENOMEM;

  return 0;
}

void cleanup_key_module(void)
{
  if (s_Sysctl_header)
    unregister_sysctl_table(s_Sysctl_header);
} 

module_init(init_key_module);
module_exit(cleanup_key_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR(DRIVER_AUTHOR);
MODULE_DESCRIPTION(DRIVER_DESC);

