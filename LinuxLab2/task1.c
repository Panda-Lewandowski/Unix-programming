/*
* Написать программу, запускающую новый процесс системным вызовом 
* fork(). В предке вывести собственный идентификатор ( функция 
* getpid()), идентификатор группы ( функция getpgrp())  и 
* идентификатор потомка. В процессе-потомке вывести собственный 
* идентификатор, идентификатор предка ( функция getppid()) и 
* идентификатор группы. Убедиться, что при завершении процесса-предка 
* потомок получает идентификатор предка (PPID), равный 1.
*/
#include <stdio.h> //printf
#include <stdlib.h> //exit


int main()
{
	int child = fork();
	if ( child == -1 )
	{
		perror("couldn't fork.");
		exit(1);
	}
	if ( child == 0 )
	{
		//потомственный код
		sleep(1);
		printf( "Child: pid=%d;	group=%d;	parent=%d\n", getpid(), getpgrp(), getppid() );

		return 0;
	}
	else
	{
		//родительский код
        printf( "Parent: pid=%d;	group=%d;	child=%d\n", getpid(), getpgrp(), child );
		return 0;
	}
}