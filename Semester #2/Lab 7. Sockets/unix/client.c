#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>

#include "info.h"

int main(void)
{
    int sockfd = socket(PF_LOCAL, SOCK_DGRAM, 0); //socket descriptor
    if (sockfd < 0)
    {
        printf("Error in socket();\n");
        return sockfd;
    }

    struct sockaddr server_addr;
    server_addr.sa_family = PF_LOCAL;
    strcpy(server_addr.sa_data, SOCKET_NAME);

    char msg[MSG_LEN]; // message
    strcpy(msg, "Client app is here!\n");
    sendto(sockfd, msg, strlen(msg), 0, &server_addr, sizeof(server_addr));

    close(sockfd);
    return 0;
}