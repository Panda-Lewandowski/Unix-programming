#include <linux/module.h>


/* Лицензия, иначе будет kernel panic*/
MODULE_LICENSE("GPL");


/* Init-функция, вызываемая при загрузке модуля */
int
my_module_init(void) {
	printk(KERN_INFO "my_module_init called.  Module is now loaded.\n");
	
	return 0;
}

/* Cleanup-функция, вызываемая при выгрузке модуля */
void
my_module_cleanup(void) {
	printk(KERN_INFO "my_module_cleanup called.  Module is now unloaded.\n");
	
	return;
}


/* Ядру сообщаются названия функций, вызываемых при загрузке и выгрузке модуля */
module_init(my_module_init);
module_exit(my_module_cleanup);