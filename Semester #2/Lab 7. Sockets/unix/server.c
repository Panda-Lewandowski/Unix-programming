#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <signal.h>
#include <sys/socket.h> //socket, bind...

#include "info.h"

int sockfd;   //socket descriptor

void sigint_catcher(int signum)
{
    printf("Closing socket 'cause of Ctrl+C....\n");
    close(sockfd);
    unlink(SOCKET_NAME);

}

int main(void)
{
    char msg[MSG_LEN]; // message
    struct sockaddr client_addr;

    sockfd = socket(PF_LOCAL, SOCK_DGRAM, 0); // create socket descriptor 
    if (sockfd < 0)                       // for local communication without connection setup
    {
        perror("Error in socket(): ");
        return sockfd;
    }

    client_addr.sa_family = PF_LOCAL;
    strcpy(client_addr.sa_data, SOCKET_NAME);  //address

    if (bind(sockfd, &client_addr, sizeof(client_addr)) < 0) // bind a name to the socket
    {
        printf("Closing socket....\n");
        close(sockfd);
        unlink(SOCKET_NAME);
        perror("Error in bind(): ");
        return -1;
    }

    printf("\nServer is waiting for the message...\n");
    signal(SIGINT, sigint_catcher);

    for(;;)
    {

        int recievedSize = recv(sockfd, msg, sizeof(msg), 0); //receive a message from the socket
        if (recievedSize < 0) 
        {
            close(sockfd);
            unlink(SOCKET_NAME);
            perror("Error in recv(): ");
            return recievedSize;
        }

        msg[recievedSize] = 0;
        printf("Client send this message: %s\n", msg);
    }
    
    printf("Closing socket....\n");
    close(sockfd);
    unlink(SOCKET_NAME);
    return 0;
}