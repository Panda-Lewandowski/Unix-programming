//testCIO.c
#include <stdio.h>
#include <fcntl.h>

/*
On my machine, a buffer size of 20 bytes
translated into a 12-character buffer.
Apparently 8 bytes were used up by the
stdio library for bookkeeping.
 */

int main()
{
  // have kernel open connection to file alphabet.txt
  int fd = open("alphabet.txt",O_RDONLY);

  // create two a C I/O buffered streams using the above connection
  // associates a stream with the existing file descriptor
  FILE *fs1 = fdopen(fd,"r"); 
  char buff1[20];
  setvbuf(fs1,buff1,_IOFBF,20); // set fully buffering

  FILE *fs2 = fdopen(fd,"r");
  char buff2[20];
  setvbuf(fs2,buff2,_IOFBF,20);
  
  // read a char and write it alternatingly from fs1 and fs2
  int flag1 = 1, flag2 = 2;
  while(flag1 == 1 || flag2 == 1)
  {
    char c;
    flag1 = fscanf(fs1,"%c",&c);
    
    if (flag1 == 1) { fprintf(stdout,"%c",c); }
    flag2 = fscanf(fs2,"%c",&c);
    if (flag2 == 1) { fprintf(stdout,"%c",c); }
  }

  return 0;
}
