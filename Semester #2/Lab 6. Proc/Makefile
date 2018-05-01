ifneq ($(KERNELRELEASE),)
	obj-m := fortune.o

else
	CURRENT = $(shell uname -r)
	KDIR = /lib/modules/$(CURRENT)/build
	PWD = $(shell pwd)

default:
	$(MAKE) -C $(KDIR) M=$(PWD) modules
	sudo make clean

clean:
	rm -rf .tmp_versions
	rm .fortune.*
	rm *.o
	rm *.mod.c
	rm *.symvers
	rm *.order

endif