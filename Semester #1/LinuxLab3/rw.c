#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/shm.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <signal.h>
#include <unistd.h>

#define WRITERS 2
#define READERS 4

#define ACT_READER 0
#define ACT_WRITER 1
#define BIN_ACT_WRITER 2
#define WAIT_WRITER 3

const int PERM =  S_IRWXU | S_IRWXG | S_IRWXO;



struct sembuf start_read[] = {  { WAIT_WRITER, 0, 0 },
                                  { ACT_WRITER,  0, 0 },
                                  { ACT_READER,  1, 0 } };

struct sembuf  stop_read[] = { {ACT_READER, -1, 0} };

struct sembuf  start_write[] = { { WAIT_WRITER,     1, 0 }, 
                                   { ACT_READER,      0, 0 }, 
                                   { BIN_ACT_WRITER, -1, 0 }, 
                                   { ACT_WRITER,      1, 0 }, 
                                   { WAIT_WRITER,    -1, 0 } };

struct sembuf  stop_write[] = { { ACT_WRITER,    -1, 0 }, 
                                { BIN_ACT_WRITER, 1, 0 }};

#define SEM_COUNT(a) sizeof(a)/sizeof(struct sembuf )

void writer(int semid, int* shm, int num) {
    nice(15);
    while (1) 
    {

        semop(semid, start_write, SEM_COUNT(start_write));

        (*shm)++;
		printf("Writer #%d ----> %d\n", num, *shm);

        semop(semid, stop_write, SEM_COUNT(stop_write));

		sleep(rand() % 5);

    }
}

void reader(int semid, int* shm, int num) {

    while (1) 
    {
        semop(semid, start_read, SEM_COUNT(start_read));

		printf("\tReader #%d <---- %d\n", num, *shm);

        semop(semid, stop_read, SEM_COUNT(stop_read));

		sleep(rand() % 3);

    }
}

int main() {

    srand( time( NULL ) );

    int parent_pid = getpid();
  	printf("Parent pid: %d\n", parent_pid);

    int shm_id;
    if ((shm_id = shmget(IPC_PRIVATE, 4, IPC_CREAT | PERM)) == -1) 
	{
		perror("!!! Unable to create a shared area.\n");
		exit( 1 );
	}

    int *shm_buf = shmat(shm_id, 0, 0); 
    if (shm_buf == (void*) -1) 
    {
        perror("!!! Can't attach memory");
        exit( 1 );
    }

    (*shm_buf) = 0;

    int sem_id;
    if ((sem_id = semget(IPC_PRIVATE, 4, IPC_CREAT | PERM)) == -1) 
	{
		perror("!!! Unable to create a semaphore.\n");
		exit( 1 );
	}

	int ctrl = semctl(sem_id, BIN_ACT_WRITER, SETVAL, 1);
    if ( ctrl == -1)
	{
		perror( "!!! Can't set control semaphors." );
		exit( 1 );
	}

	pid_t pid = -1;

	for (int i = 0; i < WRITERS && pid != 0; i++) {
        pid = fork();
        if (pid == -1) {
            perror("Writer's fork error.\n"); 
            exit( 1 );
        }
        if (pid == 0) {
            writer(sem_id, shm_buf, i);
        }
	}

    for (int i = 0; i < READERS && pid != 0; i++) {
        pid = fork();
        if (pid == -1) {
            perror("Reader's fork error.\n"); 
            exit( 1 );
        }
        if (pid == 0) {
            reader(sem_id, shm_buf, i);
        }
	}

    if (shmdt(shm_buf) == -1) {
        perror( "!!! Can't detach shared memory" );
        exit( 1 );
    }

    if (pid != 0) {
        int *status;
        for (int i = 0; i < WRITERS + READERS; ++i) {
	        wait(status);
        }
        if (shmctl(shm_id, IPC_RMID, NULL) == -1) {
            perror( "!!! Can't free memory!" );
            exit( 1 );
        }
    }

    return 0;
}
