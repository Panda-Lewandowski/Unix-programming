/*
* Написать программу, в которой процесс-потомок вызывает системный 
* вызов exec(), а процесс-предок ждет завершения процесса-потомка.
*/

#include <stdio.h> //printf
#include <stdlib.h> //exit
#include <unistd.h> //execlp


int main()
{
	int child = fork();
	if ( child == -1 )
	{
        perror("Couldn't fork.");
		exit(1);
	}
    if ( child == 0 )
	{
		//потомственный код
        printf( "Child: pid=%d;	group=%d;	parent=%d\n\n", getpid(), getpgrp(), getppid() );
        if ( execlp("ps", "ps", "al", 0) == -1 )
		{
            perror( "Child couldn't exec." );
			exit(1);
        }
	}
	else
	{
        //родительский код
        printf( "Parent: pid=%d;	group=%d;	child=%d\n", getpid(), getpgrp(), child );
        int status;
        pid_t ret_value;
        ret_value = wait( &status );
        if ( WIFEXITED(status) )
            printf("Parent: child %d finished with %d code.\n", ret_value, WEXITSTATUS(status) );
        else if ( WIFSIGNALED(status) )
            printf( "Parent: child %d finished from signal with %d code.\n", ret_value, WTERMSIG(status));
        else if ( WIFSTOPPED(status) )
            printf("Parent: child %d finished from signal with %d code.\n", ret_value, WSTOPSIG(status));
        return 0;
	}
}
