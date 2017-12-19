#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/shm.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define N     20  						
#define READER 5
#define WRITER 5
#define ITER  10					
const int PERM = S_IRWXU | S_IRWXG | S_IRWXO;	

int* shared_buffer;
int* shared_position;
int* begin;

enum SemIds { NReaders,  /* число активных читателей */
 			 ActiveWriter, 
 			 MemCapture, /* блокировка для исключения читетелей писателей */
			 WaitingWriters };

struct sembuf   start_read[] =  { { WaitingWriters, 0, 0 }, { ActiveWriter,    0, 0 }, { NReaders,     1, 0}};
struct sembuf   start_write[] = { { WaitingWriters, 1, 0 }, { NReaders,        0, 0 }, { ActiveWriter, 1, 0}, 
								  { MemCapture,    -1, 0 }, { WaitingWriters, -1, 0 } };	
struct sembuf stop_read[]  =    { { NReaders,      -1, 0 }  };
struct sembuf stop_write[]  =   { { ActiveWriter,  -1, 0 }, { MemCapture,      1, 0 } };

void start_reading(const int semid)
{
	int sem_op = semop(semid, start_read, 3);
	if ( sem_op == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}

}

void stop_reading(const int semid)
{
	int sem_op = semop(semid, stop_read, 1);
	if ( sem_op == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}

}

void start_writing(const int semid)
{
	int sem_op = semop(semid, start_write, 5);
	if ( sem_op == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}
}

void stop_writing(const int semid)
{
	int sem_op = semop(semid, stop_write, 2);
	if ( sem_op == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}
}

void writer(const int semid, const int value)
{
	
	for (int i = 0; i < ITER; ++i) {
		start_writing(semid);

		if (begin - shared_position > N)
		{
			shared_position = begin;
			shared_buffer[*shared_position] = *shared_position;
			printf("Writer #%d ----> %d\n", value + 1, shared_buffer[*shared_position]);
			(*shared_position)++;
		}
		else
		{
			shared_buffer[*shared_position] = *shared_position;
			printf("Writer #%d ----> %d\n", value + 1, shared_buffer[*shared_position]);
			(*shared_position)++;
		}

		stop_writing(semid);
		nice(15);

	}
	sleep(rand() % 2);
	exit(0);
	
	
}

void reader(const int semid, const int value)
{
	
	for (int i = 0; i < ITER; ++i) {

		start_reading(semid);

		(*shared_position)--;
		printf("Reader #%d <---- %d\n", value + 1, shared_buffer[*shared_position]);
		
		stop_reading(semid); 
		nice(15);

	}
	sleep(rand() % 5);
	exit(0);
	
}

int main()
{
	int shmid, semid; 

	int parent_pid = getpid();
  	printf("Parent pid: %d\n", parent_pid);

	if ((shmid = shmget(IPC_PRIVATE, 4, IPC_CREAT | PERM)) == -1) 
	{
		perror("!!! Unable to create a shared area.\n");
		exit( 1 );
	}

	shared_position = shmat(shmid, 0, 0); 
	if (*shared_position == -1)
	{
		perror("!!! Can't attach memory");
		exit( 1 );
	}
	begin = shared_position;
	shared_buffer = shared_position + sizeof(int); 

	(*shared_position) = 0;
	if (*shared_buffer == -1)
	{
		perror("!!! Unable to connect to the shared area.\n");
		exit( 1 );
	}

	if ((semid = semget(IPC_PRIVATE, 4, IPC_CREAT | PERM)) == -1) 
	{
		perror("!!! Unable to create a semaphore.\n");
		exit( 1 );
	}

	int ctrl_nr = semctl(semid, NReaders,       SETVAL, 0);
    int ctrl_aw = semctl(semid, ActiveWriter,   SETVAL, 0);
    int ctrl_mc = semctl(semid, MemCapture,     SETVAL, 1);
    int ctrl_ww = semctl(semid, WaitingWriters, SETVAL, 0);

	if ( ctrl_nr == -1 || ctrl_aw == -1 || ctrl_mc == -1 || ctrl_ww == -1)
	{
		perror( "!!! Can't set control semaphors." );
		exit( 1 );
	}


	pid_t pid;

	for (int i = 0 ; i < WRITER; ++i)
		if ((pid = fork()) != -1)
			if (!pid)
				writer(semid ,i);
			else
				;
		else
			perror ("Fork error while creating writers!\n");
			
		
	for (int i = 0; i < READER; ++i)
		if ((pid = fork()) != -1)
			if (!pid)
				reader(semid , i);
			else
				;
		else
			perror ("Fork error while creating readers!\n");

	// if ((pid = fork()) == -1)
	// {
	// 	perror("Error: can't create new process.\n");
	// 	exit( 1 );
	// }

	// if (getpid() == 0)
	// {
	// 	int value = 0;
	// 	while (value < COUNT)
	// 	{
	// 		reader(semid, value);
	// 		value++;
	// 	}
	// }
	// else 
	// {
	// 	int value = 0;
	// 	while (value < COUNT) 
	// 	{
	// 		writer(semid, value);
	// 		value++;
	// 	}	
	// }

	while (wait(NULL) != -1) {}
	
	if (shmdt(shared_position) == -1) 
	{
		perror( "!!! Can't detach shared memory" );
		exit( 1 );
	}
	


}