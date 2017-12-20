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
#define WRITER 3			
const int PERM = S_IRWXU | S_IRWXG | S_IRWXO;	

int* shared_buffer;
int* sh_pos_reader;
int* sh_pos_writer;

// София, [Dec 19, 2017, 8:06:02 PM]:
// struct sembuf start_reader[5] = {{RR, 1, 0}, {SB, 0, 0}, {WR, 0, 0}, {RI, 1, 0}, {RR, -1, 0}},

//        stop_reader[1] = {{RI, -1, 0}},

//        // уменьшаем кол-во ждущих читателей
//        one_up[1] = {{SB, 1, 0}},

//        start_writer_w[1] = {{WR, 1, 0}},
//        start_writer_s[3] = {{RI, 0, 0}, {SB,  -1, 0}, {WR, -1, 0}},
//        stop_writer[1]  = {{SB, 1, 0}, {RI, -1, 0}};

// #define RR  3 // ждущие читатели
// #define SB  2 // бинарный
// #define WR  1 // ждущие писатели
// #define RI  0 // активные читатели

enum SemIds { NReaders,  /* число активных читателей */
 			 ActiveWriter,  /* активный писатель */ 
 			 WaitingReaders, /* ждущий  читатель  */
			 WaitingWriters }; /* ждущие писатели */ 

struct sembuf start_read[] =  { { WaitingReaders,  1, 0 }, 
								{ ActiveWriter,   0, 0 }, 
								{ WaitingWriters, 0, 0 }, 
								{ WaitingReaders, -1, 0 },
								{ NReaders, 	  1, 0 } };	

struct sembuf stop_read[]  =  { { NReaders,      -1, 0 } };

struct sembuf start_write[] = { { WaitingWriters,  1, 0 }, 
								{ NReaders,        0, 0 }, 
								{ ActiveWriter,   1, 0 },  
								{ WaitingWriters, -1, 0 } };	

struct sembuf stop_write[] =  { { ActiveWriter, 0, 0 }, 
								{ WaitingReaders, -1, 0 } 
								};

void start_reading(const int semid)
{
	int sem_op = semop(semid, start_read, 5);
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
	int sem_op = semop(semid, start_write, 3);
	if ( sem_op == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}
}

void stop_writing(const int semid)
{
	int sem_op = semop(semid, stop_write, 1);
	if ( sem_op == -1 )
	{
		perror( "!!! Can't make operation on semaphors." );
		exit( 1 );
	}
}

void writer(const int semid, const int value)
{
	start_writing(semid);

	shared_buffer[*sh_pos_writer] = *sh_pos_writer;
	printf("Writer #%d ----> %d\n", value, shared_buffer[*sh_pos_writer]);
	(*sh_pos_writer)++;
		

	stop_writing(semid);
	nice(15);

	
	sleep(rand() % 2);
	exit(0);
	
	
}

void reader(const int semid, const int value)
{
	
	start_reading(semid);

	printf("Reader #%d <---- %d\n", value, shared_buffer[*sh_pos_reader]);
	(*sh_pos_reader)++;
		
	stop_reading(semid); 
	nice(15);

	
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

	sh_pos_writer = shmat(shmid, 0, 0); 
	if (*sh_pos_writer == -1)
	{
		perror("!!! Can't attach memory");
		exit( 1 );
	}


	shared_buffer = sh_pos_writer + 2 * sizeof(int); 
	sh_pos_reader = sh_pos_writer + sizeof(int);

	(*sh_pos_writer) = 0;
	(*sh_pos_reader) = 0;
	

	if ((semid = semget(IPC_PRIVATE, 4, IPC_CREAT | PERM)) == -1) 
	{
		perror("!!! Unable to create a semaphore.\n");
		exit( 1 );
	}

	int ctrl_nr = semctl(semid, NReaders,       SETVAL, 0);
    int ctrl_aw = semctl(semid, ActiveWriter,   SETVAL, 0);
    int ctrl_mc = semctl(semid, WaitingReaders,  SETVAL, 0);
    int ctrl_ww = semctl(semid, WaitingWriters, SETVAL, 0);

	if ( ctrl_nr == -1 || ctrl_aw == -1 || ctrl_mc == -1 || ctrl_ww == -1)
	{
		printf("%d %d %d %d \n", ctrl_nr, ctrl_aw, ctrl_mc, ctrl_ww);
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

	while (wait(NULL) != -1) {}
	
	if (shmdt(sh_pos_writer) == -1) 
	{
		perror( "!!! Can't detach shared memory" );
		exit( 1 );
	}
	


}