#include <dirent.h> 
#include <limits.h>
#include <stdio.h> //perror
#include <stdlib.h> //exit
#include <errno.h> 
#include <unistd.h> //pathconf
#include <string.h> //strncpy
#include <sys/types.h> //stat
#include <sys/stat.h> 


#define FTW_F 1 //файл, не являющийся каталогом
#define FTW_D 2 //каталог
#define FTW_DNR 3 //каталог, недоступный для чтения
#define FTW_NS 4 //файл, информацию о котором нельзя получить с помощью stat

#define PATH_MAX_GUESS 1024

#define SUSV3 200112L

#ifdef PATH_MAX
static int pathmax = PATH_MAX;
#else
static int pathmax = 0;
#endif

static long posix_version = 0;

// функция, которая будет вызываться для каждого встреченного файла
typedef int Handler(const char * ,const struct stat *, int);

static Handler counter;
static int my_ftw(char *, Handler * );
static int dopath(Handler * );

static char * fullpath; //полный путь к каждому из файлов

static long nreg, ndir, nblk, nchr, nfifo, nslink, nsock, ntot;

int main(int argc, char * argv[])
{
   
   if (argc != 2)
      perror("Использование: ftw <начальный каталог>");
   
   int ret; 

   ret = my_ftw(argv[1], counter); //выполняет всю работу

   ntot = nreg + ndir +  nblk + nchr +  nfifo + nslink + nsock;

    printf("%ld %ld %ld %ld %ld %ld %ld %ld\n", nreg, ndir, nblk, nchr, nfifo, nslink, nsock, ntot);

    exit(ret);
}

char * path_alloc(int *sizep)
{
   char *ptr;
   int size;

    if (posix_version == 0)
        posix_version = sysconf(_SC_VERSION);
   
    if (pathmax == 0) 
    {
        errno = 0;
        if ((pathmax = pathconf("/", _PC_PATH_MAX)) < 0) 
        {
            if(errno == 0)
                pathmax = PATH_MAX_GUESS;
            else
                perror("pathconf error for _PC_PATH_MAX");
        } else 
        {
            pathmax++;
        }
    }
      
    if (posix_version < SUSV3)
        size = pathmax + 1;
    else
        size = pathmax;
    
    if ((ptr = malloc(size)) == NULL)
        perror("malloc error for pathname");
    
    if(sizep != NULL)
        *sizep = size;
    
    return(ptr);
}


//обоходит дерево каталогов, начиная с pathname и применяя к каждому файлу func
static int my_ftw(char * pathname, Handler * func)
{
    int len;
    fullpath = path_alloc(&len);
    strncpy(fullpath, pathname, len); //защита от переполнения
    fullpath[len-1] = 0;            //буфера
    return(dopath(func));
} 

//обход дерева каталогов, начиная с fullpath
static int dopath(Handler * func)
{
    struct stat statbuf;
    struct dirent * dirp;
    DIR * dp;
    int ret;
    char * ptr;

    if (lstat(fullpath, &statbuf) < 0) //ошибка вызова функции lstat   
        return(func(fullpath, &statbuf, FTW_NS));

    if (S_ISDIR(statbuf.st_mode) == 0) //не каталог 
        return(func(fullpath, &statbuf, FTW_F));

    if ((ret = func(fullpath, &statbuf, FTW_D)) != 0)
        return(ret);

    ptr = fullpath + strlen(fullpath); //установить указатель в конец fullpath

    *ptr++ = '/';
    *ptr = 0;

    if ((dp = opendir(fullpath)) == NULL) //каталог недоступен
        return(func(fullpath, &statbuf, FTW_DNR));
    
    while ((dirp = readdir(dp)) != NULL)
    {
        if (strcmp(dirp->d_name, ".") == 0 ||
            strcmp(dirp->d_name, "..") == 0 )
            continue; //пропустить каталоги . и ..

        strcpy(ptr, dirp->d_name); //добавить имя после слеша

        if ((ret = dopath(func)) != 0) //рекурсия
            break; // выход по ошибке
    }

    ptr[-1] = 0; //стереть часть строки от слеша и до конца

    if (closedir(dp) < 0)
        perror("Невозможно закрыть каталог");

    return(ret);    
}

static int counter(const char* pathame, const struct stat * statptr, int type)
{
    switch(type)
    {
        case FTW_F: 
            switch(statptr->st_mode & S_IFMT)
            {
                case S_IFREG: nreg++; break;
                case S_IFBLK: nblk++; break;
                case S_IFCHR: nchr++; break;
                case S_IFIFO: nfifo++; break;
                case S_IFLNK: nslink++; break;
                case S_IFSOCK: nsock++; break;
                case S_IFDIR: 
                    perror("Католог имеет тип FTW_F"); return(-1);
            }
            break;
        case FTW_D:
            ndir++; break;
        case FTW_DNR:
            perror("Закрыт доступ к одному из каталогов!"); return(-1);
        case FTW_NS:
            perror("Ошибка функции stat!"); return(-1);
        default: 
            perror("Неизвестый тип файла!"); return(-1);
    }
    
    return(0);
}






