#include <stdio.h>
int main() {

  FILE* fd[2];
  fd[0] = fopen("testFOpen_output.txt","w");
  fd[1] = fopen("testFOpen_output.txt","w");

  int curr = 0;

  for(char c = 'a'; c <= 'z'; c++, curr = ((curr != 0) ? 0 : 1))
  {
      fprintf(fd[curr], "%c", c);
  }
  fclose(fd[0]);
  fclose(fd[1]);
  return 0;
}