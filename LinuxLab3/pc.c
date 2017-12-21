#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/shm.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

const int N = 5;  						
const int COUNT = 10;					
const int PERM = S_IRWXU | S_IRWXG | S_IRWXO;	

int* shared_buffer;
int* sh_pos_cons;
int* sh_pos_prod;

#define SB 0
#define SE 1
#define SF 2

#define P -1
#define V 1

struct sembuf producer_start[2] = { {SE, P, 0}, {SF, P, 0} };
struct sembuf producer_stop[2] =  { {SB, V, 0}, {SF, V, 0} };
struct sembuf consumer_start[2] = { {SB, P, 0}, {SF, P, 0} };
struct sembuf consumer_stop[2] =  { {SE, V, 0}, {SF, V, 0} };


void producer(const int semid, const int value)
{
	sleep(rand() % 5);
	int sem_op_p = semop(semid, producer_start, 2);
	if ( sem_op_p == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}
		
	shared_buffer[*sh_pos_prod] = *sh_pos_prod;
	printf("Producer #%d ----> %d\n", value, shared_buffer[*sh_pos_prod]);
	(*sh_pos_prod)++;
	
	
	int sem_op_v = semop(semid, producer_stop, 2);
	if ( sem_op_v == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}
}

void consumer(const int semid, const int value)
{
	sleep(rand() % 2);
	int sem_op_p = semop(semid, consumer_start, 2);
	if ( sem_op_p == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}
	
	printf("Consumer #%d <---- %d\n", value, shared_buffer[*sh_pos_cons]);
	(*sh_pos_cons)++;
	int sem_op_v = semop(semid, consumer_stop, 2);
	if ( sem_op_v == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}
	
}

int main()
{
	int shmid, semid; 

	int parent_pid = getpid();
  	printf("Parent pid: %d\n", parent_pid);

	if ((shmid = shmget(IPC_PRIVATE, (N + 1) * sizeof(int), IPC_CREAT | PERM)) == -1) 
	{
		perror("!!! Unable to create a shared area.\n");
		exit( 1 );
	}

	sh_pos_prod = shmat(shmid, 0, 0); 
	if (*sh_pos_prod == -1)
	{
		perror("!!! Can't attach memory");
		exit( 1 );
	}


	shared_buffer = sh_pos_prod + 2 * sizeof(int); 
	sh_pos_cons = sh_pos_prod + sizeof(int);

	(*sh_pos_prod) = 0;
	(*sh_pos_cons) = 0;
	

	if ((semid = semget(IPC_PRIVATE, 3, IPC_CREAT | PERM)) == -1) 
	{
		perror("!!! Unable to create a semaphore.\n");
		exit( 1 );
	}

	int ctrl_sb = semctl(semid, SB, SETVAL, 0);
	int ctrl_se = semctl(semid, SE, SETVAL, N); 
	int ctrl_sf = semctl(semid, SF, SETVAL, 1); 

	if ( ctrl_se == -1 || ctrl_sf == -1 || ctrl_sb == -1)
	{
		perror( "!!! Can't set control semaphors." );
		exit( 1 );
	}


	pid_t pid;
	if ((pid = fork()) == -1)
	{
		perror("!!! Can't create new process.\n");
		exit( 1 );
	}

	if (pid == 0)
	{
		int value = 0;
		while (value < COUNT)
		{
			producer(semid, value);
			value++;
		}
	}
	else 
	{
		int value = 0;
		while (value < COUNT) 
		{
			consumer(semid, value);
			value++;
		}	
	}

	if (pid != 0) 
	{
		int status;
		wait(&status);

		if (shmdt(sh_pos_prod) == -1) 
		{
			perror( "!!! Can't detach shared memory" );
			exit( 1 );
		}
	}
}
