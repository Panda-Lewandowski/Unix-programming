#include <linux/module.h> // module_init, ...
#include <linux/kernel.h> // printk
#include <linux/init.h> //__init, __exit


/* Лицензия, иначе будет kernel panic*/
MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Pandoral");
MODULE_DESCRIPTION("MD1 loadable kernel module");

char* export_char = "Hello world from md1!";
int export_int = 420;

extern char* even_or_odd(int num)
{
	printk(KERN_INFO "MD1: Running function 'even_or_odd'...\n");

	if (num % 2)
		return "Odd";
	
	return "Even";
}


extern int factorial(int num)
{
	printk(KERN_INFO "MD1: Running function 'factorial'...\n");

	int ans = num;
	int i = 0;
	for (i = num-1; i > 1; i--)
        ans *= i;

	return (ans == 0) ? (1) : (ans);
}

extern int return_zero(void)
{
    printk(KERN_INFO "MD1: Running function 'return_zero'...\n");
    return 0;
}

EXPORT_SYMBOL(export_char);
EXPORT_SYMBOL(export_int);

EXPORT_SYMBOL(even_or_odd);
EXPORT_SYMBOL(factorial);
EXPORT_SYMBOL(return_zero);

/* Init-функция, вызываемая при загрузке модуля */
static int __init md1_init(void) {
	printk(KERN_INFO "Module 1 is loaded.\n");
	return 0;
}

/* Cleanup-функция, вызываемая при выгрузке модуля */
static void __exit md1_cleanup(void) {
	printk(KERN_INFO "Module 1 is unloaded.\n");
}


/* Ядру сообщаются названия функций, вызываемых при загрузке и выгрузке модуля */
module_init(md1_init);
module_exit(md1_cleanup);
