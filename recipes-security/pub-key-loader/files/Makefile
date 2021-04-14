obj-m := pub-key-loader.o

TMPKDIR := /lib/modules/$(shell uname -r)/build
TMPINSTALLPATH := kernel/drivers/

ifdef KDIR
  ifneq ($KDIR, "")
    TMPKDIR=$(KDIR)
  endif
endif

ifdef INSTALL_PATH
  ifneq ($INSTALL_PATH, "")
    TMPINSTALLPATH := $(INSTALL_PATH)
  endif
endif

PWD := $(shell pwd)
default:
	$(MAKE) -C $(TMPKDIR) M=$(PWD) modules

clean:
	rm -f *.o *.ko *.order *.mod* Module.symvers

modules_install:
	$(MAKE) INSTALL_MOD_DIR=$(TMPINSTALLPATH) -C $(TMPKDIR) M=$(PWD) modules_install