#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>

#include "info.h"

int main(void)
{
    srand(time(NULL));

    int sock = socket(PF_INET, SOCK_STREAM, 0);
    if (sock < 0)
    {
        perror("Error in sock(): ");
        return sock;
    }

    struct hostent* host = gethostbyname(SOCK_ADDR);    // /etc/hosts
    if (!host)
    {
        perror("Error in gethostbyname(): ");
        return -1;
    }

    struct sockaddr_in server_addr;
    server_addr.sin_family = PF_INET;
    server_addr.sin_port = htons(SOCK_PORT);
    server_addr.sin_addr = *((struct in_addr*) host->h_addr_list[0]);

    if (connect(sock, (struct sockaddr*) &server_addr, sizeof(server_addr)) < 0)
    {
        perror("Error in connect():");
        return -1;
    }

    char msg[MSG_LEN];
    for (int i = 0; i < 10; i++)
    {
        memset(msg, 0, MSG_LEN);
        sprintf(msg, "%d message is here!\n", i);
        printf("%s", msg);

        if (send(sock, msg, strlen(msg), 0) < 0)
        {
            perror("Error in send(): ");
            return -1;
        }
        
        printf("Sended %d message\n", i);

        int wait_time = 1 + rand() % 3;
        sleep(wait_time);
    }

    printf("Client app is over!\n");
    return 0;
}