#include <linux/module.h> // module_init, ...
#include <linux/kernel.h> // printk
#include <linux/init.h> //__init, __exit
#include <linux/interrupt.h>
#include <linux/timex.h>

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Pandoral");

#define SHARED_IRQ 17
static int irq = SHARED_IRQ, my_dev_id, irq_counter = 0;
module_param( irq, int, S_IRUGO );

char tasklet_data[] = "tasklet_function was called";

void tasklet_function( unsigned long data );

DECLARE_TASKLET( my_tasklet, tasklet_function, 
                 (unsigned long)&tasklet_data );


/* Bottom Half Function */
void tasklet_function( unsigned long data ) {
	printk(KERN_INFO "[TASKLET] state: %ld, count: %d, data: %s",
					 my_tasklet.state, my_tasklet.count, my_tasklet.data);
    return;
}

static irqreturn_t my_interrupt( int irq, void *dev_id ) {
   irq_counter++;
   printk( KERN_INFO "[INTERRUPT] In the ISR: counter = %d\n", irq_counter );
   tasklet_schedule( &my_tasklet );
   return IRQ_NONE;  /* we return IRQ_NONE because we are just observing */
}

static int __init my_tasklet_init(void) {
	if( request_irq( irq, my_interrupt, IRQF_SHARED, "my_interrupt", &my_dev_id ) )
    	return -1;
    printk( KERN_INFO "[INTERRUPT] Successfully loading ISR handler on IRQ %d\n", irq );
	printk(KERN_INFO "[MODULE] Module is now loaded.\n");
	return 0;
}

static void __exit my_tasklet_exit(void) {
	/* Stop the tasklet before we exit */
  	tasklet_kill( &my_tasklet );
	synchronize_irq( irq );
   	free_irq( irq, &my_dev_id );
   	printk( KERN_INFO "[INTERRUPT] Successfully unloading, irq_counter = %d\n", irq_counter );
	printk(KERN_INFO "[MODULE] Module is now unloaded.\n");
  	return;
}

module_init(my_tasklet_init);
module_exit(my_tasklet_exit);
