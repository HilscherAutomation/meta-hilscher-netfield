obj-m := pub-key-loader.o

PWD := $(shell pwd)
default:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) modules

clean:
	rm -f *.o *.ko *.order *.mod* Module.symvers

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) modules_install
