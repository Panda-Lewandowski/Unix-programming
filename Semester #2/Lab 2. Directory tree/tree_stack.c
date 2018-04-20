#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <dirent.h>
#include <limits.h>
#include <unistd.h>
#include "stack.h"
 
static int fileTree(char*);
 
int main(int argc, char* argv[])
{
    if (argc != 2)
    {
        printf("Usage: ./dir <dir>\n");
        return -1;
    }
 
    int ret = fileTree(argv[1]);
 
    return ret;
}

// Вывод дерева каталогов
static int fileTree(char* pathname)
{
    struct dirent *dirp;
    DIR *dp;
    int ret, lvl = 0, flag = 1;
    char *path, *workpath = calloc(PATH_MAX, sizeof(char));
	stack *st = createStack(10);

	pushStack(st, pathname);
 
	while ((st->len != 0) && flag)
	{
		path = pullStack(st);
		if (strcmp(path, "..") == 0)
		{
			lvl--;
			chdir("..");
		}
		else
		{
			pushStack(st, "..");
			for (int i = 0; i < lvl; i++)
				printf("|\t");
			printf("|%s/\n", path);
			chdir(path);
			lvl++;
			getcwd(workpath, PATH_MAX);

			if ((dp = opendir(workpath)) == NULL)
			{
				flag = 0;
				printf("Can't open dir %s! Private directory!\n", workpath);
				ret = -1;
			}
			else
			{	
				while ((dirp = readdir(dp)) != NULL)
				{
					if ((strcmp(dirp->d_name, ".") != 0) && 
						(strcmp(dirp->d_name, "..") != 0) && 
						(strcmp(dirp->d_name, ".DS_Store") != 0))
					{				
						if (dirp->d_type == DT_DIR)
						{
							pushStack(st, dirp->d_name);
						}
						else
						{
							for (int i = 0; i < lvl; i++)
								printf("|\t");
							printf("|%s\n", dirp->d_name);
						}
					}
				}

				if (closedir(dp) < 0)
		        {
		        	printf("Can't close dir %s\n", workpath);
					flag = 0;
					ret = -2;
		        }
			}
		}
	}

	free(path);
	free(workpath);
	freeStack(st);
    return ret;
}