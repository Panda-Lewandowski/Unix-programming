#include <linux/module.h> // module_init, ...
#include <linux/kernel.h> // printk
#include <linux/init.h> //__init, __exit


/* Лицензия, иначе будет kernel panic*/
MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Pandoral");
MODULE_DESCRIPTION("MD2 loadable kernel module");

extern char* export_char;
extern int export_int;
extern char* even_or_odd(int num);
extern int factorial(int num);
extern int return_zero(void);

/* Init-функция, вызываемая при загрузке модуля */
static int __init md3_init(void) {
	printk(KERN_INFO "Module 3 is loaded.\n");

    printk(KERN_INFO "MD3: Export char* from MD1 - %s.\n", export_char);
    printk(KERN_INFO "MD3: Export int from MD1 - %d.\n", export_int);

    printk(KERN_INFO "MD3: Function 'even_or_odd(2)' from MD1 return %s.\n", even_or_odd(2));
    printk(KERN_INFO "MD3: Function 'even_or_odd(3)' from MD1 return %s.\n", even_or_odd(3));

    printk(KERN_INFO "MD3: Function 'factorial(0)' from MD1 return %d.\n", factorial(0));
    printk(KERN_INFO "MD3: Function 'factorial(5)' from MD1 return %d.\n", factorial(5));

    printk(KERN_INFO "MD3: Function 'return_zero' from MD1 return %d.\n", return_zero());

    printk(KERN_INFO "MD3: ERROR was occured.\n");
    
    return -1; // -1 Operation not permitted, -5 Input/output error

}

/* Cleanup-функция, вызываемая при выгрузке модуля */
static void __exit md3_cleanup(void) {
	printk(KERN_INFO "Module 3 is unloaded.\n");
}


/* Ядру сообщаются названия функций, вызываемых при загрузке и выгрузке модуля */
module_init(md3_init);
module_exit(md3_cleanup);
