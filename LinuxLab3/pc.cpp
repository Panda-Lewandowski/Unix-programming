#include <sys/shm.h> //shmat(), shmget()
#include <sys/sem.h> //semop(), semget()
#include <sys/ipc.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <unistd.h> //fork(), getpid()
#include <sys/wait.h> //wait()

#include <stdlib.h> //exit(), rand()
#include <stdio.h> //printf()
#include <time.h> //sleep()

#define ALL_PERMS S_IRWXU|S_IRWXG|S_IRWXO

#define SB 0
#define SE 1
#define SF 2

#define P -1
#define V 1

#define PROD_COUNT 3
#define CONS_COUNT 3
#define MAX_ITEM 5
#define SIZE_BUF sizeof(int) * MAX_ITEM
#define MAX_ACT 5

struct sembuf prod_P[2] = { {SE, P, 0}, {SB, P, 0} };
struct sembuf prod_V[2] = { {SB, V, 0}, {SF, V, 0} };
struct sembuf cons_P[2] = { {SF, P, 0}, {SB, P, 0} };
struct sembuf cons_V[2] = { {SB, V, 0}, {SE, V, 0} };

int n = 0;
int pos_prod = 0;
int pos_conc = 0;

void Consume(int sem_id, int shm_id )
{
	int *shm = (int*)shmat( shm_id, NULL, 0 );
	if ( shm == (int*)-1 )
	{
		perror( "!!! Can't attach shared memory." );
		exit( 4 );
	}
	
	
	for(int i = 0; i < MAX_ACT; i++)
	{
		int sem_op_p = semop(sem_id, cons_P, 2);
		if ( sem_op_p == -1 )
		{
			perror( "!!! Can't make operation on semaphors." );
			exit( 5 );
		}

		printf("Concumer with pid %d reads: %d on %d place\n", getpid(), shm[pos_conc], pos_conc);
		pos_conc++;

		int sem_op_v = semop(sem_id, cons_V, 2);
		if ( sem_op_v == -1 )
		{
			perror( "!!! Can't make operation on semaphors." );
			exit( 5 );
		}
		
		sleep(rand() % 5);
	}
	
	int shm_dt = shmdt( shm );
	if ( shm_dt == -1 )
	{
		perror( "!!! Can't detach shared memory" );
		exit( 4 );
	}

}

void Produce(int sem_id, int shm_id )
{
	int *shm = (int*)shmat( shm_id, NULL, 0 );
	if ( shm == (int*)-1 )
	{
		perror( "!!! Can't attach shared memory." );
		exit( 2 );
	}

	for( int i = 0; i < MAX_ACT; i++)
	{
		int sem_op_p = semop(sem_id, prod_P, 2);
		if ( sem_op_p == -1 )
		{
			perror( "!!! Can't make operation on semaphors." );
			exit( 4 );
		}

		shm[pos_prod] = n;
		printf( "Producer with pid %d write %d on %d place\n", getpid(), shm[pos_prod], pos_prod);
		n++;
		pos_prod++;

		int sem_op_v = semop(sem_id, prod_V, 2);
		if ( sem_op_v == -1 )
		{
			perror( "!!! Can't make operation on semaphors." );
			exit( 4 );
		}
		
		sleep(rand() % 5);
	}
	

	int shm_dt = shmdt( shm );
	if ( shm_dt == -1 )
	{
		perror( "!!! Can't detach shared memory" );
		exit( 4 );
	}

	

}





int main(int argc, char const *argv[]) {
	
	srand( time(0) );

  	int parent_pid = getpid();
  	printf("Parent pid: %d\n", parent_pid);
	int count_conc = 0;
	int count_prod = 0;

  	int childs[CONS_COUNT + PROD_COUNT];

	int sem_id = semget(IPC_PRIVATE, 3, IPC_CREAT|ALL_PERMS);
	

	if ( sem_id == -1 )
	{
		perror( "!!! Can't get semaphors." );
		exit( 1 );
	}
	
	int shm_id = shmget(IPC_PRIVATE, SIZE_BUF, IPC_CREAT|ALL_PERMS);
	if ( shm_id == -1 )
	{
		perror( "!!! Can't get shared memory." );
		exit( 1 );
	}

	int ctrl_se = semctl(sem_id, SE, SETVAL, MAX_ITEM);
	int ctrl_sf = semctl(sem_id, SF, SETVAL, 0);
	int ctrl_sb = semctl(sem_id, SB, SETVAL, 1);
	
	if ( ctrl_se == -1 || ctrl_sf == -1 || ctrl_sb == -1)
	{
		perror( "!!! Can't set control semaphors." );
		exit( 2 );
	}

  	for (int i = 0; i < CONS_COUNT + PROD_COUNT; i++)
	{
		childs[i] = fork();
		if ( childs[i] == -1 )
		{
        	perror( "!!! Can't fork." );
			exit( 3 );
		}

		if ( getpid() != parent_pid ) // in children procs - cleansing previous call (if can) and immidiately leaving cycle
		{
			for (int j = 0; j < i; j++)
				childs[j] = -1;
			break;
		}

		

		switch (i % 2)
		{
			case 0:
				count_prod ++;
				printf( " * fork %d (Producer #%d)\n", childs[i], count_prod);
				break;
			case 1:
				count_conc ++;
				printf( " * fork %d (Concumer #%d)\n", childs[i], count_conc);
				break;
		}
	}

	// starting mainloops in children procs
	for (int i = 0; i < CONS_COUNT + PROD_COUNT; i++)
	{
		if ( childs[i] != 0 ) // skipping the cycle in main program and incorrect children
			continue;

		if ( i % 2 == 0 )
		{
			Produce( sem_id, shm_id );
			return 0;
		}
		
		if ( i % 2 == 1)
		{
			Consume( sem_id, shm_id );
			return 0;
		}
	}
	
	if ( getpid() == parent_pid )
	{
		for (int i=0; i < CONS_COUNT + PROD_COUNT; i++)
			wait(NULL);
	}
	
    
  
  return 0;
}
