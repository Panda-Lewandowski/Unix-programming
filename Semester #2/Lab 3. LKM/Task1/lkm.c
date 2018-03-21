#include <linux/module.h> // module_init, ...
#include <linux/kernel.h> // printk
#include <linux/init.h> //__init, __exit


/* Лицензия, иначе будет kernel panic*/
MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Pandoral");
MODULE_DESCRIPTION("Simple loadable kernel module");


/* Init-функция, вызываемая при загрузке модуля */
static int __init my_module_init(void) {
	printk(KERN_INFO "Hello World!  Module is now loaded.\n");
	return 0;
}

/* Cleanup-функция, вызываемая при выгрузке модуля */
static void __exit my_module_cleanup(void) {
	printk(KERN_INFO "Good bye!  Module is now unloaded.\n");
}


/* Ядру сообщаются названия функций, вызываемых при загрузке и выгрузке модуля */
module_init(my_module_init);
module_exit(my_module_cleanup);
