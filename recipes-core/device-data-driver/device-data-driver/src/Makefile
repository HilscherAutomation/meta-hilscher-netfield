ifneq ($(KERNELRELEASE),)
# kbuild part of makefile
obj-m += device-data.o
device-data-objs := device-data-driver.o jsmn.o
else
# normal makefile
all:	modules

modules:
	$(MAKE) -C $(KERNEL_SRC) M=$$PWD modules

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$$PWD modules_install
clean:
	rm -f *.o *.ko *.order *.mod* Module.symvers
endif

