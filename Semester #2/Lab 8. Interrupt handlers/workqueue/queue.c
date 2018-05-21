#include <linux/module.h> // module_init, ...
#include <linux/kernel.h> // printk
#include <linux/init.h> //__init, __exit
#include <linux/interrupt.h>
#include <linux/workqueue.h>

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Pandoral");

#define SHARED_IRQ 17
static int irq = SHARED_IRQ, my_dev_id, irq_counter = 0;
module_param( irq, int, S_IRUGO );

struct workqueue_struct *wq;
void hardwork_function(struct work_struct *work);

DECLARE_WORK( hardwork, hardwork_function );

/* Bottom Half Function */
void hardwork_function(struct work_struct *work) {
    printk(KERN_INFO "[WQ] data: %d", work->data);
    return;
}

static irqreturn_t my_interrupt( int irq, void *dev_id ) {
   irq_counter++;
   printk( KERN_INFO "[INTERRUPT] In the ISR: counter = %d\n", irq_counter );
   queue_work( wq, &hardwork );
   return IRQ_NONE;  /* we return IRQ_NONE because we are just observing */
}

static int __init my_wokqueue_init(void) {
	if( request_irq( irq, my_interrupt, IRQF_SHARED, "my_interrupt", &my_dev_id ) )
    	return -1;
    printk( KERN_INFO "[INTERRUPT] Successfully loading ISR handler on IRQ %d\n", irq );
    wq = create_workqueue( "my_queue" );
    if ( wq ) {
        printk(KERN_INFO "[MODULE] Workqueue created.\n");
    }

	printk(KERN_INFO "[MODULE] Module is now loaded.\n");
	return 0;
}

static void __exit my_wokqueue_exit(void) {
    flush_workqueue( wq );
    destroy_workqueue( wq );
	synchronize_irq( irq );
   	free_irq( irq, &my_dev_id );
   	printk( KERN_INFO "[INTERRUPT] Successfully unloading, irq_counter = %d\n", irq_counter );
	printk(KERN_INFO "[MODULE] Module is now unloaded.\n");
  	return;
}

module_init(my_wokqueue_init);
module_exit(my_wokqueue_exit);
