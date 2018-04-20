ifneq ($(KERNELRELEASE),)
	obj-m := pfs.o

else
	CURRENT = $(shell uname -r)
	KDIR = /lib/modules/$(CURRENT)/build
	PWD = $(shell pwd)

default:
	$(MAKE) -C $(KDIR) M=$(PWD) modules
	sudo make clean

clean:
	rm -rf .tmp_versions
	rm .pfs.*
	# rm *.ko
	rm *.o
	rm *.mod.c
	rm *.symvers
	rm *.order

endif
