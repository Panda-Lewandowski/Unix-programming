obj-m := lkm.o 
KERNEL_DIR := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)


default:
	$(MAKE) -C $(KERNEL_DIR) M="$(PWD)" modules

clean:
	rm -rf .tmp_versions
	rm *.symvers *.order *.ko .*.*.* *.mod.c *.o