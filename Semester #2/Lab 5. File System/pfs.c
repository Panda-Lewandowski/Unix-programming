#include <linux/buffer_head.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/slab.h>

static const unsigned long PFS_MAGIC_NUMBER = 0x31337;

static inline struct pfs_super_block *PFS_SB(struct super_block *sb)
{
    return (struct pfs_super_block *)sb->s_fs_info;
}

static void pfs_put_super(struct super_block *sb)
{
    struct pfs_super_block *psb = PFS_SB(sb);

    if (psb)
        kfree(psb);
    sb->s_fs_info = NULL;
    printk(KERN_INFO "pfs super block destroyed!\n");
}

static struct super_operations const pfs_super_ops = {
    .put_super = pfs_put_super,
    .statfs = simple_statfs ,
    .drop_inode = generic_delete_inode ,
};

static struct inode *pfs_make_inode(struct super_block *sb, int mode)
{
    struct inode *ret = new_inode(sb);
    if (ret) {
        inode_init_owner(ret, NULL, mode); 
        ret->i_size = PAGE_SIZE;
        ret->i_atime = ret->i_mtime = ret->i_ctime = current_time(ret);
    }
return ret; 
}

static int pfs_fill_sb(struct super_block *sb, void *data, int silent)
{
    struct inode *root = NULL;

    sb->s_blocksize = PAGE_SIZE; 
    sb->s_blocksize_bits = PAGE_SHIFT;
    sb->s_magic = PFS_MAGIC_NUMBER;
    sb->s_op = &pfs_super_ops;

    root = pfs_make_inode(sb, S_IFDIR | 0755);
    if (!root)
    {
        printk(KERN_ERR "inode allocation failed!\n");
       return -ENOMEM;
    }

    root->i_op = &simple_dir_inode_operations; 
    root->i_fop = &simple_dir_operations;

    sb->s_root = d_make_root(root);
    if (!sb->s_root)
    {
        printk(KERN_ERR "root creation failed!\n");
        return -ENOMEM;
    }

	return 0;
}


static struct dentry *pfs_mount(struct file_system_type *type, 
                                int flags, char const *dev, void *data)
{
    struct dentry *const entry = mount_bdev(type, flags, dev, data, pfs_fill_sb);
    if (IS_ERR(entry))
        printk(KERN_ERR "pfs mounting failed!\n");
    else
        printk(KERN_INFO "pfs mounted\n");
    return entry;
}

static struct file_system_type pfs_type = {
    .owner = THIS_MODULE,
    .name = "pfs",
    .mount = pfs_mount,
    .kill_sb = kill_block_super,
    .fs_flags = FS_REQUIRES_DEV, 
};

static int __init pfs_init(void)
{
    int ret = register_filesystem(&pfs_type);
    if (ret != 0) {
	printk(KERN_ERR "Cannot register filesystem!\n");
	return ret;
    }

    printk(KERN_INFO "pfs module loaded\n");
    return 0;
}

static void __exit pfs_exit(void)
{
    int ret = unregister_filesystem(&pfs_type);

    if (ret != 0)
        printk(KERN_ERR "Cannot unregister filesystem!\n");
    printk(KERN_INFO "pfs module unloaded\n");
}

module_init(pfs_init);
module_exit(pfs_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Pandora");
