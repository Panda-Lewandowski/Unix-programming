/*
* Написать программу, в которой предок и потомок обмениваются 
* сообщением через программный канал.
*/

#include <stdio.h> //printf
#include <stdlib.h> //exit
#include <unistd.h> //pipe
#include <string.h> //strlen


int main()
{
	int descr[2]; //дескриптор _одного_ программного канала
	//[0] - выход для чтения, [1] - выход для записи
	//потомок унаследует открытый программный канал предка

	if ( pipe(descr) == -1)
	{
        perror( "Couldn't pipe." );
		exit(1);
	}

    int child1 = fork();
    if ( child1 == -1 )
	{
        perror( "Couldn't fork." );
		exit(1);
	}
    if ( child1 == 0 )
	{
		//потомственный код
        close( descr[0] ); //потомок ничего не запишет в канал

        char msg1[] = "hello1   ";

		//последовательно считываем из программного канала по 1 символу
        write(descr[1], msg1, 64);

        exit(0);
	}

    int child2 = fork();
    if ( child2 == -1 )
    {
        perror( "Couldn't fork." );
        exit(1);
    }
    if ( child2 == 0 )
    {
        //потомственный код
        close( descr[0] ); //потомок ничего не запишет в канал

        char msg2[] = "hello2   ";

        //последовательно считываем из программного канала по 1 символу
        write(descr[1], msg2, 64);


        exit(0);
	}
	
	if (child1 != 0 && child2 != 0)
	{
		//родительский код
		close( descr[1] ); //предок ничего не считает из канала
		//printf( "Parent: input string to transmit:\n" );
		char msg1[64];
		read( descr[0], msg1, 64); //передаём сообщение в канал

		char msg2[64];
		read( descr[0], msg2, 64); //передаём сообщение в канал

		printf("Parent: reads %s %s", msg1, msg2);

		int status;
		pid_t ret_value;
		ret_value = wait( &status );
		if ( WIFEXITED(status) )
		    printf("Parent: child %d finished with %d code.\n\n", ret_value, WEXITSTATUS(status) );
		else if ( WIFSIGNALED(status) )
		    printf( "Parent: child %d finished from signal with %d code.\n\n", ret_value, WTERMSIG(status));
		else if ( WIFSTOPPED(status) )
			printf("Parent: child %d finished from signal with %d code.\n\n", ret_value, WSTOPSIG(status));
			
		ret_value = wait( &status );
		if ( WIFEXITED(status) )
			printf("Parent: child %d finished with %d code.\n\n", ret_value, WEXITSTATUS(status) );
		else if ( WIFSIGNALED(status) )
			printf( "Parent: child %d finished from signal with %d code.\n\n", ret_value, WTERMSIG(status));
		else if ( WIFSTOPPED(status) )
			printf("Parent: child %d finished from signal with %d code.\n\n", ret_value, WSTOPSIG(status));

    }

    return 0;
}
