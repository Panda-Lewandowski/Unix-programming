/*
* íàïèñàòü ïðîãðàììó ïî ñõåìå ïåðâîãî çàäàíèÿ, íî â ïðîöåññå-ïðåäêå 
* âûïîëíèòü ñèñòåìíûé âûçîâ wait(). Óáåäèòüñÿ, ÷òî â ýòîì ñëó÷àå 
* èäåíòèôèêàòîð ïðîöåññà ïîòîìêà íà 1 áîëüøå èäåíòèôèêàòîðà 
* ïðîöåññà-ïðåäêà.
*/

#include <stdio.h> //printf
#include <stdlib.h> //exit
#include <sys/types.h> //W***
#include <sys/wait.h> //wait


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
        //ïîòîìñòâåííûé êîä
        printf( "Child: pid=%d;	group=%d;	parent=%d\n", getpid(), getpgrp(), getppid() );
        int ret_value = getpid() % 2;
        printf( "Child: returning %d.\n", ret_value);
        return ret_value;
	}
	else
	{
		//ðîäèòåëüñêèé êîä
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
