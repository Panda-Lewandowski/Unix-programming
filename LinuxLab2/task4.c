/*
* Ќаписать программу, в которой предок и потомок обмениваютс€ 
* сообщением через программный канал.
*/

#include <stdio.h> //printf
#include <stdlib.h> //exit
#include <unistd.h> //pipe
#include <string.h> //strlen


int main()
{
	int descr[2]; //дескриптор _одного_ программного канала
	//[0] - выход дл€ чтени€, [1] - выход дл€ записи
	//потомок унаследует открытый программный канал предка

	if ( pipe(descr) == -1)
	{
        perror( "Couldn't pipe." );
		exit(1);
	}

	int child = fork();
	if ( child == -1 )
	{
        perror( "Couldn't fork." );
		exit(1);
	}
	if ( child == 0 )
	{
		//потомственный код
        close( descr[1] ); //потомок ничего не запишет в канал

		char msg[64];
		memset( msg, 0, 64 );
		int i = 0;
		
		//последовательно считываем из программного канала по 1 символу
		while( read(descr[0], &(msg[i++]), 1) != '\0' ) ;
			
        printf( "Child: read <%s>\n", msg );
	}
	else
	{
		//родительский код
		close( descr[0] ); //предок ничего не считает из канала
        printf( "Parent: input string to transmit:\n" );
		char msg[64];
		gets(msg);
		msg[63]='\0';
        write( descr[1], msg, strlen(msg) ); //передаЄм сообщение в канал
		return 0;
	}
}
