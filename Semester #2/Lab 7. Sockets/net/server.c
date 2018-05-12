#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <arpa/inet.h>
#include <netdb.h>

#include "info.h"

#define MAX_CLIENTS 10
int clients[MAX_CLIENTS] = { 0 };


void manageConnection(unsigned int fd)
{
    struct sockaddr_in client_addr;
    int addrSize = sizeof(client_addr);

    int incom = accept(fd, (struct sockaddr*) &client_addr, (socklen_t*) &addrSize);
    if (incom < 0)
    {
        perror("Error in accept(): ");
        exit(-1);
    }

    printf("\nNew connection: \nfd = %d \nip = %s:%d\n", incom, 
                            inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));

    for (int i = 0; i < MAX_CLIENTS; i++)
    {
        if (clients[i] == 0)
        {
            clients[i] = incom;
            printf("Managed as client #%d\n", i);
            break;
        }
    }

}

void manageClient(unsigned int fd, unsigned int client_id)
{
    char msg[MSG_LEN];
    memset(msg, 0, MSG_LEN);

    struct sockaddr_in client_addr;
    int addrSize = sizeof(client_addr);

    int recvSize = recv(fd, msg, MSG_LEN, 0);
    if (recvSize == 0)
    {
        getpeername(fd, (struct sockaddr*) &client_addr, (socklen_t*) &addrSize);
        printf("User %d disconnected %s:%d \n", client_id, inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
        close(fd);
        clients[client_id] = 0;
    }
    else
    {
        msg[recvSize] = '\0';
        printf("Message from %d client: %s\n", client_id, msg);
    }
}


int main(void)
{
    int listener = socket(PF_INET, SOCK_STREAM, 0);
    if (listener < 0)
    {
        perror("Error in sock(): ");
        return listener;
    }

    struct sockaddr_in client_addr;
    client_addr.sin_family = PF_INET;
    client_addr.sin_port = htons(SOCK_PORT);
    client_addr.sin_addr.s_addr = INADDR_ANY; //any address for binding

    if (bind(listener, (struct sockaddr*) &client_addr, sizeof(client_addr)) < 0)
    {
        perror("Error in bind():");
        return -1;
    }
    printf("Server is listening on the %d port...\n", SOCK_PORT);

    if (listen(listener, 3) < 0)
    {
        perror("Error in listen(): ");
        return -1;
    }
    printf("Waiting for the connections...\n");

    for (;;)
    {
        fd_set readfds; //set of file descriptors that will monitor select()
        int max_fd;  //The largest file descriptor in the set
        int active_clients_count; //number of sockets for which select() has fixed activity

       // Empty the set and add the listener
        FD_ZERO(&readfds);
        FD_SET(listener, &readfds);
        max_fd = listener;

        //add to the set of all already connected clients
        for (int i = 0; i < MAX_CLIENTS; i++)
        {
            int fd = clients[i];

            if (fd > 0)
            {
                FD_SET(fd, &readfds);
            }

            max_fd = (fd > max_fd) ? (fd) : (max_fd);
        }

        active_clients_count = select(max_fd + 1, &readfds, NULL, NULL, NULL);

        if (active_clients_count < 0 && (errno != EINTR))
        {
            perror("Error in select():");
            return active_clients_count;
        }

        //if the listener was active than the connection came
        if (FD_ISSET(listener, &readfds))
        {
            manageConnection(listener);
        }

        // check if there was activity on one of the clients
        for (int i = 0; i < MAX_CLIENTS; i++)
        {
            int fd = clients[i];
            if ((fd > 0) && FD_ISSET(fd, &readfds))
            {
                manageClient(fd, i);
            }
        }
    }

    return 0;
}