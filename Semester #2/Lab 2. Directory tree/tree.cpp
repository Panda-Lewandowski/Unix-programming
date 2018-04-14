#include <dirent.h> 
#include <limits.h>
#include <stdio.h> //perror
#include <stdlib.h> //exit
#include <errno.h> 
#include <unistd.h> //pathconf
#include <string.h> //strncpy
#include <sys/types.h> //stat
#include <sys/stat.h> 
#include <stack>
#include <iostream>

using namespace std;

#define FTW_F 1 //файл, не являющийся каталогом
#define FTW_D 2 //каталог
#define FTW_DNR 3 //каталог, недоступный для чтения
#define FTW_NS 4 //файл, информацию о котором нельзя получить с помощью stat

// функция, которая будет вызываться для каждого встреченного файла
typedef void Handler(const char * , int, int);

static Handler counter;
static int my_ftw(char *, Handler * );
static int dopath(const char* filename, int depth, Handler * );

static long nreg, ndir, nblk, nchr, nfifo, nslink, nsock, ntot;

int main(int argc, char * argv[])
{
   int ret = -1; 
   if (argc != 2)
   {
      printf("Использование: ftw <начальный каталог>\n");
      exit(-1);
   }

   ret = my_ftw(argv[1], counter); //выполняет всю работу

   ntot = nreg + ndir +  nblk + nchr +  nfifo + nslink + nsock;

    if (ntot == 0)
		ntot = 1; //во избежание деления на 0; вывести 0 для всех счетчиков
	
	printf("_______________________________\nSummary:\n\n");
	printf("common files:\t%7ld, %5.2f %%\n", nreg, nreg*100.0/ntot);
	printf("catalogs:\t%7ld, %5.2f %%\n", ndir, ndir*100.0/ntot);
	printf("block-devices:\t%7ld, %5.2f %%\n", nblk, nblk*100.0/ntot);
	printf("char-devices:\t%7ld, %5.2f %%\n", nchr, nchr*100.0/ntot);
	printf("FIFOs:\t\t%7ld, %5.2f %%\n", nfifo, nfifo*100.0/ntot);
	printf("sym-links:\t%7ld, %5.2f %%\n", nslink, nslink*100.0/ntot);
	printf("sockets:\t%7ld, %5.2f %%\n\n", nsock, nsock*100.0/ntot);
    printf("Total:\t%7ld\n", ntot);

    exit(ret);
}

//обоходит дерево каталогов, начиная с pathname и применяя к каждому файлу func
static int my_ftw(char * pathname, Handler * func)
{
    return(dopath(pathname, 0, func));
} 



//обход дерева каталогов, начиная с fullpath
static int dopath(const char* filename, int depth, Handler * func)
{
    struct dirent * dirp;
    DIR * dp;
    int ret;
    const char * curr;
    const char * next;
    const char * to_ret;
    //Stack<const char *> dir_stack(1024);
    stack<const char *> dir_stack;
        
    dir_stack.push(filename);
    next = "";

    

    
    while (!dir_stack.empty())
    {
        curr = dir_stack.top();  
        dir_stack.pop(); 
        if (dir_stack.size() > 0)
            next = dir_stack.top();
        else
            next = "";

        if ((dp = opendir(curr)) == NULL) //каталог недоступен
        {
            if(strcmp("", curr) != 0)
                func(curr, DT_DIR, FTW_DNR);
            continue;
        }
        else
        {
            for (int i = 0; i < depth; ++i)
                printf("         |");
            chdir(curr);
            depth++; 
            func(curr, DT_DIR, FTW_D);
            while ((dirp = readdir(dp)) != NULL)
            {
                if (strcmp(dirp->d_name, ".") == 0 ||
                    strcmp(dirp->d_name, "..") == 0 ||
                    strcmp(dirp->d_name, ".DS_Store") == 0)
                    continue; //пропустить каталоги . и ..
                                
                    for (int i = 0; i < depth; ++i)
                        printf("         |");

                    if (dirp->d_type != DT_DIR) //не каталог 
                    {
                        func(dirp->d_name, dirp->d_type, FTW_F); //отобразить в дереве 
                    }
                    else
                    {  
                        dir_stack.push(dirp->d_name);
                    }
                    
                    
            }
            
            if (closedir(dp) < 0)
                perror("Невозможно закрыть каталог");

            if(dir_stack.size() > 0)
            {
                if (strcmp(dir_stack.top(), next) == 0)
                {    
                    chdir("..");
                    depth--;
                }
            }
        }
      
    };
    return(ret);    
}

static void counter(const char* pathname, int stat, int type)
{
    switch(type)
    {
        case FTW_F: 
            printf("%s\n", pathname);
            switch(stat)
            {
                case DT_REG: nreg++; break;
                case DT_BLK: nblk++; break;
                case DT_CHR: nchr++; break;
                case DT_FIFO: nfifo++; break;
                case DT_LNK: nslink++; printf("_____\n");break;
                case DT_SOCK: nsock++; break;
                case DT_DIR: 
                    perror("Католог имеет тип FTW_F"); break;
            }
            break;
        case FTW_D: 
            printf(">> %s\n", pathname);
            ndir++; break;
        case FTW_DNR:
            perror("Закрыт доступ к одному из каталогов!"); break;
        case FTW_NS:
            perror("Ошибка функции stat!"); break;
        default: 
            perror("Неизвестый тип файла!");  break;
    }
}






